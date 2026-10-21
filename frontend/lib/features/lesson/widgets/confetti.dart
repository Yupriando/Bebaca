import 'dart:math';
import 'package:flutter/material.dart';

class _Piece {
  final double x, delay, speed, size, phase, spin;
  final Color color;
  const _Piece(this.x, this.delay, this.speed, this.size, this.phase, this.spin, this.color);
}

/// Confetti jatuh sekali (±3 detik). Dipakai di halaman hasil lesson.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    const colors = [
      Color(0xFFFFB300),
      Color(0xFF50A5DB),
      Color(0xFFE74C3C),
      Color(0xFF2ECC71),
      Color(0xFF9B59B6),
    ];
    final r = Random();
    _pieces = List.generate(
      48,
      (_) => _Piece(
        r.nextDouble(),
        r.nextDouble() * 0.4,
        0.7 + r.nextDouble() * 0.6,
        8 + r.nextDouble() * 8,
        r.nextDouble() * 6.28,
        4 + r.nextDouble() * 6,
        colors[r.nextInt(colors.length)],
      ),
    );
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
        painter: _ConfettiPainter(_pieces, _c.value),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double progress;
  _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final y = -20 + t * (size.height + 40) * p.speed;
      final x = p.x * size.width + sin(t * 6 + p.phase) * 24;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.phase + t * p.spin);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
