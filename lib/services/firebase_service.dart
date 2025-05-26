import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import 'game_logic.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BhabhiGameLogic _gameLogic = BhabhiGameLogic();

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(6, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<String> createGameRoom(int maxPlayers) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');
    if (maxPlayers < 2 || maxPlayers > 6) throw Exception('Invalid player count');

    final roomCode = _generateRoomCode();
    final playerName = user.displayName ?? 'Player ${user.uid.substring(0, 5)}';

    await _firestore.collection('game_rooms').doc(roomCode).set({
      'gameId': roomCode,
      'hostId': user.uid,
      'hostName': playerName,
      'players': [user.uid],
      'playerNames': {user.uid: playerName},
      'maxPlayers': maxPlayers,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'gameStatus': 'waiting',
      'deckId': '',
      'currentTurn': 0,
      'currentRoundStarter': 0,
      'playerCards': {},
      'playedCards': [],
      'discardPile': [],
      'isFirstRound': true,
    });

    return roomCode;
  }

  Future<void> joinGameRoom(String roomCode, String playerName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      if (!doc.exists) throw Exception('Room not found');
      if (doc['status'] != 'waiting') throw Exception('Game already started');

      final players = List<String>.from(doc['players'] ?? []);
      final maxPlayers = doc['maxPlayers'] ?? 6;

      if (players.contains(user.uid)) throw Exception('Already joined');
      if (players.length >= maxPlayers) throw Exception('Room full');

      transaction.update(docRef, {
        'players': FieldValue.arrayUnion([user.uid]),
        'playerNames.${user.uid}': playerName,
      });
    });
  }

  Future<void> startGame(String roomCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      if (doc['hostId'] != user.uid) throw Exception('Only host can start');
      if (doc['status'] != 'waiting') throw Exception('Game already started');
      final players = List<String>.from(doc['players']);
      if (players.length < 2) throw Exception('Need at least 2 players');

      final deckId = await GameLogic.createShuffledDeck();
      final allCards = await GameLogic.drawCards(deckId, 52);
      final distribution = GameLogic.distributeAllCards(allCards, players);

      // Find player with Ace of Spades to start
      int startingPlayerIndex = 0;
      for (int i = 0; i < players.length; i++) {
        if (distribution[players[i]]!.any((card) => card.code == 'AS')) {
          startingPlayerIndex = i;
          break;
        }
      }

      transaction.update(docRef, {
        'status': 'started',
        'gameStatus': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'deckId': deckId,
        'playerCards': distribution.map(
          (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
        ),
        'currentTurn': startingPlayerIndex,
        'currentRoundStarter': startingPlayerIndex,
        'playedCards': [],
        'discardPile': [],
        'isFirstRound': true,
      });
      
    });
    
  }

  Future<void> playCard(String roomCode, CardModel card) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      _validatePlayerTurn(doc, user.uid);

      final gameData = doc.data() as Map<String, dynamic>;
      final players = List<String>.from(gameData['players']);
      final currentTurn = gameData['currentTurn'] as int;
      final isFirstRound = gameData['isFirstRound'] ?? true;
      final playedCards = List<Map<String, dynamic>>.from(gameData['playedCards'] ?? []);
      final leadSuit = playedCards.isNotEmpty ? CardModel.fromJson(playedCards.first).suit : null;

      // Convert player cards to CardModel objects
      final playerCards = (gameData['playerCards'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key, 
          (value as List).map((e) => CardModel.fromJson(e)).toList()
        ),
      );

      // Validate the play
      if (!BhabhiGameLogic.isValidPlay(
        currentHand: playerCards[user.uid] ?? [],
        cardToPlay: card,
        leadSuit: leadSuit,
        isFirstRound: isFirstRound,
      )) {
        throw Exception('Invalid card play');
      }

      // Update game state
      playerCards[user.uid] = playerCards[user.uid]!
          .where((c) => c.code != card.code)
          .toList();
      
      playedCards.add(card.toJson());

      // Prepare updates
      final updates = <String, dynamic>{
        'playerCards.${user.uid}': playerCards[user.uid]!.map((c) => c.toJson()).toList(),
        'playedCards': playedCards,
        'currentTurn': (currentTurn + 1) % players.length,
      };

      // Check if round is complete
      if ((updates['currentTurn'] as int) == (gameData['currentRoundStarter'] ?? 0)) {
        final playedCardsModels = playedCards.map((e) => CardModel.fromJson(e)).toList();
        final discardPile = (gameData['discardPile'] as List)
            .map((e) => CardModel.fromJson(e)).toList();

        final roundWinner = BhabhiGameLogic.determineRoundWinner(
          playedCards: Map.fromIterables(players, playedCardsModels),
          leadPlayerId: players[gameData['currentRoundStarter'] ?? 0],
          leadSuit: leadSuit,
          isFirstRound: isFirstRound,
        );

        if (roundWinner != null) {
          final roundUpdates = BhabhiGameLogic.processRoundEnd(
            playerCards: playerCards,
            playedCards: playedCardsModels,
            roundWinnerId: roundWinner,
            isFirstRound: isFirstRound,
            discardPile: discardPile,
          );
          updates.addAll(roundUpdates);
        }

        // Check for shoot-out scenario if only 2 players left
        if (BhabhiGameLogic.checkGameEnd(playerCards)) {
          final shootOutUpdate = BhabhiGameLogic.processShootOut(
            playerCards: playerCards,
            discardPile: discardPile,
            playedCards: Map.fromIterables(players, playedCardsModels),
            playerOrder: players,
          );
          if (shootOutUpdate != null) {
            updates.addAll(shootOutUpdate);
          } else {
            updates['gameStatus'] = 'ended';
            updates['endedAt'] = FieldValue.serverTimestamp();
          }
        }
      }

      transaction.update(docRef, updates);
    });
  }

  Future<void> swapHands(String roomCode) async {
  final user = _auth.currentUser;
  if (user == null) throw Exception('Authentication required');

  await _firestore.runTransaction((transaction) async {
    final docRef = _firestore.collection('game_rooms').doc(roomCode);
    final doc = await transaction.get(docRef);

    if (doc['status'] != 'started') throw Exception('Game not active');
    if ((doc['playedCards'] as List).isNotEmpty) {
      throw Exception('Cannot swap hands during a round');
    }

    final players = List<String>.from(doc['players']);
    final playerCards = (doc['playerCards'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key, 
        (value as List).map((e) => CardModel.fromJson(e)).toList()
      ),
    );

    final updates = BhabhiGameLogic.processHandSwap(
      playerCards: playerCards,
      currentPlayerId: user.uid,
      playerOrder: players,
    );

    // Additional checks for game end conditions
    if (playerCards[updates['roundWinner']]?.isEmpty ?? false) {
      updates['gameStatus'] = 'ended';
      updates['winner'] = updates['roundWinner'];
    }

    transaction.update(docRef, updates);
  });
}
  Future<void> processShootOutResponse({
    required String roomCode,
    required CardModel playedCard,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      final shootOutState = doc['shootOutState'] as Map<String, dynamic>?;
      if (shootOutState == null) throw Exception('Not in shoot-out');

      final respondingPlayer = shootOutState['respondingPlayer'] as String;
      if (respondingPlayer != user.uid) throw Exception('Not your turn to respond');

      final playerCards = (doc['playerCards'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key, 
          (value as List).map((e) => CardModel.fromJson(e)).toList()
        ),
      );
      final discardPile = (doc['discardPile'] as List)
          .map((e) => CardModel.fromJson(e)).toList();

      final updates = BhabhiGameLogic.processShootOutResponse(
        playerCards: playerCards,
        discardPile: discardPile,
        respondingPlayerId: user.uid,
        playedCard: playedCard,
        requiredSuit: shootOutState['requiredSuit'] as String,
        drawingPlayerId: shootOutState['drawingPlayer'] as String,
      );

      transaction.update(docRef, updates);
    });
  }

  void _validatePlayerTurn(DocumentSnapshot doc, String uid) {
    if (doc['status'] != 'started') throw Exception('Game not active');
    
    final players = doc['players'] as List;
    final currentTurn = doc['currentTurn'] as int;
    if (players[currentTurn % players.length] != uid) {
      throw Exception('Not your turn');
    }
  }

  Stream<DocumentSnapshot> getRoomStream(String roomCode) {
    return _firestore.collection('game_rooms').doc(roomCode).snapshots();
  }

  Future<void> leaveGameRoom(String roomCode) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      if (!doc.exists) return;

      final updates = <String, dynamic>{
        'players': FieldValue.arrayRemove([user.uid]),
        'playerNames.${user.uid}': FieldValue.delete(),
        'playerCards.${user.uid}': FieldValue.delete(),
      };

      if (doc['hostId'] == user.uid) {
        final remainingPlayers = (doc['players'] as List).where((p) => p != user.uid).toList();
        if (remainingPlayers.isNotEmpty) {
          updates['hostId'] = remainingPlayers.first;
          updates['hostName'] = doc['playerNames'][remainingPlayers.first];
        }
      }

      if ((doc['players'] as List).length <= 1) {
        updates['status'] = 'ended';
        updates['gameStatus'] = 'ended';
        updates['endedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(docRef, updates);
    });
  }
}