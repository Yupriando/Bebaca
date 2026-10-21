import 'dart:math';
import 'package:flutter/material.dart';

/// Membuat tampilan Bebaca pas di semua ukuran layar (HP s.d. tablet).
///
/// Bebaca dirancang untuk layar landscape setinggi minimal [designHeight] dp (tablet).
/// Di layar yang lebih pendek (mis. HP landscape ~360 dp), SELURUH tampilan diperkecil
/// secara proporsional: aplikasi "mengira" layarnya setinggi [designHeight], lalu hasilnya
/// dikecilkan agar muat. Jadi semua konten tetap terlihat utuh dengan susunan yang sama.
/// Di layar yang cukup tinggi (tablet), tidak ada yang berubah.
class AdaptiveScale extends StatelessWidget {
  final Widget child;
  const AdaptiveScale({super.key, required this.child});

  /// Tinggi layar (dp) yang dipakai saat merancang tampilan.
  static const designHeight = 560.0;

  /// Batas pengecilan, supaya teks tidak terlalu kecil di layar yang sangat pendek.
  static const minScale = 0.55;

  /// Ukuran huruf dari pengaturan HP dibatasi agar tata letak tidak rusak.
  static const maxTextScale = 1.15;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textScaler = mq.textScaler.clamp(maxScaleFactor: maxTextScale);
    final shortest = min(mq.size.width, mq.size.height);
    final scale = (shortest / designHeight).clamp(minScale, 1.0);

    if (scale >= 1.0) {
      return MediaQuery(data: mq.copyWith(textScaler: textScaler), child: child);
    }

    final logical = mq.size / scale;
    return MediaQuery(
      data: mq.copyWith(
        size: logical,
        devicePixelRatio: mq.devicePixelRatio * scale, // gambar tetap tajam
        padding: mq.padding / scale,
        viewPadding: mq.viewPadding / scale,
        viewInsets: mq.viewInsets / scale, // keyboard
        systemGestureInsets: mq.systemGestureInsets / scale,
        textScaler: textScaler,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(width: logical.width, height: logical.height, child: child),
      ),
    );
  }
}
