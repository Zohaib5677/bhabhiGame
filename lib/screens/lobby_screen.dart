// screens/lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const LobbyScreen({super.key, required this.roomCode, required this.isHost});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _cardAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldLeave = await _showLeaveConfirmation();
          if (shouldLeave && mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1F38),
                Color(0xFF0A0E21),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Floating card animations in background
                _buildFloatingCards(),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Custom App Bar
                      _buildCustomAppBar(),
                      
                      const SizedBox(height: 20),
                      
                      // Room Info Card
                      _buildRoomInfoCard(),
                      
                      const SizedBox(height: 20),
                      
                      // Players Section
                      Expanded(
                        child: _buildPlayersSection(),
                      ),
                      
                      // Start game button (for host) - moved outside players section
                      _buildStartGameButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2F4F).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              final shouldLeave = await _showLeaveConfirmation();
              if (shouldLeave && mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.people_alt, color: Color(0xFFE94560), size: 28),
        const SizedBox(width: 8),
        const Text(
          'Game Lobby',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.isHost)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'HOST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFloatingCards() {
    return Stack(
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            final double animationValue = _cardAnimationController.value;
            final double rotation = (animationValue * 2 * 3.14159) + (index * 0.8);
            final double xOffset = 30 + (index * 100) + (40 * (animationValue - 0.5));
            final double yOffset = 150 + (index * 80) + (30 * (animationValue - 0.5));
            
            return Positioned(
              left: xOffset,
              top: yOffset,
              child: Transform.rotate(
                angle: rotation * 0.1,
                child: Opacity(
                  opacity: 0.05 + (0.05 * animationValue),
                  child: Container(
                    width: 35,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '♦',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F4F).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Room code section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room Code',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.roomCode,
                      style: const TextStyle(
                        color: Color(0xFFE94560),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                      onPressed: _copyCodeToClipboard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFFE94560)),
                  onPressed: _shareRoomCode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firebaseService.getRoomStream(widget.roomCode),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F4F).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, color: Colors.white54, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Room not found',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final players = List<String>.from(roomData['players'] ?? []);
        final maxPlayers = roomData['maxPlayers'] ?? 6;

        return Column(
          children: [
            // Players header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F4F).withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Players',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${players.length}/$maxPlayers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Players grid
            Expanded(
              child: players.isEmpty
                  ? _buildWaitingForPlayers()
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: maxPlayers,
                      itemBuilder: (context, index) {
                        if (index < players.length) {
                          return _buildPlayerCard(players[index], index, true);
                        } else {
                          return _buildPlayerCard('Waiting...', index, false);
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerCard(String playerName, int index, bool isJoined) {
    return Container(
      decoration: BoxDecoration(
        color: isJoined 
            ? const Color(0xFF2A2F4F).withOpacity(0.9)
            : const Color(0xFF1A1F38).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isJoined ? const Color(0xFFE94560) : Colors.white24,
          width: 1,
        ),
        boxShadow: isJoined ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Player avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isJoined ? const Color(0xFFE94560) : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: isJoined
                    ? Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : const Icon(
                        Icons.person_add,
                        color: Colors.white54,
                        size: 20,
                      ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Player name
            Text(
              playerName,
              style: TextStyle(
                color: isJoined ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingForPlayers() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Waiting for players to join...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Share the room code with your friends!',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStartGameButton() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firebaseService.getRoomStream(widget.roomCode),
      builder: (context, snapshot) {
        if (!widget.isHost || !snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final players = List<String>.from(roomData['players'] ?? []);

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: players.length >= 2 ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: players.length >= 2 
                    ? const Color(0xFFE94560) 
                    : const Color(0xFF2A2F4F),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF2A2F4F),
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 24, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Start Game',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showLeaveConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2F4F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Leave Game Lobby?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to leave this game lobby? You will return to the home screen.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Stay',
              style: TextStyle(color: Color(0xFFE94560)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _copyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareRoomCode() {
    Share.share(
      'Join my card game! Room code: ${widget.roomCode}\n\nDownload the app and enter this code to play together!',
      subject: 'Join card game!',
    );
  }

  void _startGame() {
    _firebaseService.startGame(widget.roomCode);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(roomCode: widget.roomCode)),
    );
  }
}