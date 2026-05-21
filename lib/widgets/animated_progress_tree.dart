import 'package:flutter/material.dart';
import 'dart:math' as math;


class AnimatedProgressTree extends StatefulWidget {
  final double progress; // 0.0 to 1.0

  const AnimatedProgressTree({super.key, required this.progress});

  @override
  State<AnimatedProgressTree> createState() => _AnimatedProgressTreeState();
}

class _AnimatedProgressTreeState extends State<AnimatedProgressTree>
    with TickerProviderStateMixin {
  late AnimationController _growthController;
  late AnimationController _ambientController;
  late Animation<double> _growthAnimation;
  final List<Firefly> _fireflies = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _growthController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(); // Loop forever for continuous ambient effects

    _generateFireflies();
    _updateAnimation();
    _growthController.forward();
  }

  void _generateFireflies() {
    for (int i = 0; i < 20; i++) {
      _fireflies.add(
        Firefly(
          xOffset: (_random.nextDouble() - 0.5) * 200,
          yOffset:
          (_random.nextDouble() - 0.5) * 200 -
              100, // Bias towards top/leaves
          speed: 0.5 + _random.nextDouble(),
          phase: _random.nextDouble() * math.pi * 2,
          size: 1.0 + _random.nextDouble() * 2.0,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _updateAnimation();
      _growthController.forward(from: 0);
    }
  }

  void _updateAnimation() {
    _growthAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _growthController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _growthController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_growthAnimation, _ambientController]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 300),
          painter: TreePainter(
            progress: _growthAnimation.value,
            ambientTime:
            _ambientController.value *
                math.pi *
                2, // 0 to 2PI over 5 seconds
            fireflies: _fireflies,
          ),
        );
      },
    );
  }
}

class Firefly {
  final double xOffset;
  final double yOffset;
  final double speed;
  final double phase;
  final double size;

  Firefly({
    required this.xOffset,
    required this.yOffset,
    required this.speed,
    required this.phase,
    required this.size,
  });
}

class TreePainter extends CustomPainter {
  final double progress;
  final double ambientTime;
  final List<Firefly> fireflies;

  TreePainter({
    required this.progress,
    required this.ambientTime,
    required this.fireflies,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startPoint = Offset(size.width / 2, size.height);

    // Base trunk length based on height
    final trunkLength = size.height * 0.3 * math.max(0.2, progress);

    // If progress is high (golden aura / productivity streak)
    if (progress > 0.8) {
      final auraPaint = Paint()
        ..color = Colors.amber.withOpacity(0.1 + math.sin(ambientTime) * 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        100,
        auraPaint,
      );
    }

    final paint = Paint()
      ..color = progress > 0.8 ? Colors.amber.shade700 : Color(0xFF6C63FF)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = (progress > 0.8 ? Colors.amber : Color(0xFF6C63FF)).withOpacity(
        0.3,
      )
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke;

    // Draw tree recursively
    _drawBranch(
      canvas,
      startPoint,
      -math.pi / 2,
      trunkLength,
      4,
      paint,
      glowPaint,
      progress,
    );

    // Draw Fireflies
    final fireflyPaint = Paint()..style = PaintingStyle.fill;

    for (var firefly in fireflies) {
      // Float around based on ambient time
      final dx =
          size.width / 2 +
              firefly.xOffset +
              math.sin(ambientTime * firefly.speed + firefly.phase) * 20;
      final dy =
          size.height / 2 +
              firefly.yOffset +
              math.cos(ambientTime * firefly.speed + firefly.phase) * 15;

      // Blink effect
      final opacity =
          (math.sin(ambientTime * firefly.speed * 2 + firefly.phase) + 1) / 2;

      fireflyPaint.color = Colors.yellowAccent.withOpacity(opacity * 0.8);
      fireflyPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, firefly.size);

      canvas.drawCircle(Offset(dx, dy), firefly.size, fireflyPaint);

      // Core dot
      fireflyPaint.color = Colors.white.withOpacity(opacity);
      fireflyPaint.maskFilter = null;
      canvas.drawCircle(Offset(dx, dy), firefly.size * 0.5, fireflyPaint);
    }
  }

  void _drawBranch(
      Canvas canvas,
      Offset start,
      double angle,
      double length,
      int depth,
      Paint paint,
      Paint glowPaint,
      double progressScale,
      ) {
    if (depth == 0 || length < 2.0 || progressScale <= 0) return;

    final end = Offset(
      start.dx + math.cos(angle) * length,
      start.dy + math.sin(angle) * length,
    );

    paint.strokeWidth = depth * 1.5;
    glowPaint.strokeWidth = depth * 3.0;

    canvas.drawLine(start, end, glowPaint);
    canvas.drawLine(start, end, paint);

    // Draw fire streak leaves at the tips if fully grown
    if (depth == 1 && progressScale > 0.8) {
      // Pulsating fire streak animation
      final pulsate = (math.sin(ambientTime * 3 + angle) + 1) / 2; // 0.0 to 1.0

      // Color shift between deep orange and bright yellow
      final leafColor =
          Color.lerp(Colors.deepOrangeAccent, Colors.yellowAccent, pulsate) ??
              Colors.orange;

      final leafPaint = Paint()
        ..color = leafColor.withOpacity(0.7 + (pulsate * 0.3))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + (pulsate * 3));

      // Draw fire leaf shape (elongated like a streak)
      canvas.save();
      canvas.translate(end.dx, end.dy);
      canvas.rotate(angle + math.pi / 2);

      final path = Path();
      final sizeMult = 2.5; // Scale factor for larger leaves
      path.moveTo(0, (-2 - (pulsate * 2)) * sizeMult);
      path.quadraticBezierTo(
        (3 + pulsate) * sizeMult,
        0,
        0,
        (8 + (pulsate * 4)) * sizeMult,
      );
      path.quadraticBezierTo(
        (-3 - pulsate) * sizeMult,
        0,
        0,
        (-2 - (pulsate * 2)) * sizeMult,
      );

      canvas.drawPath(path, leafPaint);

      // Core glow of the fire streak
      leafPaint.color = Colors.white.withOpacity(0.5);
      leafPaint.maskFilter = null;
      canvas.drawCircle(Offset.zero, 3.0, leafPaint);

      canvas.restore();
    } else if (depth == 1 && progressScale > 0.4) {
      // Normal green leaves before reaching high productivity
      final leafPaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(end, 10.0, leafPaint); // Increased from 3.0 to 8.0
    }

    // Branch out
    final nextLength = length * 0.7;
    final nextProgress = progressScale - 0.2;

    // Wind effect (sway branches slightly based on time)
    final windSway = math.sin(ambientTime + depth) * 0.05 * (5 - depth);

    if (nextProgress > 0) {
      _drawBranch(
        canvas,
        end,
        angle - math.pi / 6 + windSway,
        nextLength,
        depth - 1,
        paint,
        glowPaint,
        nextProgress,
      );
      _drawBranch(
        canvas,
        end,
        angle + math.pi / 6 + windSway,
        nextLength,
        depth - 1,
        paint,
        glowPaint,
        nextProgress,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TreePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ambientTime != ambientTime;
  }
}
