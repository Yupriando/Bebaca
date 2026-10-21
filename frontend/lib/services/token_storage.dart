import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan token login di perangkat.
/// Catatan: SharedPreferences tidak terenkripsi. Untuk produksi, pertimbangkan
/// flutter_secure_storage (cukup ganti isi file ini).
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> get accessToken async =>
      (await SharedPreferences.getInstance()).getString(_accessKey);

  Future<String?> get refreshToken async =>
      (await SharedPreferences.getInstance()).getString(_refreshKey);

  Future<bool> get hasSession async => (await accessToken) != null;

  Future<void> save(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
