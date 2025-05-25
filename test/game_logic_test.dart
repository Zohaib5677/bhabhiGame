import 'package:bhabi/models/card_model.dart';
import 'package:bhabi/services/game_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bhabhi Game Logic Tests', () {
    late Map<String, List<CardModel>> playerCards;

    setUp(() {
      // Setup initial cards and players before each test
      final cardAS = CardModel(code: 'AS', suit: 'SPADES', value: 'ACE', image: '');
      final card2H = CardModel(code: '2H', suit: 'HEARTS', value: '2', image: '');
      final card3D = CardModel(code: '3D', suit: 'DIAMONDS', value: '3', image: '');
      final cardKH = CardModel(code: 'KH', suit: 'HEARTS', value: 'KING', image: '');
      final cardQH = CardModel(code: 'QH', suit: 'HEARTS', value: 'QUEEN', image: '');
      final cardJH = CardModel(code: 'JH', suit: 'HEARTS', value: 'JACK', image: '');

      playerCards = {
        'PlayerA': [cardAS, card2H],
        'PlayerB': [card3D, cardKH],
        'PlayerC': [cardQH, cardJH],
      };
    });

    test('isValidPlay should allow any card in first round', () {
      final currentHand = playerCards['PlayerA']!;
      final cardToPlay = currentHand[0]; // AS - valid
      final leadSuit = null;
      final isFirstRound = true;

      final result = BhabhiGameLogic.isValidPlay(
        currentHand: currentHand,
        cardToPlay: cardToPlay,
        leadSuit: leadSuit,
        isFirstRound: isFirstRound,
      );

      expect(result, true);
    });

    test('isValidPlay should enforce suit following after first round', () {
      final currentHand = playerCards['PlayerB']!;
      final cardToPlay = currentHand[1]; // KH (HEARTS)
      final leadSuit = 'SPADES';
      final isFirstRound = false;

      final result = BhabhiGameLogic.isValidPlay(
        currentHand: currentHand,
        cardToPlay: cardToPlay,
        leadSuit: leadSuit,
        isFirstRound: isFirstRound,
      );

      expect(result, false);
    });

    test('determineRoundWinner should return correct winner when all follow suit', () {
      final played = <String, CardModel>{};
      played['PlayerA'] = playerCards['PlayerA']![0]; // AS
      played['PlayerB'] = playerCards['PlayerB']![1]; // KH
      played['PlayerC'] = playerCards['PlayerC']![1]; // JH

      final winner = BhabhiGameLogic.determineRoundWinner(
        playedCards: played,
        leadPlayerId: 'PlayerA',
        leadSuit: 'SPADES',
        isFirstRound: false,
      );

      expect(winner, 'PlayerA');
    });

    test('processRoundEnd should discard cards if all followed suit', () {
      final playedCards = [
        playerCards['PlayerA']![0], // AS
        playerCards['PlayerB']![0], // 3D
        playerCards['PlayerC']![0], // QH
      ];
      final discardPile = <CardModel>[];

      final updates = BhabhiGameLogic.processRoundEnd(
        playerCards: playerCards,
        playedCards: playedCards,
        roundWinnerId: 'PlayerA',
        isFirstRound: false,
        discardPile: discardPile,
      );

      expect(updates['discardPile'], isNotEmpty);
      expect(updates['playedCards'], isEmpty);
    });

    test('checkGameEnd should return false when more than one player has cards', () {
      final isGameOver = BhabhiGameLogic.checkGameEnd(playerCards);
      expect(isGameOver, false);
    });

    test('processHandSwap should swap hands between current player and left', () {
      final playerOrder = ['PlayerA', 'PlayerB', 'PlayerC'];
      final swapResult = BhabhiGameLogic.processHandSwap(
        playerCards: playerCards,
        currentPlayerId: 'PlayerA',
        playerOrder: playerOrder,
      );

      final updatedPlayerCards = (swapResult['playerCards'] as Map).map(
        (key, value) => MapEntry(key, (value as List).map((e) => CardModel.fromJson(e)).toList()),
      );

      expect(updatedPlayerCards['PlayerA'], equals(playerCards['PlayerB']));
      expect(updatedPlayerCards['PlayerB'], equals(playerCards['PlayerA']));
    });
  });
}