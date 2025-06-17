import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/card_model.dart';
import 'dart:math' as math;

class GameScreen extends StatefulWidget {
  final String roomCode;

  const GameScreen({super.key, required this.roomCode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _cardAnimationController;
  CardModel? _selectedCard;
  bool _isPlayingCard = false;
  bool _isTakingFullHand = false;

  String get _playerId => _auth.currentUser?.uid ?? '';
  String get _playerName => _auth.currentUser?.displayName ?? 'Player';

  bool _showRules = false;
  void _toggleRules() {
  setState(() {
    _showRules = !_showRules;
  });
}

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    // Reset orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B4513), // Dark brown
              Color(0xFFD2691E), // Orange brown
              Color(0xFF8B4513), // Dark brown
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _firebaseService.getRoomStream(widget.roomCode),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final gameData = snapshot.data!.data() as Map<String, dynamic>?;
              if (gameData == null) {
                return const Center(
                  child: Text(
                    'Game data not found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return _buildGameTable(gameData);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameTable(Map<String, dynamic> gameData) {
    final players = List<String>.from(gameData['players'] ?? []);
    final playerNames = Map<String, String>.from(gameData['playerNames'] ?? {});
    final playerCards = Map<String, dynamic>.from(gameData['playerCards'] ?? {});
    final playedCards = List<dynamic>.from(gameData['playedCards'] ?? []);
    final currentTurn = gameData['currentTurn'] ?? 0;
    final gameStatus = gameData['gameStatus'] ?? 'waiting';
    final winners = List<String>.from(gameData['winners'] ?? []);
    
    // Safe handling of isFirstRound field - default to true if not exists
    final isFirstRound = gameData.containsKey('isFirstRound') 
        ? (gameData['isFirstRound'] ?? true) 
        : true;

    // Get current player's cards
    final myCards = List<dynamic>.from(playerCards[_playerId] ?? [])
        .map((card) => CardModel.fromJson(card))
        .toList();

    final isMyTurn = players.isNotEmpty && 
        players[currentTurn % players.length] == _playerId;

    // Check if current player has Ace of Spades and it's the first round
    final hasAceOfSpades = myCards.any((card) => 
        card.code == 'AS' || (card.value == 'ACE' && card.suit == 'SPADES'));
    
    // Determine if this player should start (has Ace of Spades in first round)
    final shouldStartWithAceOfSpades = isFirstRound && hasAceOfSpades && playedCards.isEmpty;

    // Check if current player is a winner (can't play anymore)
    final isCurrentPlayerWinner = winners.contains(_playerId);

    // Get left player info for "take full hand" functionality
    final currentPlayerIndex = players.indexOf(_playerId);
    final leftPlayerIndex = currentPlayerIndex >= 0 ? (currentPlayerIndex + 1) % players.length : -1;
    final leftPlayerId = leftPlayerIndex >= 0 ? players[leftPlayerIndex] : '';
    final leftPlayerCards = leftPlayerId.isNotEmpty ? (playerCards[leftPlayerId] as List?)?.length ?? 0 : 0;
    final isLeftPlayerWinner = leftPlayerId.isNotEmpty ? winners.contains(leftPlayerId) : false;

    // Check if "take full hand" is available
    final canTakeFullHand = !isCurrentPlayerWinner && 
                           leftPlayerId.isNotEmpty && 
                           !isLeftPlayerWinner && 
                           leftPlayerCards > 0 && 
                           playedCards.isEmpty; // Only when not in the middle of a round

    if (gameStatus == 'ended') {
      return _buildGameEndScreen(gameData);
    }

    return Stack(
      children: [
        // Background pattern
        _buildBackgroundPattern(),
      
// Rules overlay - add this right after background

// ... rest of your Stack children
        // Main game area - optimized for landscape
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Stack(
              children: [
                // Table - centered and larger for landscape
                _buildTable(),
                
                // Players around table
                ..._buildPlayersAroundTable(players, playerNames, playerCards, currentTurn, winners),
                
                // Center played cards
                _buildCenterCards(playedCards, isFirstRound, shouldStartWithAceOfSpades),
                
                // Current player's hand at bottom
                _buildPlayerHand(myCards, isMyTurn, shouldStartWithAceOfSpades, isCurrentPlayerWinner),
              ],
            ),
          ),
        ),
        
        // Top bar with room info
       // Top bar with back button and rules button
Positioned(
  top: 12,
  left: 12,
  right: 12,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      ClipOval(
        child: Material(
          color: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ),
      ),
      ClipOval(
        child: Material(
          color: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 26),
            onPressed: _toggleRules,
            tooltip: 'Game Rules',
          ),
        ),
      ),
    ],
  ),
),
        
// Rules overlay - add this as the LAST child in your Stack
if (_showRules)
  Positioned.fill(
    child: GestureDetector(
      onTap: _toggleRules,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7, // Fixed height
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Game Rules',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: _toggleRules,
                      ),
                    ],
                  ),
                ),
                
                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem('🔄 Play proceeds clockwise. Start with Ace of Spades.'),
                        _buildRuleItem('♠️ Follow suit if possible. Highest card wins the round.'),
                        _buildRuleItem('🌟 First round: All cards discarded regardless of suit.'),
                        _buildRuleItem('🔄 Hand Swap: Take left player\'s hand anytime (not mid-round).'),
                        _buildRuleItem('🏆 No cards to lead? You win! Next player leads.'),
                        _buildRuleItem('🔫 Shoot-Out: Last 2 players? Special endgame rules apply.'),
                        const SizedBox(height: 16),
                        _buildRuleItem('📌 Remember: The player who gets rid of all cards first wins!'),
                        _buildRuleItem('📌 Last player with cards becomes the "Bhabhi" (looser).'),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                
              ],
            ),
          ),
        ),
      ),
    ),
  ),

        // Action buttons
        _buildActionButtons(shouldStartWithAceOfSpades, canTakeFullHand, leftPlayerId, playerNames),
      ],
    );
  }

  Widget _buildGameEndScreen(Map<String, dynamic> gameData) {
    final winner = gameData['winner'];
    final bhabhi = gameData['bhabhi'];
    final winners = List<String>.from(gameData['winners'] ?? []);
    final playerNames = Map<String, String>.from(gameData['playerNames'] ?? {});
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE94560), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 Game Over! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (winner != null) ...[
              Text(
                '🏆 Final Winner: ${playerNames[winner] ?? "Unknown"}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (winners.isNotEmpty) ...[
              const Text(
                '👑 All Winners:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...winners.map((winnerId) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '✨ ${playerNames[winnerId] ?? "Unknown"}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
              const SizedBox(height: 12),
            ],
            if (bhabhi != null) ...[
              Text(
                '😅 Looser: ${playerNames[bhabhi] ?? "Unknown"}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text(
                'Back to Lobby',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildRuleItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildBackgroundPattern() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2F1B14),
      ),
      child: CustomPaint(
        painter: WoodGrainPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildTable() {
    return Center(
      child: Container(
        width: 450, // Larger for landscape
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(140),
          gradient: const RadialGradient(
            colors: [
              Color(0xFF0F5132), // Dark green center
              Color(0xFF198754), // Medium green
              Color(0xFF0F5132), // Dark green edge
            ],
          ),
          border: Border.all(
            color: const Color(0xFFD4AF37), // Gold border
            width: 10,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(125),
            border: Border.all(
              color: const Color(0xFF8B4513),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlayersAroundTable(
    List<String> players,
    Map<String, String> playerNames,
    Map<String, dynamic> playerCards,
    int currentTurn,
    List<String> winners,
  ) {
    List<Widget> playerWidgets = [];
    final centerX = 225.0; // Adjusted for larger table
    final centerY = 140.0;
    final radiusX = 260.0; // Larger radius for landscape
    final radiusY = 180.0;

    // Filter out current player (they'll be at bottom)
    final otherPlayers = players.where((p) => p != _playerId).toList();
    final totalOtherPlayers = otherPlayers.length;

    for (int i = 0; i < totalOtherPlayers; i++) {
      final playerId = otherPlayers[i];
      // Get player name with fallback
      final playerName = playerNames[playerId] ?? 'Player ${i + 1}';
      final cardCount = (playerCards[playerId] as List?)?.length ?? 0;
      final playerIndex = players.indexOf(playerId);
      final isCurrentPlayer = playerIndex == currentTurn % players.length;

      // Calculate position around ellipse
      double angle;
      if (totalOtherPlayers == 1) {
        angle = math.pi; // Top center
      } else {
        // Distribute players around the top 3/4 of the ellipse for better landscape layout
        angle = math.pi * 0.25 + (i / (totalOtherPlayers - 1)) * math.pi * 1.5;
      }

      final x = centerX + radiusX * math.cos(angle);
      final y = centerY + radiusY * math.sin(angle);

      playerWidgets.add(
        Positioned(
          left: x - 50,
          top: y - 40,
          child: _buildPlayerAvatar(playerName, cardCount, isCurrentPlayer, angle, winners.contains(playerId)),
        ),
      );
    }

    return playerWidgets;
  }

  Widget _buildPlayerAvatar(String name, int cardCount, bool isCurrentTurn, double angle, bool isWinner) {
    // Ensure we display a proper name
    final displayName = name.isNotEmpty ? name : 'Player';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player cards (back of cards) - don't show if winner
        if (cardCount > 0 && !isWinner) _buildPlayerCardFan(cardCount, angle),
        
        // Winner crown if player is a winner
        if (isWinner) ...[
          const Icon(
            Icons.emoji_events,
            color: Color(0xFFD4AF37),
            size: 30,
          ),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 8),
        
        // Player info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isWinner 
                ? const Color(0xFFD4AF37) 
                : isCurrentTurn 
                    ? const Color(0xFFD4AF37) 
                    : const Color(0xFF8B4513),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isWinner 
                  ? Colors.white 
                  : isCurrentTurn 
                      ? Colors.white 
                      : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  color: (isWinner || isCurrentTurn) ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isWinner ? 'Winner!' : '$cardCount cards',
                style: TextStyle(
                  color: (isWinner || isCurrentTurn) ? Colors.black54 : Colors.white70,
                  fontSize: 10,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCardFan(int cardCount, double angle) {
    List<Widget> cards = [];
    final maxCardsToShow = math.min(cardCount, 6);
    
    for (int i = 0; i < maxCardsToShow; i++) {
      cards.add(
        Container(
          width: 18,
          height: 25,
          margin: EdgeInsets.only(left: i * 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1a237e),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.casino,
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 60,
      height: 30,
      child: Stack(children: cards),
    );
  }

  Widget _buildCenterCards(List<dynamic> playedCards, bool isFirstRound, bool shouldStartWithAceOfSpades) {
    if (playedCards.isEmpty) {
      return Positioned(
        left: 180,
        top: 120,
        child: SizedBox(
          width: 140,
          height: 60,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shouldStartWithAceOfSpades 
                      ? 'Play Ace of Spades!' 
                      : isFirstRound 
                          ? 'First Round' 
                          : 'Follow Suit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shouldStartWithAceOfSpades
                      ? 'You must start with Ace of Spades'
                      : isFirstRound 
                          ? 'All cards go to discard'
                          : 'Waiting for cards...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show lead suit information
    final leadCard = CardModel.fromJson(playedCards.first);
    final leadSuit = leadCard.suit;

    return Positioned(
      left: 180,
      top: 100,
      child: SizedBox(
        width: 180, // Increased width to accommodate more cards
        height: 120,
        child: Column(
          children: [
            // Lead suit indicator
            if (!isFirstRound) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lead: ${_getCardSymbol(leadSuit)}',
                  style: TextStyle(
                    color: _getCardColor(leadSuit),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Played cards
            Expanded(
              child: Stack(
                children: playedCards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cardData = entry.value;
                  final card = CardModel.fromJson(cardData);
                  
                  return Positioned(
                    left: index * 20.0, // Increased horizontal offset
                    top: index * 6.0,   // Increased vertical offset
                    child: _buildPlayedCard(card),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayedCard(CardModel card) {
    return Container(
      width: 40,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          card.image,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.white,
              child: const Center(
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getCardSymbol(card.suit),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getCardColor(card.suit),
                    ),
                  ),
                  Text(
                    card.value,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _getCardColor(card.suit),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Add this method to sort cards by suit and value
  List<CardModel> _sortCards(List<CardModel> cards) {
    // Define suit order: Spades, Hearts, Diamonds, Clubs
    final suitOrder = ['SPADES', 'HEARTS', 'DIAMONDS', 'CLUBS'];
    
    return cards..sort((a, b) {
      // First sort by suit
      final suitComparison = suitOrder.indexOf(a.suit).compareTo(suitOrder.indexOf(b.suit));
      if (suitComparison != 0) return suitComparison;
      
      // Then sort by numeric value (ascending order)
      return a.numericValue.compareTo(b.numericValue);
    });
  }

  Widget _buildPlayerHand(List<CardModel> myCards, bool isMyTurn, bool shouldStartWithAceOfSpades, bool isCurrentPlayerWinner) {
    // If the current player is a winner, show a special winner display
    if (isCurrentPlayerWinner) {
      return Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are a Winner!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your hand was taken by another player',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (myCards.isEmpty) {
      return const Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: Center(
          child: Text(
            'No cards in hand',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    // Sort the cards before displaying
    final sortedCards = _sortCards(List<CardModel>.from(myCards));

    // Get current player's name for display
    final currentPlayerName = _playerName.isNotEmpty ? _playerName : 'You';

    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          String? leadSuit;
          bool isFirstRound = true;
          
          if (snapshot.hasData) {
            final gameData = snapshot.data!.data() as Map<String, dynamic>?;
            if (gameData != null) {
              final playedCards = List<dynamic>.from(gameData['playedCards'] ?? []);
              isFirstRound = gameData['isFirstRound'] ?? true;
              
              if (playedCards.isNotEmpty && !isFirstRound) {
                final leadCard = CardModel.fromJson(playedCards.first);
                leadSuit = leadCard.suit;
              }
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player name display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$currentPlayerName (${sortedCards.length} cards)',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Cards
              SizedBox(
                height: 100,
                child: Center(
                  child: SizedBox(
                    width: math.min(sortedCards.length * 25.0 + 60, MediaQuery.of(context).size.width - 60),
                    child: Stack(
                      children: sortedCards.asMap().entries.map((entry) {
                        final index = entry.key;
                        final card = entry.value;
                        final isSelected = _selectedCard?.code == card.code && 
                                         _selectedCard?.suit == card.suit;
                        
                        final isAceOfSpades = card.code == 'AS' || 
                            (card.value == 'ACE' && card.suit == 'SPADES');
                        
                        // Determine if this card can be played
                        bool canPlayCard = false;
                        if (shouldStartWithAceOfSpades) {
                          canPlayCard = isAceOfSpades;
                        } else if (isMyTurn) {
                          if (isFirstRound) {
                            canPlayCard = true; // Any card in first round
                          } else if (leadSuit != null) {
                            // Must follow suit if you have it
                            final hasLeadSuit = sortedCards.any((c) => c.suit == leadSuit);
                            canPlayCard = hasLeadSuit ? card.suit == leadSuit : true;
                          } else {
                            canPlayCard = true;
                          }
                        }
                        
                        final leftOffset = index * 22.0;
                        
                        return Positioned(
                          left: leftOffset,
                          bottom: isSelected ? 15 : 0,
                          child: GestureDetector(
                            onTap: canPlayCard ? () => _selectCard(card) : null,
                            child: _buildPlayerCard(
                              card, 
                              isSelected, 
                              canPlayCard
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(CardModel card, bool isSelected, bool canPlayCard) {
    final offsetValue = isSelected ? 4.0 : 2.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 45,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canPlayCard 
              ? (isSelected ? const Color(0xFFD4AF37) : Colors.green)
              : (isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade400),
          width: canPlayCard ? (isSelected ? 3 : 2) : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.4 : 0.2),
            blurRadius: isSelected ? 8 : 4,
            offset: Offset(0, offsetValue),
          ),
        ],
      ),
      child: Stack(
        children: [
          Transform.rotate(
            angle: math.pi, // 180 degrees rotation
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                card.image,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white,
                    child: const Center(
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getCardSymbol(card.suit),
                          style: TextStyle(
                            fontSize: 18,
                            color: _getCardColor(card.suit),
                          ),
                        ),
                        Text(
                          card.value,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getCardColor(card.suit),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Playable indicator
          if (canPlayCard && !isSelected)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool shouldStartWithAceOfSpades, bool canTakeFullHand, String leftPlayerId, Map<String, String> playerNames) {
    return Positioned(
      bottom: 120, // Position above the player's hand
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Swap button on the left
          if (canTakeFullHand)
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: FloatingActionButton(
                heroTag: "swap_cards",
                onPressed: _isTakingFullHand ? null : () => _takeFullHand(leftPlayerId),
                backgroundColor: const Color(0xFFD4AF37),
                mini: true,
                child: _isTakingFullHand
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz, color: Colors.black, size: 20),
              ),
            )
          else
            const SizedBox(width: 60), // Placeholder to maintain layout

          // Play card button on the right
          if (_selectedCard != null)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: FloatingActionButton(
                heroTag: "play_card",
                onPressed: _isPlayingCard ? null : () => _playSelectedCard(shouldStartWithAceOfSpades),
                backgroundColor: shouldStartWithAceOfSpades 
                    ? Colors.orange 
                    : const Color(0xFFD4AF37),
                mini: true,
                child: _isPlayingCard
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
              ),
            )
          else
            const SizedBox(width: 60), // Placeholder to maintain layout
        ],
      ),
    );
  }

  void _selectCard(CardModel card) {
    setState(() {
      if (_selectedCard?.code == card.code && _selectedCard?.suit == card.suit) {
        _selectedCard = null;
      } else {
        _selectedCard = card;
      }
    });
  }

  Future<void> _playSelectedCard(bool shouldStartWithAceOfSpades) async {
    if (_selectedCard == null) return;
    
    // Validate Ace of Spades rule
    if (shouldStartWithAceOfSpades) {
      final isAceOfSpades = _selectedCard!.code == 'AS' || 
          (_selectedCard!.value == 'ACE' && _selectedCard!.suit == 'SPADES');
      
      if (!isAceOfSpades) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must start the game with Ace of Spades!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    setState(() => _isPlayingCard = true);
    
    try {
      await _firebaseService.playCard(widget.roomCode, _selectedCard!);
      setState(() {
        _selectedCard = null;
        _isPlayingCard = false;
      });
      _cardAnimationController.forward().then((_) {
        _cardAnimationController.reset();
      });
    } catch (e) {
      setState(() => _isPlayingCard = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeFullHand(String leftPlayerId) async {
    setState(() => _isTakingFullHand = true);
    
    try {
      await _firebaseService.takeFullHand(widget.roomCode);
      setState(() => _isTakingFullHand = false);
      _cardAnimationController.forward().then((_) {
        _cardAnimationController.reset();
      });
    } catch (e) {
      setState(() => _isTakingFullHand = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getCardSymbol(String suit) {
    switch (suit.toUpperCase()) {
      case 'HEARTS':
        return '♥';
      case 'DIAMONDS':
        return '♦';
      case 'CLUBS':
        return '♣';
      case 'SPADES':
        return '♠';
      default:
        return '?';
    }
  }

  Color _getCardColor(String suit) {
    switch (suit.toUpperCase()) {
      case 'HEARTS':
      case 'DIAMONDS':
        return Colors.red;
      case 'CLUBS':
      case 'SPADES':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}

// Custom painter for wood grain background
class WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513).withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < size.height; i += 25) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
