import 'package:flutter/material.dart';
import 'package:bhabi/services/auth_service.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  final AuthService _authService = AuthService();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Dot> _dots = [];
  final int _dotCount = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    // Initialize dots
    for (int i = 0; i < _dotCount; i++) {
      _dots.add(Dot());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDots(Offset position) {
    setState(() {
      for (var dot in _dots) {
        dot.reactToPosition(position);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Stack(
          children: [
            // Animated Background Dots
            Positioned.fill(
              child: MouseRegion(
                onHover: (event) => _updateDots(event.position),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: DotPainter(
                        dots: _dots,
                        time: _controller.value * 2 * 3.1416,
                      ),
                      size: size,
                    );
                  },
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.spa, color: Color(0xFFE94560)),
                          SizedBox(width: 8),
                          Text(
                            'BHABHI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await widget._authService.signOut();
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Welcome Message
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Player ${widget._authService.currentUserUid?.substring(0, 5) ?? 'Guest'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Compact Game Cards
                  Center(
                    child: SizedBox(
                      width: 300, // Fixed width for compact cards
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CompactGameCard(
                            icon: Icons.add_circle_outline,
                            title: "Create Game",
                            description: "Start a fresh card table",
                            color: const Color(0xFFE94560),
                            onTap: () => Navigator.pushNamed(context, '/create'),
                          ),
                          const SizedBox(height: 20),
                          _CompactGameCard(
                            icon: Icons.people_alt_outlined,
                            title: "Join Game",
                            description: "Join existing tables",
                            color: const Color(0xFF2A2F4F),
                            onTap: () => Navigator.pushNamed(context, '/join'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Footer
                  const Center(
                    child: Text(
                      'Play with friends in real-time\nExperience the classic card game',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactGameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _CompactGameCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F38).withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white, // 🔴 White Icon (only inside the card)
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white, // 🔴 Right arrow also white
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dot class and DotPainter class unchanged
class Dot {
  Offset position = Offset.zero;
  double size = 0;
  Color color = Colors.transparent;
  double baseSize = 0;
  Offset basePosition = Offset.zero;
  double speed = 0;

  Dot() {
    reset();
  }

  void reset() {
    position = Offset(
      Random().nextDouble(),
      Random().nextDouble(),
    );
    baseSize = Random().nextDouble() * 3 + 1;
    size = baseSize;
    color = Color(0xFF2A2F4F).withOpacity(Random().nextDouble() * 0.3 + 0.1);
    basePosition = position;
    speed = Random().nextDouble() * 0.2 + 0.05;
  }

  void reactToPosition(Offset pointerPosition) {
    final dx = (pointerPosition.dx - position.dx * 1000) / 1000;
    final dy = (pointerPosition.dy - position.dy * 1000) / 1000;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < 0.3) {
      size = baseSize * 3;
      position = Offset(
        position.dx - dx * 0.02,
        position.dy - dy * 0.02,
      );
    } else {
      size = baseSize;
    }
  }

  void update(double time) {
    // Move dots in circular pattern
    position = Offset(
      basePosition.dx + sin(time * speed) * 0.1,
      basePosition.dy + cos(time * speed) * 0.1,
    );
  }
}

class DotPainter extends CustomPainter {
  final List<Dot> dots;
  final double time;

  DotPainter({required this.dots, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (var dot in dots) {
      dot.update(time);
      final paint = Paint()
        ..color = dot.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(dot.position.dx * size.width, dot.position.dy * size.height),
        dot.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}