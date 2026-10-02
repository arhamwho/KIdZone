import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'feature_tile.dart';

/// Concentric radar used on the parent Location screen — no map tiles.
class LocationRadar extends StatefulWidget {
  const LocationRadar({
    super.key,
    required this.name,
    required this.hasFix,
    required this.live,
    this.accuracyMeters,
  });

  final String name;
  final bool hasFix;
  final bool live;
  final double? accuracyMeters;

  @override
  State<LocationRadar> createState() => _LocationRadarState();
}

class _LocationRadarState extends State<LocationRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live && widget.hasFix) {
      _pulse.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LocationRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool shouldPulse = widget.live && widget.hasFix;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              painter: _RadarPainter(
                progress: widget.live && widget.hasFix ? _pulse.value : 0,
                hasFix: widget.hasFix,
                accuracy: widget.accuracyMeters,
              ),
              child: Center(
                child: widget.hasFix
                    ? PersonAvatar(name: widget.name, size: 64)
                    : Icon(
                        Icons.location_searching_rounded,
                        size: 36,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.progress,
    required this.hasFix,
    required this.accuracy,
  });

  final double progress;
  final bool hasFix;
  final double? accuracy;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2 - 8;

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.primary.withValues(alpha: 0.18);

    for (final double t in <double>[0.38, 0.62, 0.86]) {
      canvas.drawCircle(center, radius * t, ring);
    }

    final Paint fill = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppColors.primary.withValues(alpha: hasFix ? 0.16 : 0.06),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, fill);

    if (hasFix && accuracy != null && accuracy! > 0) {
      final double accT = (accuracy!.clamp(8, 80) / 80);
      canvas.drawCircle(
        center,
        radius * (0.28 + accT * 0.42),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.tileGreen.withValues(alpha: 0.45),
      );
    }

    if (progress > 0) {
      canvas.drawCircle(
        center,
        radius * (0.2 + progress * 0.7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.primary.withValues(alpha: (1 - progress) * 0.45),
      );
    }

    final Paint tick = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.28)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final double a = i * math.pi / 6;
      final Offset a1 = Offset(
        center.dx + math.cos(a) * radius * 0.92,
        center.dy + math.sin(a) * radius * 0.92,
      );
      final Offset a2 = Offset(
        center.dx + math.cos(a) * radius,
        center.dy + math.sin(a) * radius,
      );
      canvas.drawLine(a1, a2, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hasFix != hasFix ||
        oldDelegate.accuracy != accuracy;
  }
}
