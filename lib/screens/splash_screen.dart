import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _cardsController;
  late AnimationController _particlesController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _cardsSpreadAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particlesAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Main controller for primary animations
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Cards spread animation controller
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Particles animation controller
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    // Pulse effect controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _logoRotationAnimation = Tween<double>(begin: math.pi, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Title animations
    _titleSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Cards spread animation
    _cardsSpreadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: Curves.easeOutBack,
      ),
    );

    // Glow pulse animation
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Particles animation
    _particlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particlesController,
        curve: Curves.linear,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Start particles animation immediately
    _particlesController.repeat();
    
    // Start main animation
    await Future.delayed(const Duration(milliseconds: 300));
    _mainController.forward();
    
    // Start cards spread after logo appears
    await Future.delayed(const Duration(milliseconds: 800));
    _cardsController.forward();
    
    // Start pulse effect
    await Future.delayed(const Duration(milliseconds: 500));
    _pulseController.repeat(reverse: true);
    
    // Navigate to login after total sequence
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced background with card pattern
          _buildEnhancedBackground(),
          
          // Floating particles
          _buildFloatingParticles(),
          
          // Main content
          _buildMainContent(),
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
            Color(0xFF1A1F38),  // Your original color
            Color(0xFF0A0E21),  // Your original dark color
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          
          // Animated card stack with glow effect
          _buildAnimatedCardStack(),
          
          const SizedBox(height: 50),
          
          // Animated title section
          _buildAnimatedTitle(),
          
          const Spacer(flex: 1),
          
          // Enhanced loading indicator
          _buildEnhancedLoader(),
          
          const Spacer(flex: 1),
          
          // Footer with enhanced styling
          _buildStyledFooter(),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAnimatedCardStack() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _cardsController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotationAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing background effect
                Container(
                  width: 180 * _glowAnimation.value,
                  height: 230 * _glowAnimation.value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE94560).withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 30 * _glowAnimation.value,
                        spreadRadius: 10 * _glowAnimation.value,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1 * _glowAnimation.value),
                        blurRadius: 50 * _glowAnimation.value,
                        spreadRadius: 5 * _glowAnimation.value,
                      ),
                    ],
                  ),
                ),
                
                // Background cards (spread effect)
                ...List.generate(3, (index) {
                  double offset = (index - 1) * 15 * _cardsSpreadAnimation.value;
                  double rotation = (index - 1) * 0.2 * _cardsSpreadAnimation.value;
                  
                  return Transform.translate(
                    offset: Offset(offset, -offset.abs() * 0.5),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Opacity(
                        opacity: 0.3 + (0.7 * (1 - index * 0.2)),
                        child: _buildSingleCard(),
                      ),
                    ),
                  );
                }),
                
                // Main card
                _buildSingleCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleCard() {
    return Container(
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F8F8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFE94560).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Card pattern overlay
            CustomPaint(
              painter: CardDesignPainter(),
              size: const Size(150, 200),
            ),
            
            // Your image
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/deck2.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _titleSlideAnimation.value),
          child: Opacity(
            opacity: _titleFadeAnimation.value,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFE94560),
                      Color(0xFFFFFFFF),
                      Color(0xFFE94560),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'GETWAY',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'CARD GAME',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE94560).withOpacity(0.5),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE94560).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Text(
                    'Play with Friends',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLoader() {
    return AnimatedBuilder(
      animation: _particlesAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Card-themed loader with more visual appeal
            SizedBox(
              width: 80,
              height: 20,
              child: Stack(
                children: List.generate(5, (index) {
                  double delay = index * 0.2;
                  double animationValue = ((_particlesAnimation.value * 2) - delay).clamp(0.0, 1.0);
                  
                  return Positioned(
                    left: index * 15.0,
                    child: Transform.scale(
                      scale: 0.3 + (0.7 * math.sin(animationValue * math.pi)),
                      child: Container(
                        width: 12,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              index.isEven ? const Color(0xFFE94560) : Colors.white,
                              index.isEven ? const Color(0xFFB73E56) : const Color(0xFFE0E0E0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (index.isEven ? const Color(0xFFE94560) : Colors.white)
                                  .withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.4),
                ],
                stops: const [0.0, 0.5, 1.0],
                transform: GradientRotation(_particlesAnimation.value * 2 * math.pi),
              ).createShader(bounds),
              child: const Text(
                'Loading Game...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStyledFooter() {
    return Container(
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
        'Experience the ultimate card game\nChallenge friends in real-time battles',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white60,
          fontSize: 13,
          height: 1.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _cardsController.dispose();
    _particlesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

// Custom painter for background card pattern
class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle card patterns in background
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

// Custom painter for floating particles
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i + math.sin(animationValue * 2 * math.pi + i) * 30;
      final y = (size.height / 20) * (i % 4) + 
               math.cos(animationValue * 2 * math.pi + i * 0.5) * 20 +
               (animationValue * size.height * 0.1);
      
      paint.color = (i.isEven ? const Color(0xFFE94560) : Colors.white)
          .withOpacity(0.1 + 0.2 * math.sin(animationValue * math.pi + i));
      
      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        2 + math.sin(animationValue * 4 * math.pi + i) * 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Custom painter for card design details
class CardDesignPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle corner decorations
    paint.color = const Color(0xFFE94560).withOpacity(0.1);
    
    // Top corners
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
    
    // Bottom corners
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