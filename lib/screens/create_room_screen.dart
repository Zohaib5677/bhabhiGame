// screens/create_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import 'lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedPlayerCount = 2;
  bool _isCreating = false;
  String? _createdRoomCode;
  late AnimationController _cardAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
      canPop: _createdRoomCode == null,
      onPopInvoked: (didPop) async {
        if (!didPop && _createdRoomCode != null) {
          final shouldExit = await _showBackConfirmation();
          if (shouldExit && mounted) {
            Navigator.pop(context);
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
                      
                      const SizedBox(height: 30),
                      
                      if (_createdRoomCode == null) ...[
                        // Create Room Section
                        _buildCreateRoomSection(),
                      ] else ...[
                        // Room Created Section
                        _buildRoomCreatedSection(),
                      ],
                    ],
                  ),
                ),
                
                // Loading overlay
                if (_isCreating)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Creating your game room...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
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
              if (_createdRoomCode != null) {
                final shouldExit = await _showBackConfirmation();
                if (shouldExit) Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.add_circle_outline, color: Color(0xFFE94560), size: 28),
        const SizedBox(width: 8),
        const Text(
          'Create Game Room',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCards() {
    return Stack(
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            final double animationValue = _cardAnimationController.value;
            final double rotation = (animationValue * 2 * 3.14159) + (index * 0.5);
            final double xOffset = 50 + (index * 80) + (30 * (animationValue - 0.5));
            final double yOffset = 100 + (index * 60) + (20 * (animationValue - 0.5));
            
            return Positioned(
              left: xOffset,
              top: yOffset,
              child: Transform.rotate(
                angle: rotation * 0.1,
                child: Opacity(
                  opacity: 0.1 + (0.1 * animationValue),
                  child: Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '♠',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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

  Widget _buildCreateRoomSection() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main card container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F4F).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Card game icon
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '♠',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'GETWAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                const Text(
                  'Setup Your Game',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Choose the number of players for your game',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                // Player count selector
                _buildPlayerCountSelector(),
                
                const SizedBox(height: 40),
                
                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : () => _createRoom(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Create Room',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Test API button (hidden in production)
          if (true) // You can set this to false in production
            TextButton(
              onPressed: _testDeckApi,
              child: const Text(
                'Test Deck API',
                style: TextStyle(color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCountSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Players:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE94560),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_selectedPlayerCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFE94560),
            inactiveTrackColor: const Color(0xFF1A1F38),
            thumbColor: const Color(0xFFE94560),
            overlayColor: const Color(0xFFE94560).withOpacity(0.2),
            valueIndicatorColor: const Color(0xFFE94560),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _selectedPlayerCount.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            label: '$_selectedPlayerCount players',
            onChanged: (value) {
              setState(() {
                _selectedPlayerCount = value.toInt();
              });
            },
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Player count indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final playerCount = index + 2;
            final isSelected = _selectedPlayerCount == playerCount;
            return Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE94560) : const Color(0xFF1A1F38),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$playerCount',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRoomCreatedSection() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F4F).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Room Created!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Room code display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F38),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE94560), width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Room Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _createdRoomCode!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy,  color: Colors.white,),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _createdRoomCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Room code copied to clipboard!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareRoomCode,
                        icon: const Icon(Icons.share),
                        label: const Text('Share Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 88, 97, 154),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startGame,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 50),
          
          const Text(
            'Share the room code with your friends\nto start playing together!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showBackConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2F4F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Leave Room Creation?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          _createdRoomCode != null 
            ? 'Your room has been created. Are you sure you want to leave?'
            : 'Are you sure you want to cancel room creation?',
          style: const TextStyle(color: Colors.white70),
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

  Future<void> _createRoom(BuildContext context) async {
    setState(() => _isCreating = true);
    
    try {
      final roomCode = await _firebaseService.createGameRoom(_selectedPlayerCount);
      setState(() {
        _createdRoomCode = roomCode;
        _isCreating = false;
      });
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareRoomCode() {
    if (_createdRoomCode != null) {
      Share.share(
        'Join my  card game! Room code: $_createdRoomCode\n\nDownload the app and enter this code to play together!',
        subject: 'Join  card game!',
      );
    }
  }

  void _startGame() {
    if (_createdRoomCode != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyScreen(roomCode: _createdRoomCode!, isHost: true),
        ),
      );
    }
  }

  Future<void> _testDeckApi() async {
    try {
      final shuffleResponse = await http.get(
        Uri.parse('https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1'),
      );
      print('🔄 Shuffle API response: ${shuffleResponse.body}');

      if (shuffleResponse.statusCode != 200) {
        print('❌ Failed to create and shuffle deck');
        return;
      }

      final shuffleData = json.decode(shuffleResponse.body);
      final deckId = shuffleData['deck_id'];
      print('🆔 Deck ID: $deckId');

      final drawResponse = await http.get(
        Uri.parse('https://deckofcardsapi.com/api/deck/$deckId/draw/?count=5'),
      );
      print('🃏 Draw Cards API response: ${drawResponse.body}');

      if (drawResponse.statusCode != 200) {
        print('❌ Failed to draw cards');
        return;
      }

      final drawData = json.decode(drawResponse.body);
      print('🎴 Cards drawn: ${drawData['cards']}');
    } catch (e) {
      print('❗ Error testing Deck of Cards API: $e');
    }
  }
}
