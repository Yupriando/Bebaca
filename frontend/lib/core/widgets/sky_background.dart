import 'dart:math';
import 'package:flutter/material.dart';

/// Gambar latar Bebaca (assets/latar/latar_<nama>.webp, 16:9).
enum Latar {
  utama(Color(0xFFA7D9EA)),
  masuk(Color(0xFFB2DEDB)),
  belajar(Color(0xFFC3E8F3)),
  dongeng(Color(0xFFE6D4CD)),
  pembuka(Color(0xFF0A215D)),
  terkunci(Color(0xFF2E4684));

  /// Warna rata-rata gambar, tampil sesaat selama gambar dimuat.
  final Color color;
  const Latar(this.color);

  String get asset => 'assets/latar/latar_$name.webp';

  /// Latar bergambar tanah menempel ke bawah (yang terpotong bagian langit);
  /// latar yang memusat (pembuka, terkunci) menempel di tengah.
  Alignment get alignment =>
      this == Latar.pembuka || this == Latar.terkunci ? Alignment.center : Alignment.bottomCenter;
}

/// Latar halaman: gambar latar menutupi layar, konten di atasnya.
class SkyBackground extends StatelessWidget {
  final Widget child;
  final Latar latar;
  const SkyBackground({super.key, required this.child, this.latar = Latar.utama});

  /// Latar di belakang sidebar dan semua tab. Selama lesson berjalan diganti ke
  /// [Latar.belajar], supaya latar di sekitar sidebar menyambung dengan latar lesson.
  static final shell = ValueNotifier<Latar>(Latar.utama);

  /// Muat latar yang sering dipakai lebih awal (dari layar pembuka) supaya tidak berkedip.
  static Future<void> precache(BuildContext context) => Future.wait([
        for (final l in const [Latar.utama, Latar.belajar, Latar.dongeng, Latar.masuk])
          precacheImage(AssetImage(l.asset), context),
      ]);

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: LatarImage(latar, key: ValueKey(latar)),
            ),
          ),
          child,
        ],
      );
}

/// Gambar latar yang ditempatkan seolah-olah menutupi layar penuh (BoxFit.cover), lalu
/// hanya bagian di bawah widget ini yang digambar. Widget dianggap menempel di kanan-bawah
/// layar (halaman penuh, atau area konten di kanan sidebar), jadi latar lesson menyambung
/// mulus dengan latar di sekitar sidebar.
class LatarImage extends StatelessWidget {
  final Latar latar;
  const LatarImage(this.latar, {super.key});

  static const _aspect = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth.isFinite ? box.maxWidth : screen.width;
      final h = box.maxHeight.isFinite ? box.maxHeight : screen.height;
      final drawnHeight = max(screen.width / _aspect, screen.height);
      final full = latar.alignment.inscribe(Size(drawnHeight * _aspect, drawnHeight), Offset.zero & screen);
      final rect = full.shift(Offset(w - screen.width, h - screen.height));
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: ColoredBox(color: latar.color)),
          Positioned.fromRect(
            rect: rect,
            child: Image.asset(
              latar.asset,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      );
    });
  }
}

/// Kartu putih membulat dengan bayangan lembut (dipakai di atas latar).
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
