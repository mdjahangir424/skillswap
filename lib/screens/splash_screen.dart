
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061442),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BackgroundPainter(_animation.value),
                  );
                },
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      const Spacer(flex: 3),

                      // SkillSwap S Logo
                      SizedBox(
                        height: constraints.maxHeight * 0.19,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFF00DFFF),
                                    Color(0xFF537BFF),
                                    Color(0xFFB34AFF),
                                  ],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'S',
                                style: TextStyle(
                                  fontSize: 145,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            Transform.rotate(
                              angle: -0.35,
                              child: Container(
                                width: 150,
                                height: 45,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF49DFFF),
                                    width: 3,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF16CFFF)
                                          .withOpacity(0.5),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Brand Name
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.8,
                          ),
                          children: [
                            TextSpan(
                              text: 'Skill',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Swap',
                              style: TextStyle(
                                color: Color(0xFFAB7AFF),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Learn. Teach. Exchange.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'A World of Skills,\nOne Community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFDCEAFF),
                          fontSize: 18,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Animated Global Network
                      Expanded(
                        flex: 5,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: GlobePainter(
                                _animation.value,
                              ),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),

                      const Spacer(),

                      // Loading Indicator
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animation.value * math.pi * 2,
                            child: const SizedBox(
                              width: 46,
                              height: 46,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Color(0xFF35D9FF),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Preparing your experience...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Background: gradient atmosphere, stars and blue-purple waves
class BackgroundPainter extends CustomPainter {
  final double animation;

  BackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(24);

    // Background glow
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF102F83),
          Color(0xFF071A50),
          Color(0xFF040D35),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Offset.zero & size,
      glow,
    );

    // Stars
    final starPaint = Paint()
      ..color = const Color(0xFF3EDCFF);

    for (int i = 0; i < 55; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final pulse = 1 +
          math.sin(animation * math.pi * 2 + i) * 0.5;

      canvas.drawCircle(
        Offset(x, y),
        1.2 * pulse,
        starPaint,
      );
    }

    // Top blue wave
    final topWave = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .42, 0)
      ..cubicTo(
        size.width * .28,
        size.height * .09,
        size.width * .12,
        size.height * .10,
        0,
        size.height * .16,
      )
      ..close();

    canvas.drawPath(
      topWave,
      Paint()..color = const Color(0xFF0755C5).withOpacity(.5),
    );

    // Bottom waves
    final bottomWave = Path()
      ..moveTo(0, size.height * .91)
      ..cubicTo(
        size.width * .28,
        size.height * .87,
        size.width * .48,
        size.height * .99,
        size.width,
        size.height * .89,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      bottomWave,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF006BDF),
            Color(0xFF172C94),
            Color(0xFF7D19D9),
          ],
        ).createShader(
          Rect.fromLTWH(
            0,
            size.height * .87,
            size.width,
            size.height * .13,
          ),
        ),
    );

    final waveLine = Paint()
      ..color = const Color(0xFF36CFFF).withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .92)
        ..cubicTo(
          size.width * .30,
          size.height * .85,
          size.width * .55,
          size.height * .99,
          size.width,
          size.height * .90,
        ),
      waveLine,
    );
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// Globe and connected community avatars
class GlobePainter extends CustomPainter {
  final double animation;

  GlobePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height * .53,
    );

    final radius = math.min(
      size.width * .30,
      size.height * .39,
    );

    // Globe glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00CFFF).withOpacity(.35),
          const Color(0xFF007BFF).withOpacity(.12),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius * 1.6,
        ),
      );

    canvas.drawCircle(
      center,
      radius * 1.6,
      glowPaint,
    );

    // Globe outline
    final globePaint = Paint()
      ..color = const Color(0xFF48DFFF).withOpacity(.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, globePaint);

    // Longitude
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * .85,
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

    // Latitude
    for (final factor in [.55, 1.0, 1.45]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * factor,
        ),
        globePaint,
      );
    }

    // Globe network connections
    final nodes = [
      Offset(center.dx - radius * .75, center.dy - radius * .55),
      Offset(center.dx + radius * .75, center.dy - radius * .55),
      Offset(center.dx - radius * .95, center.dy + radius * .45),
      Offset(center.dx + radius * .95, center.dy + radius * .45),
      Offset(center.dx, center.dy + radius * .95),
    ];

    final connectionPaint = Paint()
      ..color = const Color(0xFF36DFFF).withOpacity(.8)
      ..strokeWidth = 1.7;

    for (final point in nodes) {
      canvas.drawLine(center, point, connectionPaint);

      canvas.drawCircle(
        point,
        5 + math.sin(animation * math.pi * 2) * 1.5,
        Paint()..color = const Color(0xFF4AE7FF),
      );
    }

    // Orbital network paths
    final orbitPaint = Paint()
      ..color = const Color(0xFF22DFFF).withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation * math.pi * 2 * .15);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 3.1,
        height: radius * 1.1,
      ),
      orbitPaint,
    );

    canvas.restore();

    // Four avatar bubbles
    final avatars = [
      (
        Offset(center.dx - radius * 1.05, center.dy - radius * .85),
        'J',
        Color(0xFF48BFFF),
      ),
      (
        Offset(center.dx + radius * 1.05, center.dy - radius * .85),
        'A',
        Color(0xFFB66BFF),
      ),
      (
        Offset(center.dx - radius * 1.12, center.dy + radius * .85),
        'S',
        Color(0xFFFFC44E),
      ),
      (
        Offset(center.dx + radius * 1.12, center.dy + radius * .85),
        'M',
        Color(0xFF42DDAA),
      ),
    ];

    for (final avatar in avatars) {
      final point = avatar.$1;
      final letter = avatar.$2;
      final color = avatar.$3;

      canvas.drawCircle(
        point,
        29,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        point,
        25,
        Paint()..color = color,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          point.dy - textPainter.height / 2,
        ),
      );
    }

    // Globe center light
    canvas.drawCircle(
      center,
      5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) =>
      oldDelegate.animation != animation;
}
