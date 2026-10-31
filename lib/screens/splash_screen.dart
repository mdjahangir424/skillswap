
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
              Color(0xFF073B91),
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
                    Color(0xFF783BFF),
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

              const SizedBox(height: 4),

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

              const SizedBox(height: 30),

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
                child: _GlobalNetwork(),
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

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalNetwork extends StatelessWidget {
  const _GlobalNetwork();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NetworkPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.57);
    final radius = size.width * 0.43;

    final globePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF16C9FF).withOpacity(0.35),
          const Color(0xFF0878FF).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, globePaint);

    final linePaint = Paint()
      ..color = const Color(0xFF44D7FF).withOpacity(0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 0.9,
      ),
      linePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 1.3,
        height: radius * 1.8,
      ),
      linePaint,
    );

    final points = [
      Offset(size.width * 0.12, size.height * 0.50),
      Offset(size.width * 0.28, size.height * 0.34),
      Offset(size.width * 0.50, size.height * 0.27),
      Offset(size.width * 0.74, size.height * 0.38),
      Offset(size.width * 0.89, size.height * 0.53),
      Offset(size.width * 0.30, size.height * 0.70),
      Offset(size.width * 0.68, size.height * 0.72),
    ];

    final connections = [
      [0, 1], [1, 2], [2, 3], [3, 4],
      [0, 5], [5, 6], [6, 4], [1, 5], [3, 6],
    ];

    for (final connection in connections) {
      canvas.drawLine(
        points[connection[0]],
        points[connection[1]],
        linePaint,
      );
    }

    final nodePaint = Paint()
      ..color = const Color(0xFF24D6FF);

    for (final point in points) {
      canvas.drawCircle(point, 4, nodePaint);
      canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = const Color(0xFF24D6FF).withOpacity(0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
