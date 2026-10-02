import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cartoon kid-face portraits used instead of letter initials.
class KidFacePainter extends CustomPainter {
  KidFacePainter(this.seed);

  final int seed;

  static const List<_KidLook> _looks = <_KidLook>[
    _KidLook(
      skin: Color(0xFFF8C9A0),
      hair: Color(0xFF4A2E1A),
      shirt: Color(0xFF5B9BFF),
      style: _HairStyle.short,
    ),
    _KidLook(
      skin: Color(0xFFE8B089),
      hair: Color(0xFF6B3A1F),
      shirt: Color(0xFF2ECF9A),
      style: _HairStyle.long,
    ),
    _KidLook(
      skin: Color(0xFFF3D0B0),
      hair: Color(0xFF2B2118),
      shirt: Color(0xFF7B6EFF),
      style: _HairStyle.beanie,
    ),
    _KidLook(
      skin: Color(0xFFD9A074),
      hair: Color(0xFF1C1410),
      shirt: Color(0xFFF5C044),
      style: _HairStyle.curly,
    ),
    _KidLook(
      skin: Color(0xFFF6D7B8),
      hair: Color(0xFFC48A2A),
      shirt: Color(0xFFE0565B),
      style: _HairStyle.pigtails,
    ),
    _KidLook(
      skin: Color(0xFFE4B48A),
      hair: Color(0xFF3A2416),
      shirt: Color(0xFF4B8BFF),
      style: _HairStyle.cap,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final _KidLook look = _looks[seed.abs() % _looks.length];
    final double w = size.width;
    final double h = size.height;
    final Offset c = Offset(w / 2, h * 0.48);

    canvas.drawRect(Offset.zero & size, Paint()..color = look.shirt);

    _drawHairBack(canvas, size, look);
    _drawNeck(canvas, size, look);
    _drawFace(canvas, size, c, look);
    _drawHairFront(canvas, size, look);
    _drawFeatures(canvas, size, c);
    _drawAccessory(canvas, size, look);
  }

  void _drawNeck(Canvas canvas, Size size, _KidLook look) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, h * 0.78),
          width: w * 0.22,
          height: h * 0.18,
        ),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = look.skin,
    );
  }

  void _drawFace(Canvas canvas, Size size, Offset c, _KidLook look) {
    final double w = size.width;
    canvas.drawOval(
      Rect.fromCenter(center: c, width: w * 0.72, height: w * 0.78),
      Paint()..color = look.skin,
    );
    canvas.drawCircle(
      Offset(c.dx - w * 0.36, c.dy + w * 0.02),
      w * 0.08,
      Paint()..color = look.skin,
    );
    canvas.drawCircle(
      Offset(c.dx + w * 0.36, c.dy + w * 0.02),
      w * 0.08,
      Paint()..color = look.skin,
    );
  }

  void _drawHairBack(Canvas canvas, Size size, _KidLook look) {
    final double w = size.width;
    final double h = size.height;
    final Paint hair = Paint()..color = look.hair;
    switch (look.style) {
      case _HairStyle.long:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.84, h * 0.72),
            Radius.circular(w * 0.42),
          ),
          hair,
        );
      case _HairStyle.pigtails:
        canvas.drawCircle(Offset(w * 0.12, h * 0.42), w * 0.16, hair);
        canvas.drawCircle(Offset(w * 0.88, h * 0.42), w * 0.16, hair);
      case _HairStyle.curly:
        for (final double x in <double>[0.18, 0.38, 0.62, 0.82]) {
          canvas.drawCircle(Offset(w * x, h * 0.22), w * 0.16, hair);
        }
      case _HairStyle.short:
      case _HairStyle.beanie:
      case _HairStyle.cap:
        break;
    }
  }

  void _drawHairFront(Canvas canvas, Size size, _KidLook look) {
    final double w = size.width;
    final double h = size.height;
    final Paint hair = Paint()..color = look.hair;
    final Path bangs = Path()
      ..moveTo(w * 0.16, h * 0.32)
      ..quadraticBezierTo(w * 0.50, h * 0.02, w * 0.84, h * 0.32)
      ..quadraticBezierTo(w * 0.50, h * 0.22, w * 0.16, h * 0.32);
    switch (look.style) {
      case _HairStyle.short:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w / 2, h * 0.28),
            width: w * 0.78,
            height: w * 0.42,
          ),
          hair,
        );
        canvas.drawPath(bangs, hair);
      case _HairStyle.long:
      case _HairStyle.pigtails:
      case _HairStyle.curly:
        canvas.drawPath(bangs, hair);
      case _HairStyle.beanie:
      case _HairStyle.cap:
        canvas.drawPath(bangs, hair);
    }
  }

  void _drawFeatures(Canvas canvas, Size size, Offset c) {
    final double w = size.width;
    void eye(double dx) {
      final Offset p = Offset(c.dx + dx, c.dy + w * 0.02);
      canvas.drawOval(
        Rect.fromCenter(center: p, width: w * 0.16, height: w * 0.18),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(p, w * 0.055, Paint()..color = const Color(0xFF2A1A12));
      canvas.drawCircle(
        Offset(p.dx - w * 0.02, p.dy - w * 0.02),
        w * 0.018,
        Paint()..color = Colors.white,
      );
    }

    eye(-w * 0.13);
    eye(w * 0.13);

    canvas.drawCircle(
      Offset(c.dx - w * 0.22, c.dy + w * 0.14),
      w * 0.055,
      Paint()..color = const Color(0x33E56B6B),
    );
    canvas.drawCircle(
      Offset(c.dx + w * 0.22, c.dy + w * 0.14),
      w * 0.055,
      Paint()..color = const Color(0x33E56B6B),
    );

    final Paint smile = Paint()
      ..color = const Color(0xFFC45C5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, w * 0.035)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + w * 0.16),
        width: w * 0.22,
        height: w * 0.14,
      ),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      smile,
    );
  }

  void _drawAccessory(Canvas canvas, Size size, _KidLook look) {
    final double w = size.width;
    final double h = size.height;
    if (look.style == _HairStyle.beanie) {
      final Path hat = Path()
        ..moveTo(w * 0.10, h * 0.32)
        ..quadraticBezierTo(w * 0.50, h * -0.08, w * 0.90, h * 0.32)
        ..lineTo(w * 0.90, h * 0.38)
        ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.10, h * 0.38)
        ..close();
      canvas.drawPath(hat, Paint()..color = const Color(0xFF4B8BFF));
      canvas.drawCircle(
        Offset(w * 0.50, h * 0.06),
        w * 0.08,
        Paint()..color = const Color(0xFFFFE0C2),
      );
    }
    if (look.style == _HairStyle.cap) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, h * 0.20),
          width: w * 0.78,
          height: w * 0.36,
        ),
        Paint()..color = const Color(0xFF1E4F9A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.84, h * 0.08),
          Radius.circular(w * 0.04),
        ),
        Paint()..color = const Color(0xFF163A74),
      );
    }
  }

  @override
  bool shouldRepaint(covariant KidFacePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

enum _HairStyle { short, long, beanie, curly, pigtails, cap }

class _KidLook {
  const _KidLook({
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.style,
  });

  final Color skin;
  final Color hair;
  final Color shirt;
  final _HairStyle style;
}
