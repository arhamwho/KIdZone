import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// KidZone mascot: an orange egg character with a focused look, plus the
/// wordmark underneath — the same composition as a home-screen icon.
class KidZoneMark extends StatelessWidget {
  const KidZoneMark({super.key, this.size = 160, this.showWordmark = true});

  final double size;

  /// When false, only the character is drawn (for headers that already say
  /// KidZone in type).
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final double radius = size * 0.22;
    final double wordSize = (size * 0.13).clamp(12.0, 22.0);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE4E4E4),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            size * 0.08,
            size * 0.06,
            size * 0.08,
            showWordmark ? size * 0.06 : size * 0.08,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: CustomPaint(
                  painter: const KidZoneMascotPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
              if (showWordmark) ...<Widget>[
                SizedBox(height: size * 0.02),
                Text(
                  'KidZone',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: AppColors.parentAccent,
                    fontSize: wordSize,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The egg character without the tile or wordmark.
class KidZoneMascotPainter extends CustomPainter {
  const KidZoneMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    final Path egg = Path()
      ..moveTo(cx, h * 0.02)
      ..cubicTo(
        cx + w * 0.18,
        h * 0.06,
        cx + w * 0.46,
        h * 0.36,
        cx + w * 0.40,
        h * 0.70,
      )
      ..cubicTo(
        cx + w * 0.36,
        h * 1.02,
        cx - w * 0.36,
        h * 1.02,
        cx - w * 0.40,
        h * 0.70,
      )
      ..cubicTo(cx - w * 0.46, h * 0.36, cx - w * 0.18, h * 0.06, cx, h * 0.02)
      ..close();

    canvas.drawPath(egg, Paint()..color = AppColors.primary);

    final double eyeY = h * 0.42;
    final double eyeDx = w * 0.16;
    final double eyeRx = w * 0.155;
    final double eyeRy = h * 0.168;

    void eye(double x) {
      final Offset center = Offset(x, eyeY);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: eyeRx * 2, height: eyeRy * 2),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        center,
        eyeRx * 0.72,
        Paint()..color = const Color(0xFF8A8A8A),
      );
      canvas.drawCircle(
        center,
        eyeRx * 0.48,
        Paint()..color = const Color(0xFF222222),
      );
      canvas.drawCircle(
        Offset(x - eyeRx * 0.22, eyeY - eyeRy * 0.22),
        eyeRx * 0.14,
        Paint()..color = Colors.white,
      );
    }

    eye(cx - eyeDx);
    eye(cx + eyeDx);

    final Paint brow = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = (w * 0.058).clamp(3.0, 9.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path leftBrow = Path()
      ..moveTo(cx - w * 0.36, eyeY - h * 0.20)
      ..quadraticBezierTo(
        cx - w * 0.22,
        eyeY - h * 0.28,
        cx - w * 0.05,
        eyeY - h * 0.13,
      );
    final Path rightBrow = Path()
      ..moveTo(cx + w * 0.36, eyeY - h * 0.20)
      ..quadraticBezierTo(
        cx + w * 0.22,
        eyeY - h * 0.28,
        cx + w * 0.05,
        eyeY - h * 0.13,
      );
    canvas.drawPath(leftBrow, brow);
    canvas.drawPath(rightBrow, brow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
