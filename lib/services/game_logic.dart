import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
// class BhabhiGameLogic {
//   static final Random _random = Random();

//   static bool isValidPlay({
//     required List<CardModel> currentHand,
//     required CardModel cardToPlay,
//     required String? leadSuit,
//     required bool isFirstRound,
//   }) {
//     if (!currentHand.any((c) => c.code == cardToPlay.code && c.suit == cardToPlay.suit)) {
//       return false;
//     }

//     if (isFirstRound) {
//       return true;
//     }

//     if (leadSuit != null && currentHand.any((c) => c.suit == leadSuit)) {
//       return cardToPlay.suit == leadSuit;
//     }

//     return true;
//   }

//   static String? determineRoundWinner({
//     required Map<String, CardModel> playedCards,
//     required String leadPlayerId,
//     required String? leadSuit,
//     required bool isFirstRound,
//   }) {
//     if (playedCards.isEmpty) return null;

//     if (isFirstRound) {
//       return leadPlayerId;
//     }

//     final allFollowedSuit = leadSuit != null && 
//         playedCards.values.every((card) => card.suit == leadSuit);

//     if (allFollowedSuit) {
//       final highestCard = playedCards.values.reduce((highest, card) {
//         return card.suit == leadSuit && card.numericValue > highest.numericValue 
//             ? card : highest;
//       });

//       return playedCards.entries
//           .firstWhere((entry) => entry.value == highestCard)
//           .key;
//     } else {
//       if (leadSuit == null) return null;

//       final leadSuitCards = playedCards.values.where((card) => card.suit == leadSuit);
//       if (leadSuitCards.isEmpty) return null;

//       final highestLeadCard = leadSuitCards.reduce((highest, card) {
//         return card.numericValue > highest.numericValue ? card : highest;
//       });

//       return playedCards.entries
//           .firstWhere((entry) => entry.value == highestLeadCard)
//           .key;
//     }
//   }

//   static Map<String, dynamic> processRoundEnd({
//     required Map<String, List<CardModel>> playerCards,
//     required List<CardModel> playedCards,
//     required String roundWinnerId,
//     required bool isFirstRound,
//     required List<CardModel> discardPile,
//   }) {
//     final updates = <String, dynamic>{};
//     final cardsToDiscard = <CardModel>[];

//     if (isFirstRound) {
//       cardsToDiscard.addAll(playedCards);
//     } else {
//       final leadSuit = playedCards.isNotEmpty ? playedCards.first.suit : null;
//       final allFollowedSuit = leadSuit != null && 
//           playedCards.every((card) => card.suit == leadSuit);

//       if (allFollowedSuit) {
//         cardsToDiscard.addAll(playedCards);
//       } else {
//         final winnerCards = playerCards[roundWinnerId] ?? [];
//         playerCards[roundWinnerId] = [...winnerCards, ...playedCards];
//         updates['playerCards'] = playerCards.map(
//           (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
//         );
//       }
//     }

//     if (cardsToDiscard.isNotEmpty) {
//       discardPile.addAll(cardsToDiscard);
//       updates['discardPile'] = discardPile.map((c) => c.toJson()).toList();
//     }

//     updates.addAll({
//       'playedCards': [],
//       'currentTurn': playerCards.keys.toList().indexOf(roundWinnerId),
//       'isFirstRound': false,
//     });

//     return updates;
//   }

//   static Map<String, dynamic> processHandSwap({
//     required Map<String, List<CardModel>> playerCards,
//     required String currentPlayerId,
//     required List<String> playerOrder,
//   }) {
//     final currentPlayerIndex = playerOrder.indexOf(currentPlayerId);
//     final leftPlayerIndex = (currentPlayerIndex + 1) % playerOrder.length;
//     final leftPlayerId = playerOrder[leftPlayerIndex];

//     final tempHand = playerCards[currentPlayerId];
//     playerCards[currentPlayerId] = playerCards[leftPlayerId] ?? [];
//     playerCards[leftPlayerId] = tempHand ?? [];

//     return {
//       'playerCards': playerCards.map(
//         (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
//       ),
//       'lastAction': 'hand_swap',
//       'lastActionPlayer': currentPlayerId,
//     };
//   }

//   static bool checkGameEnd(Map<String, List<CardModel>> playerCards) {
//     final playersWithCards = playerCards.values.where((hand) => hand.isNotEmpty).length;
//     return playersWithCards <= 1;
//   }

//   static Map<String, dynamic>? processShootOut({
//     required Map<String, List<CardModel>> playerCards,
//     required List<CardModel> discardPile,
//     required Map<String, CardModel> playedCards,
//     required List<String> playerOrder,
//   }) {
//     final remainingPlayers = playerCards.entries
//         .where((entry) => entry.value.isNotEmpty)
//         .toList();
    
//     if (remainingPlayers.length != 2) return null;

//     final player1 = remainingPlayers[0];
//     final player2 = remainingPlayers[1];

