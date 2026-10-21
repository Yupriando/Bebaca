import 'dart:typed_data';
import '../models/user_profile.dart';
import 'api_client.dart';

class ProfileService {
  final _api = ApiClient.instance;

  Future<UserProfile> getProfile() async {
    final data = await _api.get('/api/profile') as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  /// Ubah profil. Jika [tanggalLahir] diisi, umur dihitung otomatis oleh server.
  /// [clearTanggalLahir] menghapus tanggal lahir (umur memakai nilai [umur]).
  Future<UserProfile> updateProfile({
    String? nama,
    DateTime? tanggalLahir,
    bool clearTanggalLahir = false,
    int? umur,
  }) async {
    final body = <String, dynamic>{};
    if (nama != null) body['nama'] = nama;
    if (tanggalLahir != null) {
      body['tanggalLahir'] = _formatDate(tanggalLahir);
    } else if (clearTanggalLahir) {
      body['tanggalLahir'] = null;
    }
    if (umur != null) body['umur'] = umur;

    final data = await _api.put('/api/profile', body: body) as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> uploadAvatar(Uint8List bytes, String filename) async {
    final data = await _api.postFile(
      '/api/profile/avatar',
      field: 'avatar',
      bytes: bytes,
      filename: filename,
    ) as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> removeAvatar() async {
    final data = await _api.delete('/api/profile/avatar') as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
