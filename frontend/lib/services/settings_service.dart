import '../models/app_settings.dart';
import 'api_client.dart';

class SettingsService {
  final _api = ApiClient.instance;

  Future<AppSettings> getSettings() async {
    final j = await _api.get('/api/settings') as Map<String, dynamic>;
    return AppSettings.fromJson(j);
  }

  Future<void> saveSettings(AppSettings s) async {
    await _api.put('/api/settings', body: {
      'soundEffect': s.soundEffect,
      'animation': s.animation,
      'listeningExercise': s.listeningExercise,
      'parentalControl': s.parentalControl,
      'timeLimitMinutes': s.timeLimitMinutes,
      'curfew': s.curfew,
    });
  }

  /// Cek PIN orang tua. Melempar ApiException (403) jika salah.
  Future<void> verifyParentPin(String pin) async {
    await _api.post('/api/settings/parent-pin/verify', body: {'pin': pin});
  }

  /// Buat / ganti PIN orang tua (butuh password akun).
  Future<AppSettings> setParentPin({
    required String pin,
    required String password,
  }) async {
    final j = await _api.put('/api/settings/parent-pin',
        body: {'pin': pin, 'password': password}) as Map<String, dynamic>;
    return AppSettings.fromJson(j);
  }

  /// Tambah waktu belajar hari ini (menit). Mengembalikan pengaturan terbaru
  /// (termasuk total waktu belajar hari ini).
  Future<AppSettings> addUsage(int minutes) async {
    final j = await _api.post('/api/settings/usage', body: {'minutes': minutes})
        as Map<String, dynamic>;
    return AppSettings.fromJson(j);
  }
}
