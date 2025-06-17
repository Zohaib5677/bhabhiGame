import 'package:flutter/material.dart';
import 'package:bhabi/services/auth_service.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  late AnimationController _logoController;
  late AnimationController _buttonsController;
  late AnimationController _particlesController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoGlowAnimation;
  late Animation<double> _buttonsSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<double> _particlesAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    _logoGlowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonsSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Curves.easeIn,
      ),
    );

    _particlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particlesController,
        curve: Curves.linear,
      ),
    );
  }

  void _startAnimations() async {
    _particlesController.repeat();
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    _buttonsController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _pulseController.repeat(reverse: true);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final String? uid = await _authService.signInWithGoogle();
      if (uid != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: const Color(0xFFE94560),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      final String? uid = await _authService.signInAnonymously();
      if (uid != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guest sign-in failed: $e'),
            backgroundColor: const Color(0xFFE94560),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced background matching splash screen
          _buildEnhancedBackground(),
          
          // Floating particles
          _buildFloatingParticles(),
          
          // Main content
          _buildMainContent(),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEnhancedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF2D1B69),  // Deep purple center
            Color(0xFF1A1F38),  // Original color
            Color(0xFF0A0E21),  // Original dark color
            Color(0xFF000000),  // Pure black edges
          ],
          stops: [0.0, 0.4, 0.8, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: CardPatternPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particlesAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(_particlesAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(flex: 1),
            
            // Animated Logo Section
            _buildAnimatedLogo(),
            
            const Spacer(flex: 1),
            
            // Welcome Text
            _buildWelcomeText(),
            
            const SizedBox(height: 40),
            
            // Animated Login Buttons
            _buildAnimatedButtons(),
            
            const SizedBox(height: 30),
            
            // Enhanced Footer
            _buildEnhancedFooter(),
            
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.scale(
            scale: _logoGlowAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing background effect with pulsing
                Container(
                  width: 160,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE94560).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                
                // Main logo card
                Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2A2F4F),
                        Color(0xFF1A1F38),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFE94560).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Card pattern overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CardDesignPainter(),
                        ),
                      ),
                      
                      // Content - perfectly centered
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated icon with gradient
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE94560),
                                    Color(0xFFB73E56),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE94560).withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.spa,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Logo text with gradient - perfectly centered
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFE94560),
                                  Colors.white,
                                  Color(0xFFE94560),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'GETWAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return AnimatedBuilder(
      animation: _buttonsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _buttonsSlideAnimation.value * 0.5),
          child: Opacity(
            opacity: _buttonsFadeAnimation.value,
            child: Column(
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your sign-in method',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedButtons() {
    return AnimatedBuilder(
      animation: _buttonsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _buttonsSlideAnimation.value),
          child: Opacity(
            opacity: _buttonsFadeAnimation.value,
            child: Column(
              children: [
                // Google Sign-in Button
                _buildEnhancedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                  ),
                  text: 'Continue with Google',
                  isSecondary: false,
                ),
                
                const SizedBox(height: 16),
                
                // Divider with "OR"
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Guest Mode Button
                _buildEnhancedButton(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  icon: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  text: 'Play as Guest',
                  isSecondary: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedButton({
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    required Widget icon,
    required String text,
    required bool isSecondary,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isSecondary
            ? const LinearGradient(
                colors: [
                  Color(0xFFE94560),
                  Color(0xFFB73E56),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isSecondary 
                ? const Color(0xFFE94560).withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : backgroundColor,
          foregroundColor: foregroundColor,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary 
                ? BorderSide.none
                : BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFooter() {
    return AnimatedBuilder(
      animation: _buttonsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _buttonsSlideAnimation.value * 0.3),
          child: Opacity(
            opacity: _buttonsFadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Text(
                'Join millions of players worldwide\nExperience the ultimate card game',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE94560).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE94560),
                          Color(0xFFB73E56),
                        ],
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Signing you in...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonsController.dispose();
    _particlesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

// Fixed custom painters
class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 15; j++) {
        final rect = Rect.fromLTWH(
          i * (size.width / 8) - 50,
          j * (size.height / 12) - 30,
          30,
          40,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final x = (size.width / 15) * i + math.sin(animationValue * 2 * math.pi + i) * 25;
      final y = (size.height / 15) * (i % 3) + 
               math.cos(animationValue * 2 * math.pi + i * 0.5) * 15 +
               (animationValue * size.height * 0.1);
      
      paint.color = (i.isEven ? const Color(0xFFE94560) : Colors.white)
          .withOpacity(0.1 + 0.15 * math.sin(animationValue * math.pi + i));
      
      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        1.5 + math.sin(animationValue * 4 * math.pi + i) * 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CardDesignPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFFE94560).withOpacity(0.1);
    
    // Corner decorations
    canvas.drawArc(
      const Rect.fromLTWH(10, 10, 20, 20),
      0,
      math.pi / 2,
      false,
      paint,
    );
    
    canvas.drawArc(
      Rect.fromLTWH(size.width - 30, 10, 20, 20),
      math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
    
    canvas.drawArc(
      Rect.fromLTWH(10, size.height - 30, 20, 20),
      -math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
    
    canvas.drawArc(
      Rect.fromLTWH(size.width - 30, size.height - 30, 20, 20),
      math.pi,
      math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}