//     if ((player1.value.isEmpty && player2.value.isNotEmpty) ||
//         (player2.value.isEmpty && player1.value.isNotEmpty)) {
      
//       final lastCardPlayer = player1.value.isEmpty ? player1 : player2;
//       final otherPlayer = player1.value.isEmpty ? player2 : player1;

//       final leadSuit = playedCards.values.first.suit;
//       final otherPlayerCard = playedCards[otherPlayer.key];
      
//       if (otherPlayerCard != null && otherPlayerCard.suit == leadSuit) {
//         final updates = <String, dynamic>{};
//         final availableCards = discardPile.where((card) => 
//             !playedCards.values.any((c) => c.code == card.code && c.suit == card.suit)).toList();

//         if (availableCards.isNotEmpty) {
//           final drawnCard = availableCards[_random.nextInt(availableCards.length)];
//           playerCards[lastCardPlayer.key] = [drawnCard];
//           updates['playerCards'] = playerCards.map(
//             (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
//           );

//           discardPile.removeWhere((card) => 
//               card.code == drawnCard.code && card.suit == drawnCard.suit);
//           updates['discardPile'] = discardPile.map((c) => c.toJson()).toList();

//           updates['shootOutState'] = {
//             'drawingPlayer': lastCardPlayer.key,
//             'respondingPlayer': otherPlayer.key,
//             'requiredSuit': leadSuit,
//           };

//           return updates;
//         }
//       }
//     }

//     return null;
//   }

//   static Map<String, dynamic> processShootOutResponse({
//     required Map<String, List<CardModel>> playerCards,
//     required List<CardModel> discardPile,
//     required String respondingPlayerId,
//     required CardModel playedCard,
//     required String requiredSuit,
//     required String drawingPlayerId,
//   }) {
//     final updates = <String, dynamic>{};
//     final respondingPlayerHand = playerCards[respondingPlayerId] ?? [];

//     if (playedCard.suit == requiredSuit) {
//       if (playedCard.numericValue < 8) {
//         final availableCards = discardPile.where((card) => 
//             card.suit != playedCard.suit || card.code != playedCard.code).toList();

//         if (availableCards.isNotEmpty) {
//           final drawnCard = availableCards[_random.nextInt(availableCards.length)];
//           playerCards[drawingPlayerId] = [drawnCard];
//           discardPile.removeWhere((card) => 
//               card.code == drawnCard.code && card.suit == drawnCard.suit);

//           updates.addAll({
//             'playerCards': playerCards.map(
//               (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
//             ),
//             'discardPile': discardPile.map((c) => c.toJson()).toList(),
//             'shootOutState': {
//               'drawingPlayer': drawingPlayerId,
//               'respondingPlayer': respondingPlayerId,
//               'requiredSuit': requiredSuit,
//             },
//           });
//         }
//       } else {
//         updates['gameStatus'] = 'ended';
//         updates['winner'] = drawingPlayerId;
//         updates['bhabhi'] = respondingPlayerId;
//       }
//     } else {
//       updates['gameStatus'] = 'ended';
//       updates['winner'] = respondingPlayerId;
//       updates['bhabhi'] = drawingPlayerId;
//     }

//     updates['shootOutState'] = FieldValue.delete();
//     return updates;
//   }
// }

class GameLogic {
  static Future<String> createShuffledDeck() async {
    try {
      final response = await http.get(
        Uri.parse('https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1'),
      );
      print(response.body); // Add this line to print the response from the Deck of Cards AP
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('this is data: $data');
        print("this is deck id: ${data['deck_id']}");
        return data['deck_id'] as String;
      } else {
        throw Exception('Failed to create shuffled deck');
      }
    } catch (e) {
      throw Exception('Error creating deck: $e');
    }
  }

  static Future<List<CardModel>> drawCards(String deckId, int count) async {
    try {
      final response = await http.get(
        Uri.parse('https://deckofcardsapi.com/api/deck/$deckId/draw/?count=$count'),
      );
      print('this is draw cards: $response.body');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('this is draw cards: $data');
        final cards = data['cards'] as List;
        return cards.map((card) => CardModel.fromJson(card)).toList();
      } else {
        throw Exception('Failed to draw cards');
      }
    } catch (e) {
      throw Exception('Error drawing cards: $e');
    }
  }

  static Map<String, List<CardModel>> distributeAllCards(
    List<CardModel> allCards,
    List<String> players,
  ) {
    final distribution = <String, List<CardModel>>{};
    final cardsPerPlayer = allCards.length ~/ players.length;
    
    // Shuffle the cards before distribution (though they should already be shuffled)
    final shuffledCards = List<CardModel>.from(allCards)..shuffle();
    
    for (var i = 0; i < players.length; i++) {
      final start = i * cardsPerPlayer;
      final end = (i + 1) * cardsPerPlayer;
      distribution[players[i]] = shuffledCards.sublist(start, end);
    }
    print('this is distribution: $distribution');
    return distribution;
  }
}