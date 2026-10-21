import 'dart:math';
import 'package:flutter/material.dart';

/// Bentuk bintang kecil 4 sudut (berlian melengkung).
Path sparklePath(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy - r)
  ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
  ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
  ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
  ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
  ..close();

/// Ledakan bintang kecil sekali putar (±0,8 detik). Letakkan di Stack di atas
/// widget yang dirayakan (pakai Positioned.fill + IgnorePointer).
class SparkleBurst extends StatefulWidget {
  final double radius;
  final int count;
  const SparkleBurst({super.key, this.radius = 70, this.count = 12});

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  late final List<double> _jitter;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _jitter = List.generate(widget.count, (_) => r.nextDouble());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _BurstPainter(_c.value, widget.radius, _jitter),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  final double radius;
  final List<double> jitter;
  _BurstPainter(this.t, this.radius, this.jitter);

  static const _colors = [
    Color(0xFFFFC83D),
    Color(0xFFFFFFFF),
    Color(0xFF7CC6F2),
    Color(0xFFFF8FB1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(t);
    final n = jitter.length;

    for (var i = 0; i < n; i++) {
      final angle = (i / n) * 2 * pi + jitter[i] * 0.5;
      final dist = radius * (0.55 + 0.45 * jitter[i]) * eased;
      final pos = center + Offset(cos(angle), sin(angle)) * dist;
      final r = (6 + 8 * jitter[i]) * (1 - t * 0.6);
      final alpha = ((1 - t) * 255).round().clamp(0, 255);
      canvas.drawPath(
        sparklePath(pos, r),
        Paint()..color = _colors[i % _colors.length].withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}

/// Membungkus widget: saat diketuk "membal" (mengecil lalu melenting).
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool animate;
  const BouncyTap({
    super.key,
    required this.child,
    required this.onTap,
    this.animate = true,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.15), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.animate) _c.forward(from: 0);
        widget.onTap();
      },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Melayang naik-turun pelan (idle animation).
class Bob extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final double phase; // 0..1, supaya beberapa widget tidak bergerak serempak
  final bool enabled;
  const Bob({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.phase = 0,
    this.enabled = true,
  });

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  // dibuat di initState (bukan lazy): kalau animasi mati, dispose() tidak boleh membuatnya
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.enabled) {
      _c.value = widget.phase;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, Curves.easeInOut.transform(_c.value) * -widget.amplitude),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Sinar matahari berputar pelan (latar halaman hasil).
class Sunburst extends StatefulWidget {
  final double size;
  const Sunburst({super.key, this.size = 340});

  @override
  State<Sunburst> createState() => _SunburstState();
}

class _SunburstState extends State<Sunburst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Transform.rotate(
        angle: _c.value * 2 * pi,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RaysPainter(),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x99FFC83D), Color(0x00FFC83D)],
      ).createShader(Rect.fromCircle(center: c, radius: radius));
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * pi / rays;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.1) * radius, c.dy + sin(a - 0.1) * radius)
        ..lineTo(c.dx + cos(a + 0.1) * radius, c.dy + sin(a + 0.1) * radius)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
