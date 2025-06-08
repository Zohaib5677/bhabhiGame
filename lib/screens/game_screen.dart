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

  String get _playerId => _auth.currentUser?.uid ?? '';
  String get _playerName => _auth.currentUser?.displayName ?? 'Player';

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

    if (gameStatus == 'ended') {
      return _buildGameEndScreen(gameData);
    }

    return Stack(
      children: [
        // Background pattern
        _buildBackgroundPattern(),
        
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
                ..._buildPlayersAroundTable(players, playerNames, playerCards, currentTurn),
                
                // Center played cards
                _buildCenterCards(playedCards, isFirstRound, shouldStartWithAceOfSpades),
                
                // Current player's hand at bottom
                _buildPlayerHand(myCards, isMyTurn, shouldStartWithAceOfSpades),
              ],
            ),
          ),
        ),
        
        // Top bar with room info
        _buildTopBar(isFirstRound),
        
        // Action buttons
        if (isMyTurn || shouldStartWithAceOfSpades) _buildActionButtons(shouldStartWithAceOfSpades),
      ],
    );
  }

  Widget _buildGameEndScreen(Map<String, dynamic> gameData) {
    final winner = gameData['winner'];
    final bhabhi = gameData['bhabhi'];
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
                '🏆 Winner: ${playerNames[winner] ?? "Unknown"}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (bhabhi != null) ...[
              Text(
                '😅 Bhabhi: ${playerNames[bhabhi] ?? "Unknown"}',
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
          child: _buildPlayerAvatar(playerName, cardCount, isCurrentPlayer, angle),
        ),
      );
    }

    return playerWidgets;
  }

  Widget _buildPlayerAvatar(String name, int cardCount, bool isCurrentTurn, double angle) {
    // Ensure we display a proper name
    final displayName = name.isNotEmpty ? name : 'Player';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player cards (back of cards)
        if (cardCount > 0) _buildPlayerCardFan(cardCount, angle),
        
        const SizedBox(height: 8),
        
        // Player info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCurrentTurn ? const Color(0xFFD4AF37) : const Color(0xFF8B4513),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isCurrentTurn ? Colors.white : Colors.transparent,
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
                  color: isCurrentTurn ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$cardCount cards',
                style: TextStyle(
                  color: isCurrentTurn ? Colors.black54 : Colors.white70,
                  fontSize: 10,
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
        width: 140,
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
                    left: index * 12.0,
                    top: index * 4.0,
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

  Widget _buildPlayerHand(List<CardModel> myCards, bool isMyTurn, bool shouldStartWithAceOfSpades) {
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
                  '$currentPlayerName (${myCards.length} cards)',
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
                    width: math.min(myCards.length * 25.0 + 60, MediaQuery.of(context).size.width - 60),
                    child: Stack(
                      children: myCards.asMap().entries.map((entry) {
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
                            final hasLeadSuit = myCards.any((c) => c.suit == leadSuit);
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColorFiltered(
              colorFilter: canPlayCard 
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : ColorFilter.mode(Colors.grey.shade400, BlendMode.saturation),
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

  Widget _buildTopBar(bool isFirstRound) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(15), // Reduced radius
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24), // Smaller icon
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(4), // Reduced padding
            ),
            const SizedBox(width: 8),
            Text(
              'Room: ${widget.roomCode}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
              decoration: BoxDecoration(
                color: isFirstRound ? Colors.orange : Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isFirstRound ? 'First Round' : 'Regular Play',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool shouldStartWithAceOfSpades) {
    return Positioned(
      bottom: 120,
      right: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedCard != null)
            FloatingActionButton.extended(
              heroTag: "play_card",
              onPressed: _isPlayingCard ? null : () => _playSelectedCard(shouldStartWithAceOfSpades),
              backgroundColor: shouldStartWithAceOfSpades 
                  ? Colors.orange 
                  : const Color(0xFFD4AF37),
              icon: _isPlayingCard
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(
                _isPlayingCard 
                    ? 'Playing...' 
                    : shouldStartWithAceOfSpades 
                        ? 'Start Game' 
                        : 'Play Card',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
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
