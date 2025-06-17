import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import 'game_logic.dart';
import 'dart:math';
import 'dart:async';

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
        'isFirstRound': true,
        'playedCards': [],
        'currentRoundStarter': 0,
        'winners': [],
      });
    });
  }

  Future<void> playCard(String roomCode, CardModel card) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    bool shouldDelayRoundEnd = false;
    Map<String, dynamic>? delayedRoundParams;

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      // Defensive: fallback to empty/defaults if any field is missing
      final docPlayerCards = doc['playerCards'] as Map<String, dynamic>? ?? {};
      final docPlayedCards = doc['playedCards'] as List? ?? [];
      final docIsFirstRound = doc['isFirstRound'] ?? true;
      final docCurrentRoundStarter = doc['currentRoundStarter'] ?? 0;
      final docPlayerOrder = doc['players'] as List? ?? [];

      final isFirstRound = docIsFirstRound;
      final playedCards = List<dynamic>.from(docPlayedCards);
      final isAceOfSpades = card.code == 'AS' || (card.value == 'ACE' && card.suit == 'SPADES');
      final isFirstCardOfGame = isFirstRound && playedCards.isEmpty;
      
      // Allow Ace of Spades to be played first, otherwise validate turn
      if (!isFirstCardOfGame || !isAceOfSpades) {
        _validatePlayerTurn(doc, user.uid);
      } else {
        // For first Ace of Spades play, just validate game is active
        if (doc['status'] != 'started') throw Exception('Game not active');
      }

      final playerCards = docPlayerCards.map<String, List<CardModel>>(
        (key, value) => MapEntry(
          key, 
          (value as List).map((e) => CardModel.fromJson(e)).toList()
        ),
      );
      final leadSuit = playedCards.isNotEmpty ? 
          CardModel.fromJson(playedCards.first).suit : null;

      final currentHand = playerCards[user.uid] ?? [];
      if (!BhabhiGameLogic.isValidPlay(
        currentHand: currentHand,
        cardToPlay: card,
        leadSuit: leadSuit,
        isFirstRound: isFirstRound,
      )) {
        throw Exception('Invalid card play');
      }

      playerCards[user.uid] = currentHand.where(
        (c) => !(c.code == card.code && c.suit == card.suit)
      ).toList();

      playedCards.add(card.toJson());

      final playerOrder = List<String>.from(docPlayerOrder);
      final currentTurn = (doc['currentTurn'] ?? 0) as int;
      
      // For Ace of Spades first play, set the current turn to the player who played it
      final nextTurn = isFirstCardOfGame && isAceOfSpades 
          ? (playerOrder.indexOf(user.uid) + 1) % playerOrder.length
          : (currentTurn + 1) % playerOrder.length;
      
      // Get the round starter - either existing or the current player if first card
      final currentRoundStarter = isFirstCardOfGame 
          ? playerOrder.indexOf(user.uid)
          : (docCurrentRoundStarter as int? ?? 0);
      
      // Check if round should end early due to someone not following suit
      // This happens when a player plays out of suit but they DO have cards of the lead suit
      // (which means they chose not to follow suit)
      final shouldEndRoundEarly = !isFirstRound && 
          leadSuit != null && 
          card.suit != leadSuit && 
          currentHand.any((c) => c.suit == leadSuit);
      
      // Actually, let me correct this: if someone can't follow suit (has no cards of that suit),
      // they play any card and play stops immediately
      final cantFollowSuit = !isFirstRound && 
          leadSuit != null && 
          card.suit != leadSuit && 
          !currentHand.any((c) => c.suit == leadSuit);
      
      // Check if round is complete 
      // For first round: all players must play
      // For regular rounds: all players play OR someone can't follow suit (stops early)
      final roundComplete = cantFollowSuit || 
          (playedCards.length >= playerOrder.length && 
           nextTurn == currentRoundStarter);

      final updates = <String, dynamic>{
        'playerCards.${user.uid}': playerCards[user.uid]!.map((c) => c.toJson()).toList(),
        'playedCards': playedCards,
        'currentTurn': cantFollowSuit ? nextTurn : nextTurn, // Keep current logic for now
      };

      // Set the round starter if this is the first card
      if (isFirstCardOfGame) {
        updates['currentRoundStarter'] = currentRoundStarter;
      }

      if (roundComplete) {
        // Instead of processing the round immediately, set roundEnding: true and delay the round end
        updates['roundEnding'] = true;
        shouldDelayRoundEnd = true;
        delayedRoundParams = {
          'roomCode': roomCode,
          'playerCards': playerCards,
          'playedCards': playedCards,
          'isFirstRound': isFirstRound,
          'currentRoundStarter': currentRoundStarter,
          'playerOrder': playerOrder,
        };
      }

      transaction.update(docRef, updates);
    });

    // If roundComplete, process the round after a delay
    if (shouldDelayRoundEnd && delayedRoundParams != null) {
      await Future.delayed(const Duration(seconds: 1));
      await _processRoundEndAfterDelay(
        delayedRoundParams!['roomCode'],
        delayedRoundParams!['playerCards'],
        delayedRoundParams!['playedCards'],
        delayedRoundParams!['isFirstRound'],
        delayedRoundParams!['currentRoundStarter'],
        delayedRoundParams!['playerOrder'],
      );
    }
  }

  Future<void> _processRoundEndAfterDelay(
    String roomCode,
    Map<String, List<CardModel>> playerCards,
    List playedCards,
    bool isFirstRound,
    int currentRoundStarter,
    List<String> playerOrder,
  ) async {
    // Fetch the latest document to get discard pile and other info
    final docRef = _firestore.collection('game_rooms').doc(roomCode);
    final docSnap = await docRef.get();
    if (!docSnap.exists) return;
    final doc = docSnap.data()!;

    // Only get discardPile from Firestore, use parameters for the rest
    final docDiscardPile = doc?['discardPile'] as List? ?? [];

    final playedCardsModels = playedCards.map((e) => CardModel.fromJson(e)).toList();
    final discardPile = List<CardModel>.from(
      docDiscardPile.map((e) => CardModel.fromJson(e)));

    // Create proper mapping of players to their played cards
    final playedCardsMap = <String, CardModel>{};
    for (int i = 0; i < playedCardsModels.length; i++) {
      final playerIndex = (currentRoundStarter + i) % playerOrder.length;
      playedCardsMap[playerOrder[playerIndex]] = playedCardsModels[i];
    }

    final roundWinner = BhabhiGameLogic.determineRoundWinner(
      playedCards: playedCardsMap,
      leadPlayerId: playerOrder.isNotEmpty ? playerOrder[currentRoundStarter] : '',
      leadSuit: playedCardsModels.isNotEmpty ? playedCardsModels.first.suit : null,
      isFirstRound: isFirstRound,
    );

    final updates = <String, dynamic>{
      'roundEnding': FieldValue.delete(),
    };

    if (roundWinner != null) {
      final roundUpdates = BhabhiGameLogic.processRoundEnd(
        playerCards: playerCards,
        playedCards: playedCardsModels,
        roundWinnerId: roundWinner,
        isFirstRound: isFirstRound,
        discardPile: discardPile,
        playerOrder: playerOrder,
      );
      updates.addAll(roundUpdates);
    }

    if (BhabhiGameLogic.checkGameEnd(playerCards)) {
      updates['gameStatus'] = 'ended';
      updates['endedAt'] = FieldValue.serverTimestamp();
      // Determine winner and bhabhi
      final playersWithCards = playerCards.entries
          .where((entry) => entry.value.isNotEmpty)
          .toList();
      if (playersWithCards.isEmpty) {
        updates['winner'] = roundWinner;
      } else if (playersWithCards.length == 1) {
        updates['bhabhi'] = playersWithCards.first.key;
        final finishedPlayers = playerCards.entries
            .where((entry) => entry.value.isEmpty)
            .map((entry) => entry.key)
            .toList();
        if (finishedPlayers.isNotEmpty) {
          updates['winner'] = finishedPlayers.last;
        }
      }
    }

    await docRef.update(updates);
  }

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

  Future<void> swapHands(String roomCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      if (doc['status'] != 'started') throw Exception('Game not active');
      if (doc['playedCards'] != null && (doc['playedCards'] as List).isNotEmpty) {
        throw Exception('Cannot swap hands during a round');
      }

      final playerCards = (doc['playerCards'] as Map<String, dynamic>).map<String, List<CardModel>>(
        (key, value) => MapEntry(
          key, 
          (value as List).map((e) => CardModel.fromJson(e)).toList()
        ),
      );
      final playerOrder = List<String>.from(doc['players']);

      final updates = BhabhiGameLogic.processHandSwap(
        playerCards: playerCards,
        currentPlayerId: user.uid,
        playerOrder: playerOrder,
      );

      transaction.update(docRef, updates);
    });
  }

  Future<void> takeFullHand(String roomCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('game_rooms').doc(roomCode);
      final doc = await transaction.get(docRef);

      if (doc['status'] != 'started') throw Exception('Game not active');
      
      // Check if we're in the middle of a round
      if (doc['playedCards'] != null && (doc['playedCards'] as List).isNotEmpty) {
        throw Exception('Cannot take full hand during a round');
      }

      final playerCards = (doc['playerCards'] as Map<String, dynamic>).map<String, List<CardModel>>(
        (key, value) => MapEntry(
          key, 
          (value as List).map((e) => CardModel.fromJson(e)).toList()
        ),
      );
      final playerOrder = List<String>.from(doc['players']);
      final winners = List<String>.from(doc['winners'] ?? []);

      // Check if the left player is already a winner (has no cards due to previous take full hand)
      final currentPlayerIndex = playerOrder.indexOf(user.uid);
      final leftPlayerIndex = (currentPlayerIndex + 1) % playerOrder.length;
      final leftPlayerId = playerOrder[leftPlayerIndex];
      
      if (winners.contains(leftPlayerId)) {
        throw Exception('Cannot take cards from a player who is already a winner');
      }

      // Check if left player has any cards to take
      final leftPlayerCards = playerCards[leftPlayerId] ?? [];
      if (leftPlayerCards.isEmpty) {
        throw Exception('Left player has no cards to take');
      }

      final updates = BhabhiGameLogic.processTakeFullHand(
        playerCards: playerCards,
        currentPlayerId: user.uid,
        playerOrder: playerOrder,
        winners: winners,
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

      if ((doc['players'] as List).length <= 2 && doc['status'] == 'started') {
        updates['status'] = 'ended';
        updates['gameStatus'] = 'ended';
        updates['endedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(docRef, updates);
    });
  }
}