import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _textController;
  late AnimationController _loaderController;
  
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loaderAnimation;

  @override
  void initState() {
    super.initState();
    
    // Card animations
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _cardScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.elasticOut,
      ),
    );
    
    _cardRotationAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Text animations
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );
    
    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );
    
    // Loader animation
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _loaderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loaderController,
        curve: Curves.easeInOut,
      ),
    );
    
    _startAnimations();
  }

  void _startAnimations() async {
    // Start card animation
    await _cardController.forward();
    
    // Start text animation after card animation
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
    
    // Start loader animation
    await Future.delayed(const Duration(milliseconds: 500));
    _loaderController.repeat();
    
    // Navigate to login after total delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated Card Logo
              AnimatedBuilder(
                animation: _cardController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _cardRotationAnimation.value,
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 150,
                            height: 200,
                            color: Colors.white,
                            child: Image.asset(
                              'assets/deck2.webp',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Animated Text
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _textSlideAnimation.value),
                    child: Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Column(
                        children: [
                          const Text(
                            'Getway Card Game',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Play with Friends',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const Spacer(flex: 1),
              
              // Animated Loader
              AnimatedBuilder(
                animation: _loaderAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      // Custom card-themed loader
                      SizedBox(
                        width: 60,
                        height: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            double delay = index * 0.25;
                            double animationValue = (_loaderAnimation.value - delay).clamp(0.0, 1.0);
                            
                            return Transform.scale(
                              scale: 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2)).clamp(0.0, 1.0),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index.isEven ? const Color(0xFFE94560) : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (index.isEven ? const Color(0xFFE94560) : Colors.white).withOpacity(0.5),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const Spacer(flex: 1),
              
              // Footer Text (matching login screen position at bottom)
              const Text(
                'Play with friends in real-time\nExperience the classic card game',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }
}