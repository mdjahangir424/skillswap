import 'home_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF073A91),
              Color(0xFF061B55),
              Color(0xFF073A91),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              ShaderMask(
                shaderCallback: (bounds) =>
                    const LinearGradient(
                  colors: [
                    Color(0xFF00C8FF),
                    Color(0xFF793BFF),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'S',
                  style: TextStyle(
                    fontSize: 112,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),

              const SizedBox(height: 2),

              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 39,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Skill',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'Swap',
                      style: TextStyle(color: Color(0xFF9B70FF)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Learn. Teach. Exchange.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'A World of Skills,\nOne Community.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 1),

              const Expanded(
                flex: 3,
                child: _GlobeNetwork(),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 18,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Welcome to SkillSwap!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF073A91),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Get Started  →',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobeNetwork extends StatelessWidget {
  const _GlobeNetwork();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlobePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final radius = size.width * 0.39;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF12BFFF).withOpacity(0.38),
          const Color(0xFF0878FF).withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius * 1.4),
      );

    canvas.drawCircle(center, radius * 1.4, glow);

    final globePaint = Paint()
      ..color = const Color(0xFF35CFFF).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Globe outline
    canvas.drawCircle(center, radius, globePaint);

    // Longitude curves
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 0.9,
        height: radius * 2,
      ),
      globePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 1.55,
        height: radius * 2,
      ),
      globePaint,
    );

    // Latitude curves
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 0.65,
      ),
      globePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 1.35,
      ),
      globePaint,
    );

    final points = [
      Offset(size.width * 0.12, size.height * 0.45),
      Offset(size.width * 0.28, size.height * 0.29),
      Offset(size.width * 0.49, size.height * 0.24),
      Offset(size.width * 0.73, size.height * 0.33),
      Offset(size.width * 0.88, size.height * 0.49),
      Offset(size.width * 0.30, size.height * 0.70),
      Offset(size.width * 0.70, size.height * 0.70),
    ];

    final connections = [
      [0, 1], [1, 2], [2, 3], [3, 4],
      [0, 5], [5, 6], [6, 4],
      [1, 5], [3, 6],
    ];

    final linePaint = Paint()
      ..color = const Color(0xFF45DFFF).withOpacity(0.65)
      ..strokeWidth = 1.3;

    for (final pair in connections) {
      canvas.drawLine(
        points[pair[0]],
        points[pair[1]],
        linePaint,
      );
    }

    final nodePaint = Paint()
      ..color = const Color(0xFF24D6FF);

    for (final point in points) {
      canvas.drawCircle(
        point,
        10,
        Paint()..color = const Color(0xFF24D6FF).withOpacity(0.16),
      );
      canvas.drawCircle(point, 4, nodePaint);
    }

    // Small profile circles
    final avatarPositions = [
      Offset(size.width * 0.12, size.height * 0.45),
      Offset(size.width * 0.82, size.height * 0.45),
      Offset(size.width * 0.28, size.height * 0.29),
      Offset(size.width * 0.70, size.height * 0.33),
    ];

    for (final point in avatarPositions) {
      canvas.drawCircle(
        point,
        13,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        point,
        10,
        Paint()..color = const Color(0xFF9CCEFF),
      );
      canvas.drawCircle(
        Offset(point.dx, point.dy - 2),
        3.5,
        Paint()..color = const Color(0xFF073A91),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(point.dx, point.dy + 5),
          width: 9,
          height: 5,
        ),
        Paint()..color = const Color(0xFF073A91),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
