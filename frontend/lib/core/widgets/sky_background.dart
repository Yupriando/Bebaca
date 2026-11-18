import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Latar ala banner Bebaca: langit biru bergradasi, awan putih lembut,
/// bintang kecil, dan (opsional) bukit hijau di bawah.
class SkyBackground extends StatelessWidget {
  final Widget child;
  final bool hills;
  final bool stars;
  const SkyBackground({super.key, required this.child, this.hills = false, this.stars = true});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.skyTop, Color(0xFFB8E2FF), AppColors.skyBottom],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _SkyPainter(hills: hills, stars: stars))),
          ),
          child,
        ],
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final bool hills;
  final bool stars;
  _SkyPainter({required this.hills, required this.stars});

  void _cloud(Canvas c, Offset o, double s, double opacity) {
    final p = Paint()..color = Colors.white.withAlpha((255 * opacity).round());
    c.drawCircle(o.translate(-0.55 * s, 0.1 * s), 0.38 * s, p);
    c.drawCircle(o, 0.5 * s, p);
    c.drawCircle(o.translate(0.55 * s, 0.12 * s), 0.36 * s, p);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 0.95 * s, o.dy + 0.05 * s, 1.9 * s, 0.42 * s), Radius.circular(0.21 * s)),
      p,
    );
  }

  void _star(Canvas c, Offset o, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final pt = o + Offset(cos(a) * rad, sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, Paint()..color = AppColors.sun);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = min(w, h);
    _cloud(canvas, Offset(w * 0.08, h * 0.12), s * 0.10, 0.9);
    _cloud(canvas, Offset(w * 0.86, h * 0.08), s * 0.13, 0.85);
    _cloud(canvas, Offset(w * 0.55, h * 0.04), s * 0.07, 0.6);
    _cloud(canvas, Offset(w * 0.95, h * 0.62), s * 0.09, 0.55);
    _cloud(canvas, Offset(w * 0.03, h * 0.78), s * 0.11, 0.6);
    if (stars) {
      _star(canvas, Offset(w * 0.30, h * 0.10), s * 0.022);
      _star(canvas, Offset(w * 0.72, h * 0.20), s * 0.016);
      _star(canvas, Offset(w * 0.93, h * 0.32), s * 0.012);
    }
    if (hills) {
      final back = Path()
        ..moveTo(0, h * 0.86)
        ..quadraticBezierTo(w * 0.25, h * 0.74, w * 0.5, h * 0.84)
        ..quadraticBezierTo(w * 0.78, h * 0.94, w, h * 0.80)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(back, Paint()..color = AppColors.grass.withAlpha(170));
      final front = Path()
        ..moveTo(0, h * 0.93)
        ..quadraticBezierTo(w * 0.35, h * 0.84, w * 0.62, h * 0.93)
        ..quadraticBezierTo(w * 0.85, h * 0.99, w, h * 0.90)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(front, Paint()..color = AppColors.grassDark.withAlpha(200));
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.hills != hills || old.stars != stars;
}

/// Kartu putih membulat dengan bayangan lembut (dipakai di atas latar langit).
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(color: Color(0x1A1C5FC7), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: child,
      );
}
