import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../services/speech_service.dart';
import 'story_pages.dart';

/// Membacakan satu halaman Baca Bersama dan memberi tahu kata mana yang sedang dibaca
/// ([wordIndex]) supaya bisa dinyalakan seperti karaoke.
///
/// 1. Rekaman narasi AI: assets/stories/<narrationKey>.mp3 + .json (waktu tiap kata),
///    dibuat dengan tool/generate_story_voice.py.
/// 2. Kalau rekaman tidak ada: suara perangkat (TTS) dengan posisi kata dari TTS.
/// Suara yang sedang dipakai narator (ditampilkan saat debug untuk memeriksa).
enum NarrationSource { none, recording, device }

class StoryNarrator extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _doneSub;
  static Set<String>? _clips;

  int _wordIndex = -1;
  bool _playing = false;
  int _token = 0;
  bool _disposed = false;

  NarrationSource _source = NarrationSource.none;
  String? _lastError;

  int get wordIndex => _wordIndex;
  NarrationSource get source => _source;
  String? get lastError => _lastError;
  bool get playing => _playing;

  static Future<Set<String>> _loadClips() async {
    if (_clips != null) return _clips!;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _clips = manifest
          .listAssets()
          .where((a) => a.startsWith('assets/stories/') && a.endsWith('.mp3'))
          .map((a) => a.substring('assets/stories/'.length, a.length - 4))
          .toSet();
    } catch (_) {
      _clips = {};
    }
    return _clips!;
  }

  void _setWord(int i) {
    if (_disposed || i == _wordIndex) return;
    _wordIndex = i;
    notifyListeners();
  }

  /// Bacakan [text]. [onFinished] dipanggil kalau selesai sampai akhir (bukan dihentikan).
  Future<void> play(String text, {VoidCallback? onFinished}) async {
    await stop();
    final token = ++_token;
    _playing = true;
    _wordIndex = -1;
    notifyListeners();

    void finish() {
      if (_disposed || token != _token) return;
      _playing = false;
      _wordIndex = -1;
      notifyListeners();
      onFinished?.call();
    }

    final key = narrationKey(text);
    final clips = await _loadClips();
    if (!clips.contains(key)) {
      _lastError = 'Rekaman $key tidak ada di aplikasi (${clips.length} rekaman terdaftar)';
      debugPrint('[Baca Bersama] $_lastError');
    }
    if (clips.contains(key)) {
      try {
        final json = jsonDecode(await rootBundle.loadString('assets/stories/$key.json'))
            as Map<String, dynamic>;
        final starts = [
          for (final w in json['words'] as List<dynamic>) ((w as List<dynamic>)[0] as num).toDouble()
        ];
        _posSub = _player.onPositionChanged.listen((pos) {
          if (token != _token) return;
          final t = pos.inMilliseconds / 1000;
          var i = -1;
          while (i + 1 < starts.length && starts[i + 1] <= t + 0.05) {
            i++;
          }
          _setWord(i);
        });
        _doneSub = _player.onPlayerComplete.listen((_) => finish());
        await _player.play(AssetSource('stories/$key.mp3'));
        _source = NarrationSource.recording;
        _lastError = null;
        notifyListeners();
        return;
      } catch (e) {
        // rekaman gagal diputar -> pakai suara perangkat
        _lastError = 'Gagal memutar rekaman $key: $e';
        debugPrint('[Baca Bersama] $_lastError');
        await _posSub?.cancel();
        await _doneSub?.cancel();
      }
    }
    _source = NarrationSource.device;
    notifyListeners();

    // suara perangkat: posisi karakter -> indeks kata
    final wordStarts = RegExp(r'\S+').allMatches(text).map((m) => m.start).toList();
    await SpeechService.instance.speakTracked(
      text,
      onWord: (start, _) {
        if (token != _token) return;
        var i = 0;
        while (i + 1 < wordStarts.length && wordStarts[i + 1] <= start) {
          i++;
        }
        _setWord(i);
      },
      onDone: finish,
    );
  }

  Future<void> stop() async {
    _token++;
    await _posSub?.cancel();
    await _doneSub?.cancel();
    _posSub = null;
    _doneSub = null;
    try {
      await _player.stop();
    } catch (_) {}
    await SpeechService.instance.stopSpeaking();
    if (!_disposed && (_playing || _wordIndex != -1)) {
      _playing = false;
      _wordIndex = -1;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    _player.dispose();
    super.dispose();
  }
}

/// Mencocokkan ucapan anak dengan kata-kata halaman (mode "Aku yang baca").
/// Mengembalikan jumlah kata halaman yang sudah terbaca berurutan dari awal.
/// Dibuat longgar: boleh melewati 2 kata, tanda baca & huruf besar diabaikan.
int matchReadWords(List<String> pageWords, String heard) {
  String norm(String w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final target = pageWords.map(norm).toList();
  final spoken = heard.split(RegExp(r'\s+')).map(norm).where((w) => w.isNotEmpty);

  var pos = 0; // kata halaman berikutnya yang ditunggu
  for (final w in spoken) {
    for (var k = 0; k < 3 && pos + k < target.length; k++) {
      final t = target[pos + k];
      if (t.isNotEmpty && (t == w || (t.length > 3 && w.length > 3 && t.startsWith(w.substring(0, 4))))) {
        pos += k + 1;
        break;
      }
    }
  }
  // lompati "kata" yang hanya tanda baca
  while (pos < target.length && target[pos].isEmpty) {
    pos++;
  }
  return pos;
}
