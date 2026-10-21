import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kotak huruf kayu (sesuai desain).
class WoodTile extends StatelessWidget {
  final String letter;
  final double size;
  final double rotation; // radian
  final Color? outline;
  final Widget? badge;
  final VoidCallback? onTap;

  const WoodTile({
    super.key,
    required this.letter,
    this.size = 96,
    this.rotation = 0,
    this.outline,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDC8F42), Color(0xFFB4601D)],
            ),
            border: Border.all(
              color: outline ?? const Color(0xFF8A4A14),
              width: outline != null ? 5 : 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _GrainPainter())),
              Center(
                child: Text(
                  letter,
                  style: GoogleFonts.itim(
                    fontSize: size * 0.62,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              if (badge != null) Positioned(right: 6, bottom: 6, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Serat kayu: garis bergelombang tipis.
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.018;
    for (var i = 1; i <= 6; i++) {
      final y = size.height * i / 7;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.25, y - size.height * 0.04,
            size.width * 0.5, y)
        ..quadraticBezierTo(size.width * 0.75, y + size.height * 0.04,
            size.width, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
