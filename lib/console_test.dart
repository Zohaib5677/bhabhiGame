import 'dart:io';
import 'package:bhabi/services/game_logic.dart';
import 'package:bhabi/models/card_model.dart';

void main() {
  print("Starting Bhabhi Game Logic Test...");

  // Simulate players
  final players = ['PlayerA', 'PlayerB', 'PlayerC'];

  // Simulate cards manually or via CardModel
  final testCards = [
    CardModel(code: 'AS', suit: 'SPADES', value: 'ACE', image: ''),
    CardModel(code: '2H', suit: 'HEARTS', value: '2', image: ''),
    CardModel(code: '3D', suit: 'DIAMONDS', value: '3', image: ''),
    CardModel(code: 'KH', suit: 'HEARTS', value: 'KING', image: ''),
    CardModel(code: 'QH', suit: 'HEARTS', value: 'QUEEN', image: ''),
    CardModel(code: 'JH', suit: 'HEARTS', value: 'JACK', image: ''),
  ];

  // Distribute cards manually for testing
  final playerCards = <String, List<CardModel>>{
    'PlayerA': [testCards[0], testCards[1]],
    'PlayerB': [testCards[2], testCards[3]],
    'PlayerC': [testCards[4], testCards[5]],
  };

  // Simulate played cards
  final playedCards = <CardModel>[];

  // Simulate discard pile
  final discardPile = <CardModel>[];

  // --- Run tests ---
  testIsValidPlay(playerCards);
  testDetermineRoundWinner(playerCards, playedCards);
  testProcessRoundEnd(playerCards, playedCards, discardPile);
  testSwapHands(playerCards, players);
  testCheckGameEnd(playerCards);
}

void testIsValidPlay(Map<String, List<CardModel>> playerCards) {
  print("\n🧪 Testing isValidPlay()");
  final currentHand = playerCards['PlayerA']!;
  final cardToPlay = currentHand[0]; // AS - valid
  final leadSuit = null;
  final isFirstRound = true;

  bool result = BhabhiGameLogic.isValidPlay(
    currentHand: currentHand,
    cardToPlay: cardToPlay,
    leadSuit: leadSuit,
    isFirstRound: isFirstRound,
  );
  print("Is valid play: $result");
}

void testDetermineRoundWinner(Map<String, List<CardModel>> playerCards, List<CardModel> playedCards) {
  print("\n🧪 Testing determineRoundWinner()");
  final played = <String, CardModel>{};
  played['PlayerA'] = playerCards['PlayerA']![0]; // AS
  played['PlayerB'] = playerCards['PlayerB']![0]; // 3D
  played['PlayerC'] = playerCards['PlayerC']![0]; // QH

  final winner = BhabhiGameLogic.determineRoundWinner(
    playedCards: played,
    leadPlayerId: 'PlayerA',
    leadSuit: 'SPADES',
    isFirstRound: false,
  );

  print("Round winner: $winner");
}

void testProcessRoundEnd(
    Map<String, List<CardModel>> playerCards,
    List<CardModel> playedCards,
    List<CardModel> discardPile) {
  print("\n🧪 Testing processRoundEnd()");
  final roundUpdates = BhabhiGameLogic.processRoundEnd(
    playerCards: playerCards,
    playedCards: playedCards,
    roundWinnerId: 'PlayerA',
    isFirstRound: false,
    discardPile: discardPile,
  );

  print("Round updates:");
  roundUpdates.forEach((key, value) => print("$key: $value"));
}

void testSwapHands(
    Map<String, List<CardModel>> playerCards, List<String> players) {
  print("\n🧪 Testing swapHands()");
  final swapResult = BhabhiGameLogic.processHandSwap(
    playerCards: playerCards,
    currentPlayerId: 'PlayerA',
    playerOrder: players,
  );

  print("After hand swap:");
  swapResult.forEach((key, value) => print("$key: $value"));
}

void testCheckGameEnd(Map<String, List<CardModel>> playerCards) {
  print("\n🧪 Testing checkGameEnd()");
  final isGameOver = BhabhiGameLogic.checkGameEnd(playerCards);
  print("Is game over? $isGameOver");
}