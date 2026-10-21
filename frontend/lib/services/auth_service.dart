import 'api_client.dart';
import 'settings_store.dart';
import 'token_storage.dart';

/// Hasil dari proses auth.
class AuthResult {
  final bool success;
  final String? message;

  const AuthResult({required this.success, this.message});
}

class AuthService {
  final _api = ApiClient.instance;
  final _storage = TokenStorage();

  Future<bool> isLoggedIn() => _storage.hasSession;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.post(
        '/api/auth/login',
        body: {'email': email, 'password': password},
        auth: false,
      ) as Map<String, dynamic>;
      await _saveSession(data);
      return const AuthResult(success: true);
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  Future<AuthResult> register({
    required int umur,
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      await _api.post(
        '/api/auth/register',
        body: {'umur': umur, 'nama': nama, 'email': email, 'password': password},
        auth: false,
      );
      return const AuthResult(success: true);
    } on ApiException catch (e) {
      return AuthResult(success: false, message: e.message);
    }
  }

  /// Selalu menghapus token lokal, walaupun request ke server gagal.
  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout', retryOn401: false);
    } catch (_) {
      // abaikan: yang penting sesi lokal dibersihkan
    } finally {
      await _storage.clear();
      await SettingsStore.instance.clear();
    }
  }

  // ---------------------------------------------------------------

  Future<void> _saveSession(Map<String, dynamic> data) => _storage.save(
        data['access_token'] as String,
        data['refresh_token'] as String,
      );
}
