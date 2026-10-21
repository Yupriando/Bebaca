import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bebaca hanya dipakai dalam posisi LANDSCAPE (HP/tablet dimiringkan).
/// Juga diatur di AndroidManifest (screenOrientation) & Info.plist iOS,
/// supaya sejak aplikasi dibuka tidak sempat tampil tegak.
const landscapeOnly = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

Future<void> lockLandscape() => SystemChrome.setPreferredOrientations(landscapeOnly);

/// Tampilan aplikasi: landscape + layar penuh (status bar & tombol navigasi disembunyikan,
/// muncul sebentar saat layar diusap dari tepi). Dipanggil saat start & setelah video penuh.
Future<void> applyAppSystemUi() async {
  await lockLandscape();
  final mobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (mobile) await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}
