import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'settings_service.dart';
import 'sound_service.dart';

enum LockReason { none, timeLimit, curfew }

/// Pengaturan aplikasi yang berlaku sekarang. Semua bagian aplikasi (suara, animasi,
/// lesson, kontrol orang tua) membaca dari sini, dan berubah seketika saat pengguna
/// mengganti pengaturan. Salinan terakhir disimpan di perangkat supaya splash screen
/// bisa mengikuti pengaturan sebelum data dari server tiba.
class SettingsStore extends ChangeNotifier {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  static const _cacheKey = 'app_settings_cache';
  static const _wakeMinutes = 5 * 60; // jam malam berakhir pukul 05:00

  final _service = SettingsService();
  AppSettings _value = const AppSettings();
  bool _loaded = false;

  AppSettings get value => _value;

  /// true jika sudah pernah berhasil mengambil data dari server pada sesi ini.
  bool get loaded => _loaded;

  /// Muat salinan terakhir dari perangkat (cepat, tanpa internet).
  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        _value = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Ambil pengaturan terbaru dari server. Melempar ApiException jika gagal.
  Future<void> refresh() async {
    final s = await _service.getSettings();
    _loaded = true;
    _set(s);
  }

  /// Terapkan langsung (optimistis), lalu simpan ke server. Jika gagal, dikembalikan
  /// seperti semula dan error dilempar ulang agar bisa ditampilkan.
  Future<void> update(AppSettings next) async {
    final previous = _value;
    _set(next);
    try {
      await _service.saveSettings(next);
    } catch (_) {
      _set(previous);
      rethrow;
    }
  }

  /// Cek PIN orang tua di server. Melempar ApiException jika salah / gagal.
  Future<void> verifyParentPin(String pin) => _service.verifyParentPin(pin);

  /// Buat / ganti PIN orang tua (butuh password akun).
  Future<void> setParentPin({required String pin, required String password}) async {
    _set(await _service.setParentPin(pin: pin, password: password));
  }

  /// Catat waktu belajar; server mengembalikan total hari ini.
  Future<void> addUsage(int minutes) async {
    _set(await _service.addUsage(minutes));
  }

  /// Dipanggil saat logout: kembali ke bawaan dan hapus salinan akun sebelumnya.
  Future<void> clear() async {
    _loaded = false;
    _value = const AppSettings();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
    notifyListeners();
  }

  void _set(AppSettings s) {
    final soundChanged = s.soundEffect != _value.soundEffect;
    _value = s;
    if (soundChanged) SoundService.instance.setEnabled(s.soundEffect);
    _saveCache();
    notifyListeners();
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_value.toJson()));
    } catch (_) {}
  }

  // ---------------- Kontrol orang tua ----------------

  /// Terkunci karena apa? (none = boleh dipakai)
  LockReason get lockReason {
    final s = _value;
    if (!s.parentalControl) return LockReason.none;
    if (curfewActive(DateTime.now(), s.curfew)) return LockReason.curfew;
    if (s.timeLimitMinutes > 0 && s.timespentMinutes >= s.timeLimitMinutes) {
      return LockReason.timeLimit;
    }
    return LockReason.none;
  }

  int get remainingMinutes => _value.timeLimitMinutes <= 0
      ? -1
      : (_value.timeLimitMinutes - _value.timespentMinutes).clamp(0, 100000);

  /// Jam malam berlaku dari [curfew] ("HH:mm") sampai pukul 05:00 pagi.
  static bool curfewActive(DateTime now, String curfew) {
    final parts = curfew.split(':');
    final c = (int.tryParse(parts[0]) ?? 20) * 60 +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    final n = now.hour * 60 + now.minute;
    return c >= _wakeMinutes
        ? (n >= c || n < _wakeMinutes) // mis. 20:00 -> 05:00 (melewati tengah malam)
        : (n >= c && n < _wakeMinutes); // mis. 03:00 -> 05:00
  }
}
