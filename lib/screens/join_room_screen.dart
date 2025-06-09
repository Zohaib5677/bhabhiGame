import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import 'lobby_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isJoining = false;
  late AnimationController _cardAnimationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

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

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _slideController,
                              curve: Curves.easeOutBack,
                            )),
                            child: FadeTransition(
                              opacity: _slideController,
                              child: _buildJoinRoomCard(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Loading overlay
              if (_isJoining)
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
                          'Joining room...',
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.meeting_room, color: Color(0xFFE94560), size: 28),
        const SizedBox(width: 8),
        const Text(
          'Join Game Room',
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
      children: List.generate(6, (index) {
        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            final double animationValue = _cardAnimationController.value;
            final double rotation = (animationValue * 2 * 3.14159) + (index * 0.7);
            final double xOffset = 40 + (index * 70) + (35 * (animationValue - 0.5));
            final double yOffset = 120 + (index * 90) + (25 * (animationValue - 0.5));
            
            return Positioned(
              left: xOffset,
              top: yOffset,
              child: Transform.rotate(
                angle: rotation * 0.1,
                child: Opacity(
                  opacity: 0.06 + (0.04 * animationValue),
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
                        '♣',
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

  Widget _buildJoinRoomCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F4F).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header section
            _buildHeader(),
            
            const SizedBox(height: 40),
            
            // Room code input
            _buildRoomCodeInput(),
            
            const SizedBox(height: 24),
            
            // Player name input
            _buildPlayerNameInput(),
            
            const SizedBox(height: 40),
            
            // Join button
            _buildJoinButton(),
            
            const SizedBox(height: 20),
            
            // Help text
            _buildHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE94560).withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.meeting_room,
            size: 40,
            color: Color(0xFFE94560),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Join Game Room',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the room code to join your friends!',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoomCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F38).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: TextFormField(
            controller: _codeController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
            decoration: const InputDecoration(
              hintText: 'ABCD12',
              hintStyle: TextStyle(
                color: Colors.white38,
                letterSpacing: 3,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.length != 6) {
                return 'Please enter a 6-character room code';
              }
              return null;
            },
            onChanged: (value) {
              if (value.length == 6) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F38).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: TextFormField(
            controller: _nameController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            maxLength: 20,
            decoration: const InputDecoration(
              hintText: 'Enter your display name',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: '',
              prefixIcon: Icon(Icons.person, color: Colors.white38),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isJoining ? null : _joinRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94560),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          shadowColor: const Color(0xFFE94560).withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isJoining)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.login, size: 24),
            const SizedBox(width: 12),
            Text(
              _isJoining ? 'Joining...' : 'Join Room',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F38).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFE94560),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ask your friend for the 6-character room code to join their game.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isJoining = true;
    });

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    try {
      await _firebaseService.joinGameRoom(code, name);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LobbyScreen(roomCode: code, isHost: false),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to join room: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
