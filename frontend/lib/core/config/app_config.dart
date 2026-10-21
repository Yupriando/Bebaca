import 'package:flutter/foundation.dart';

class AppConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// Alamat backend.
  /// - Emulator Android  : http://10.0.2.2:3000 (otomatis)
  /// - iOS simulator/web : http://localhost:3000 (otomatis)
  /// - HP asli / deploy  : flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
  static String get baseUrl {
    var url = _fromEnv;
    if (url.isEmpty) {
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      url = isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
