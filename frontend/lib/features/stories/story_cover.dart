import 'package:flutter/material.dart';

/// Gambar sampul / ilustrasi dongeng: URL (http...), path asset, atau
/// kotak pastel berisi judul kalau gambar belum ada.
class StoryCover extends StatelessWidget {
  final String? url;
  final String title;
  final String seed; // menentukan warna pastel (mis. id dongeng)
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

  static const pastels = [
    Color(0xFFFFE0B2),
    Color(0xFFC8E6C9),
    Color(0xFFBBDEFB),
    Color(0xFFF8BBD0),
    Color(0xFFD1C4E9),
  ];

  static Color pastelFor(String seed) => pastels[seed.hashCode.abs() % pastels.length];

  Widget _placeholder() {
    final color = pastelFor(seed);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.55)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: showTitle
          ? Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.black87),
            )
          : Icon(Icons.auto_stories_rounded,
              size: 96, color: Colors.black.withAlpha(40)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder();
    return u.startsWith('http')
        ? Image.network(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
        : Image.asset(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
  }
}
