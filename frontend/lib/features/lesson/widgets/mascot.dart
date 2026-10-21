import 'dart:math';
import 'package:flutter/material.dart';

enum MascotMood { idle, cheer, sad }

/// Maskot bulat kuning yang ikut bereaksi saat anak menjawab:
/// benar -> melompat gembira, salah -> bergeleng sedih. Menyala-redup saat diam.
class Mascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final bool animate;
  const Mascot({
    super.key,
    required this.mood,
    this.size = 44,
    this.animate = true,
  });

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _idle.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Mascot old) {
    super.didUpdateWidget(old);
    if (widget.animate != old.animate) {
      widget.animate ? _idle.repeat(reverse: true) : _idle.stop();
    }
    if (widget.animate &&
        widget.mood != old.mood &&
        widget.mood != MascotMood.idle) {
      _react.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _react]),
      builder: (context, _) {
        var dx = 0.0;
        var dy = widget.animate ? -sin(_idle.value * pi) * 3 : 0.0;
        var scale = 1.0;
        final t = _react.value;
        if (widget.animate && _react.isAnimating) {
          if (widget.mood == MascotMood.cheer) {
            dy -= sin(t * pi) * widget.size * 0.35; // lompat
            scale = 1 + 0.15 * sin(t * pi);
          } else if (widget.mood == MascotMood.sad) {
            dx = sin(t * pi * 5) * 4 * (1 - t); // menggeleng
          }
        }
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _MascotPainter(widget.mood),
            ),
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  _MascotPainter(this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final r = s * 0.44;
    // gaya sama dengan matahari di logo Bebaca: garis tepi gelap tebal,
    // kuning-oranye mengilap, pipi merah, mata berbulu mata.
    const ink = Color(0xFF1B1530);

    // bayangan
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s / 2, s * 0.97), width: s * 0.6, height: s * 0.08),
      Paint()..color = const Color(0x22000000),
    );

    // badan
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.2, -0.5),
          radius: 1.0,
          colors: [Color(0xFFFFD54A), Color(0xFFFFB81C), Color(0xFFF59A0C)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.055
        ..color = ink,
    );

    // kilau putih di kanan atas
    canvas.save();
    canvas.translate(s * 0.66, s * 0.24);
    canvas.rotate(0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.17, height: s * 0.08),
      Paint()..color = const Color(0xCCFFFFFF),
    );
    canvas.restore();
    canvas.drawCircle(Offset(s * 0.79, s * 0.36), s * 0.025,
        Paint()..color = const Color(0xAAFFFFFF));

    // pipi
    final blush = Paint()..color = const Color(0xCCF25C5C);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(s * 0.25, s * 0.62), width: s * 0.17, height: s * 0.13),
        blush);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(s * 0.75, s * 0.62), width: s * 0.17, height: s * 0.13),
        blush);

    // mata
    if (mood == MascotMood.cheer) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..strokeCap = StrokeCap.round
        ..color = ink;
      for (final x in [0.35, 0.65]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(s * x, s * 0.46), width: s * 0.16, height: s * 0.16),
          pi, pi, false, arc,
        );
      }
    } else {
      final lash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..strokeCap = StrokeCap.round
        ..color = ink;
      for (final x in [0.36, 0.64]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(s * x, s * 0.45), width: s * 0.12, height: s * 0.14),
          Paint()..color = ink,
        );
        canvas.drawCircle(
          Offset(s * x + s * 0.02, s * 0.42),
          s * 0.022,
          Paint()..color = Colors.white,
        );
        // bulu mata di sisi luar
        final out = x < 0.5 ? -1.0 : 1.0;
        final ex = s * x + out * s * 0.05;
        canvas.drawLine(Offset(ex, s * 0.41),
            Offset(ex + out * s * 0.05, s * 0.37), lash);
        canvas.drawLine(Offset(ex - out * s * 0.01, s * 0.385),
            Offset(ex + out * s * 0.025, s * 0.335), lash);
      }
    }

    // mulut
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round
      ..color = ink;
    switch (mood) {
      case MascotMood.idle:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(s / 2, s * 0.58), width: s * 0.24, height: s * 0.16),
          0.2, pi - 0.4, false, mouth,
        );
      case MascotMood.cheer:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(s / 2, s * 0.58), width: s * 0.28, height: s * 0.24),
          0, pi, true, Paint()..color = const Color(0xFF7A2E1F),
        );
      case MascotMood.sad:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(s / 2, s * 0.7), width: s * 0.22, height: s * 0.14),
          pi + 0.3, pi - 0.6, false, mouth,
        );
        // air mata
        canvas.drawOval(
          Rect.fromCenter(center: Offset(s * 0.69, s * 0.56), width: s * 0.05, height: s * 0.08),
          Paint()..color = const Color(0xFF7CC6F2),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) => old.mood != mood;
}
