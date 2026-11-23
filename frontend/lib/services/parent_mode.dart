import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode "Belajar bersama Ayah/Ibu":
///  - tiap soal menampilkan tips singkat cara mendampingi si kecil,
///  - orang tua bisa menilai bacaan anak (tombol "Sudah benar" / "Coba lagi"),
///    karena mikrofon sering gagal menangkap suara balita,
///  - di dongeng, halaman berisi pertanyaan ngobrol tidak langsung berganti otomatis.
/// Disimpan di perangkat saja (siapa yang mendampingi bisa berbeda di tiap HP).
class ParentMode extends ValueNotifier<bool> {
  ParentMode._() : super(false);
  static final ParentMode instance = ParentMode._();

  static const _key = 'parent_mode';
  bool _loaded = false;

  bool get enabled => value;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      value = prefs.getBool(_key) ?? false;
    } catch (_) {
      // penyimpanan tidak tersedia: pakai bawaan (mati)
    }
  }

  Future<void> set(bool on) async {
    value = on;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, on);
    } catch (_) {}
  }
}
