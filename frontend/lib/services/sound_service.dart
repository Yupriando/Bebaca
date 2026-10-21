import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daftar efek suara (file di assets/sounds/).
enum Sfx { tap, correct, wrong, next, success, star1, star2, star3, fanfare, micOn, chime }

/// Efek suara pendek. Mengikuti pengaturan "Sound Effect" (disimpan juga di perangkat
/// supaya splash screen bisa ikut menyesuaikan sebelum login).
/// Aman dipanggil kapan saja: kalau gagal memutar, tidak melempar error.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _prefKey = 'sound_enabled';
  static const _files = <Sfx, String>{
    Sfx.tap: 'sounds/tap.wav',
    Sfx.correct: 'sounds/correct.wav',
    Sfx.wrong: 'sounds/wrong.wav',
    Sfx.next: 'sounds/next.wav',
    Sfx.success: 'sounds/success.wav',
    Sfx.star1: 'sounds/star1.wav',
    Sfx.star2: 'sounds/star2.wav',
    Sfx.star3: 'sounds/star3.wav',
    Sfx.fanfare: 'sounds/fanfare.wav',
    Sfx.micOn: 'sounds/mic_on.wav',
    Sfx.chime: 'sounds/chime.wav',
  };

  final Map<Sfx, AudioPlayer> _players = {};
  bool _enabled = true;
  bool _loaded = false;

  bool get enabled => _enabled;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? true;
      // Efek suara dicampur dengan suara lain (mis. pembacaan huruf), tidak memotongnya.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  Future<void> play(Sfx sfx, {double volume = 0.8}) async {
    if (!_enabled) return;
    try {
      if (!_loaded) await load();
      // satu pemutar per efek: efek berbeda bisa terdengar bersamaan
      final player = _players.putIfAbsent(
        sfx,
        () => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
      );
      await player.stop();
      await player.play(
        AssetSource(_files[sfx]!),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }
}
