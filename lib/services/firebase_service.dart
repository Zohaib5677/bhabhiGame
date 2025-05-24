import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import 'game_logic.dart';
import 'dart:math';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

 String _generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  
  return String.fromCharCodes(
    List.generate(6, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}

  Future<String> createGameRoom(int maxPlayers, {String? gameType}) async {
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
      'gameType': gameType,
      'deckId': '',
      'currentTurn': 0,
      'playerCards': {},
      'playedCards': [],
      'discardPile': [],
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
      if ((doc['players'] as List).length < 2) throw Exception('Need 2+ players');

      final deckId = await GameLogic.createShuffledDeck();
      final allCards = await GameLogic.drawCards(deckId, 52);
      final players = List<String>.from(doc['players']);
      final distribution = GameLogic.distributeAllCards(allCards, players);

      final playerCardsJson = distribution.map(
        (uid, cards) => MapEntry(uid, cards.map((card) => card.toJson()).toList()),
      );

      transaction.update(docRef, {
        'status': 'started',
        'gameStatus': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'deckId': deckId,
        'playerCards': playerCardsJson,
        'currentTurn': 0,
        'remainingCards': 0,
        'discardPile': [],
      });
    });
  }

  // Future<void> playCard(String roomCode, CardModel card) async {
  //   final user = _auth.currentUser;
  //   if (user == null) throw Exception('Authentication required');

  //   await _firestore.runTransaction((transaction) async {
  //     final docRef = _firestore.collection('game_rooms').doc(roomCode);
  //     final doc = await transaction.get(docRef);

  //     _validatePlayerTurn(doc, user.uid);

  //     final playerCards = (doc['playerCards'] as Map<String, dynamic>).map<String, List<CardModel>>(
  //       (key, value) => MapEntry(
  //         key, 
  //         (value as List).map((e) => CardModel.fromJson(e)).toList()
  //       ),
  //     );
  //     final playedCards = List<Map<String, dynamic>>.from(doc['playedCards'] ?? []);
  //     final isFirstRound = doc['isFirstRound'] ?? true;
  //     final leadSuit = playedCards.isNotEmpty ? 
  //         CardModel.fromJson(playedCards.first).suit : null;

  //     final currentHand = playerCards[user.uid] ?? [];
  //     if (!BhabhiGameLogic.isValidPlay(
  //       currentHand: currentHand,
  //       cardToPlay: card,
  //       leadSuit: leadSuit,
  //       isFirstRound: isFirstRound,
  //     )) {
  //       throw Exception('Invalid card play');
  //     }

  //     playerCards[user.uid] = currentHand.where(
  //       (c) => !(c.code == card.code && c.suit == card.suit)
  //     ).toList();

  //     playedCards.add(card.toJson());

  //     final playerOrder = List<String>.from(doc['players']);
  //     final currentTurn = doc['currentTurn'] as int;
  //     final nextTurn = (currentTurn + 1) % playerOrder.length;
  //     final roundComplete = nextTurn == (doc['currentRoundStarter'] ?? 0);

  //     final updates = <String, dynamic>{
  //       'playerCards.${user.uid}': playerCards[user.uid]!.map((c) => c.toJson()).toList(),
  //       'playedCards': playedCards,
  //       'currentTurn': nextTurn,
  //     };

  //     if (roundComplete as bool) {
  //       final playedCardsModels = playedCards.map((e) => CardModel.fromJson(e)).toList();
  //       final discardPile = List<CardModel>.from(
  //         (doc['discardPile'] as List).map((e) => CardModel.fromJson(e)));
        
  //       final roundWinner = BhabhiGameLogic.determineRoundWinner(
  //         playedCards: Map.fromIterables(
  //           playerOrder, 
  //           playedCardsModels,
  //         ),
  //         leadPlayerId: playerOrder[doc['currentRoundStarter'] ?? 0],
  //         leadSuit: leadSuit,
  //         isFirstRound: isFirstRound,
  //       );

  //       if (roundWinner != null) {
  //         final roundUpdates = BhabhiGameLogic.processRoundEnd(
  //           playerCards: playerCards,
  //           playedCards: playedCardsModels,
  //           roundWinnerId: roundWinner,
  //           isFirstRound: isFirstRound,
  //           discardPile: discardPile,
  //         );
  //         updates.addAll(roundUpdates);
  //       }

  //       if (BhabhiGameLogic.checkGameEnd(playerCards)) {
  //         updates['gameStatus'] = 'ended';
  //         updates['endedAt'] = FieldValue.serverTimestamp();
  //       }
  //     }

  //     transaction.update(docRef, updates);
  //   });
  // }

  Future<void> drawCard(String roomCode, {int count = 1}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      _validatePlayerTurn(doc, user.uid);

      final deckId = doc['deckId'] as String;
      if (deckId.isEmpty) throw Exception('No deck available');

      final cards = await GameLogic.drawCards(deckId, count);
      final currentCards = List<Map<String, dynamic>>.from(
        (doc['playerCards'] as Map<String, dynamic>)[user.uid] ?? []
      );

      currentCards.addAll(cards.map((card) => card.toJson()));

      transaction.update(docRef, {
        'playerCards.${user.uid}': currentCards,
      });
    });
  }

  // Future<void> swapHands(String roomCode) async {
  //   final user = _auth.currentUser;
  //   if (user == null) throw Exception('Authentication required');

  //   await _firestore.runTransaction((transaction) async {
  //     final docRef = _firestore.collection('game_rooms').doc(roomCode);
  //     final doc = await transaction.get(docRef);

  //     if (doc['status'] != 'started') throw Exception('Game not active');
  //     if (doc['playedCards'] != null && (doc['playedCards'] as List).isNotEmpty) {
  //       throw Exception('Cannot swap hands during a round');
  //     }

  //     final playerCards = (doc['playerCards'] as Map<String, dynamic>).map<String, List<CardModel>>(
  //       (key, value) => MapEntry(
  //         key, 
  //         (value as List).map((e) => CardModel.fromJson(e)).toList()
  //       ),
  //     );
  //     final playerOrder = List<String>.from(doc['players']);

  //     final updates = BhabhiGameLogic.processHandSwap(
  //       playerCards: playerCards,
  //       currentPlayerId: user.uid,
  //       playerOrder: playerOrder,
  //     );

  //     transaction.update(docRef, updates);
  //   });
  // }

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

      if ((doc['players'] as List).length <= 2 && doc['status'] == 'started') {
        updates['status'] = 'ended';
        updates['gameStatus'] = 'ended';
        updates['endedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(docRef, updates);
    });
  }
}