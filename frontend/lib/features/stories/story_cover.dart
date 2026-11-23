import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Gambar sampul / ilustrasi dongeng: URL (http...), path asset, atau
/// sampul polos bergaya buku (warna lembut + judul) kalau gambar belum ada.
class StoryCover extends StatelessWidget {
  final String? url;
  final String title;
  final String seed; // menentukan warna (mis. id dongeng)
  final double titleSize;
  final bool showTitle;

  const StoryCover({
    super.key,
    required this.url,
    required this.title,
    required this.seed,
    this.titleSize = 20,
    this.showTitle = true,
  });

  /// (warna latar, warna aksen) per sampul.
  static const palettes = [
    (Color(0xFFFFE3C2), Color(0xFFE8892B)),
    (Color(0xFFD6F0D9), Color(0xFF3E9B57)),
    (Color(0xFFD7E8FD), Color(0xFF2F7BEA)),
    (Color(0xFFFADCE6), Color(0xFFD24D7A)),
    (Color(0xFFE5DDF7), Color(0xFF7B61FF)),
    (Color(0xFFFFF0C2), Color(0xFFC99700)),
  ];

  /// Hash stabil (String.hashCode bisa berbeda antara web dan HP).
  static int _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  static (Color, Color) paletteFor(String seed) => palettes[_hash(seed) % palettes.length];
  static Color pastelFor(String seed) => paletteFor(seed).$1;

  Widget _placeholder() {
    final (bg, accent) = paletteFor(seed);
    return LayoutBuilder(builder: (context, c) {
      final s = c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 200.0;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bg, Color.lerp(bg, Colors.white, 0.6)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // lingkaran lembut sebagai hiasan sampul
            Positioned(
              right: -s * 0.18,
              top: -s * 0.2,
              child: _circle(s * 0.7, Colors.white.withAlpha(110)),
            ),
            Positioned(
              left: -s * 0.15,
              bottom: -s * 0.25,
              child: _circle(s * 0.6, accent.withAlpha(28)),
            ),
            // "punggung buku" di sisi kiri
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: s * 0.05, color: accent.withAlpha(60)),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(s * 0.1, s * 0.06, s * 0.06, s * 0.06),
                child: showTitle
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: titleSize * 1.5, color: accent),
                          SizedBox(height: titleSize * 0.35),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fredoka(
                              fontSize: titleSize,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      )
                    : Icon(Icons.auto_stories_rounded, size: s * 0.35, color: accent.withAlpha(120)),
              ),
            ),
          ],
        ),
      );
    });
  }

  static Widget _circle(double d, Color color) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder();
    return u.startsWith('http')
        ? Image.network(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
        : Image.asset(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
  }
}
