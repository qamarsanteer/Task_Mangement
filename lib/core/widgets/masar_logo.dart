import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Masar's brand mark: a flowing route drawn inside a rounded gradient tile.
///
/// The glyph is now an "M" shaped path — a direct visual link to the app's
/// name "Masar" / "مسار". It starts at the bottom-left leg (the starting
/// point) and ends at the bottom-right leg (the destination).
class MasarLogo extends StatelessWidget {
  final double size;
  final double progress;
  final double markerProgress;

  const MasarLogo({
    super.key,
    this.size = 140,
    this.progress = 1.0,
    double? markerProgress,
  }) : markerProgress = markerProgress ?? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.11),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _MasarRoutePainter(
          progress: progress.clamp(0.0, 1.0),
          markerProgress: markerProgress.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _MasarRoutePainter extends CustomPainter {
  final double progress;
  final double markerProgress;

  _MasarRoutePainter({required this.progress, required this.markerProgress});

  // Start at bottom-left leg of the M
  static const Offset _start = Offset(20, 80);
  // End at bottom-right leg of the M
  static const Offset _end = Offset(80, 80);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    Offset p(double x, double y) => Offset(x * s, y * s);

    // Build the M-shaped path
    final route = Path()
      ..moveTo(p(_start.dx, _start.dy).dx, p(_start.dx, _start.dy).dy)
      // Left leg: straight up
      ..lineTo(p(20, 22).dx, p(20, 22).dy)
      // Left shoulder: curve down to the valley
      ..cubicTo(
        p(20, 22).dx, p(20, 22).dy,
        p(35, 22).dx, p(35, 22).dy,
        p(50, 55).dx, p(50, 55).dy,
      )
      // Right shoulder: curve up from the valley
      ..cubicTo(
        p(65, 22).dx, p(65, 22).dy,
        p(80, 22).dx, p(80, 22).dy,
        p(80, 22).dx, p(80, 22).dy,
      )
      // Right leg: straight down
      ..lineTo(p(_end.dx, _end.dy).dx, p(_end.dx, _end.dy).dy);

    // Animate the stroke drawing
    Path drawnRoute = route;
    if (progress < 1) {
      final metrics = route.computeMetrics().toList();
      drawnRoute = Path();
      for (final metric in metrics) {
        drawnRoute.addPath(
          metric.extractPath(0, metric.length * progress),
          Offset.zero,
        );
      }
    }

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(drawnRoute, linePaint);

    // Starting dot at bottom-left of the M
    final startPaint = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawCircle(p(_start.dx, _start.dy), s * 4.2 * progress, startPaint);

    // Destination marker at bottom-right of the M
    if (markerProgress > 0) {
      final center = p(_end.dx, _end.dy);
      final ringPaint = Paint()
        ..color = Colors.white.withOpacity(0.35 * markerProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 2.5;
      canvas.drawCircle(center, s * 10 * markerProgress, ringPaint);

      final corePaint = Paint()..color = Colors.white.withOpacity(markerProgress);
      canvas.drawCircle(center, s * 6.5 * markerProgress, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MasarRoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.markerProgress != markerProgress;
  }
}