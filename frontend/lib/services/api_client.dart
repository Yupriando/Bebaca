import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'token_storage.dart';

/// Error dari API / jaringan. `message` aman ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Client HTTP tunggal untuk semua service:
/// - otomatis menambah header Authorization
/// - kalau token kedaluwarsa (401) -> refresh token -> ulangi request
/// - kalau refresh gagal -> hapus token & panggil [onSessionExpired]
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Diisi di main.dart: pindah ke halaman awal saat sesi habis.
  static VoidCallback? onSessionExpired;

  static const _timeout = Duration(seconds: 15);
  final http.Client _http = http.Client();
  final TokenStorage _storage = TokenStorage();
  Future<bool>? _refreshing;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
    bool retryOn401 = true,
  }) =>
      _send('POST', path, body: body, auth: auth, retryOn401: retryOn401);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Unggah satu file (multipart/form-data), mis. foto profil.
  Future<dynamic> postFile(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
  }) =>
      _sendFile(path, field: field, bytes: bytes, filename: filename);

  // ---------------------------------------------------------------

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<http.Response> _guarded(
    Future<http.Response> Function() call, {
    Duration timeout = _timeout,
  }) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Server tidak merespons, coba lagi');
    } catch (_) {
      throw const ApiException('Tidak bisa terhubung ke server');
    }
  }

  Future<http.Response> _request(
    String method,
    String path,
    Map<String, String> headers,
    Object? body,
  ) {
    final uri = _uri(path);
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return _http.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        return _http.delete(uri, headers: headers);
      default:
        return _http.get(uri, headers: headers);
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _storage.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final res = await _guarded(() => _request(method, path, headers, body));

    if (res.statusCode == 401 && auth && retryOn401) {
      if (await _refresh()) {
        return _send(method, path, body: body, auth: auth, retryOn401: false);
      }
      await _storage.clear();
      onSessionExpired?.call();
      throw const ApiException('Sesi berakhir, silakan login lagi',
          statusCode: 401);
    }
    return _parse(res);
  }

  Future<dynamic> _sendFile(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    bool retryOn401 = true,
  }) async {
    final token = await _storage.accessToken;

    // MultipartRequest hanya bisa dikirim sekali -> dibuat ulang tiap percobaan.
    final res = await _guarded(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers['Accept'] = 'application/json'
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      final streamed = await _http.send(request);
      return http.Response.fromStream(streamed);
    }, timeout: const Duration(seconds: 60));

    if (res.statusCode == 401 && retryOn401) {
      if (await _refresh()) {
        return _sendFile(path,
            field: field, bytes: bytes, filename: filename, retryOn401: false);
      }
      await _storage.clear();
      onSessionExpired?.call();
      throw const ApiException('Sesi berakhir, silakan login lagi',
          statusCode: 401);
    }
    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {}
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final message = (data is Map && data['message'] is String)
        ? data['message'] as String
        : 'Terjadi kesalahan (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }

  // Refresh token digabung: banyak request 401 bersamaan hanya memicu 1 refresh.
  Future<bool> _refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null) return false;

    final res = await _guarded(() => _http.post(
          _uri('/api/auth/refresh'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refresh}),
        ));
    if (res.statusCode != 200) return false;

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    await _storage.save(
      data['access_token'] as String,
      data['refresh_token'] as String,
    );
    return true;
  }
}
