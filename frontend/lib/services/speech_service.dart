import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Suara untuk belajar: membacakan huruf (TTS) dan mendengarkan anak membaca (STT).
/// Semua method aman dipanggil walau perangkat tidak mendukung (tidak melempar error).
///
/// Urutan suara yang dipakai saat membacakan:
///  1. Rekaman suara AI (natural, logat Indonesia) di assets/voice/<kunci>.mp3,
///     dibuat sekali dengan tool/generate_voice.py. Contoh kunci: "ini huruf a" -> ini_huruf_a
///  2. Kalau rekamannya tidak ada: suara bahasa Indonesia terbaik di perangkat
///     (Google TTS di Android, Damayanti/Enhanced di iPhone/iPad).
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  // ---------------- Text to Speech ----------------
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  final AudioPlayer _voice = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  Set<String>? _clips; // nama file rekaman yang tersedia di assets/voice/

  /// "Ini huruf a" -> "ini_huruf_a" (harus sama dengan tool/generate_voice.py)
  static String clipKey(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  Future<Set<String>> _loadClips() async {
    if (_clips != null) return _clips!;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _clips = manifest
          .listAssets()
          .where((a) => a.startsWith('assets/voice/') && a.endsWith('.mp3'))
          .map((a) => a.substring('assets/voice/'.length, a.length - 4))
          .toSet();
    } catch (_) {
      _clips = {};
    }
    return _clips!;
  }

  /// Nama huruf dalam bahasa Indonesia (supaya TTS tidak salah baca).
  static const _letterNames = {
    'A': 'a', 'B': 'be', 'C': 'ce', 'D': 'de', 'E': 'e', 'F': 'ef', 'G': 'ge',
    'H': 'ha', 'I': 'i', 'J': 'je', 'K': 'ka', 'L': 'el', 'M': 'em', 'N': 'en',
    'O': 'o', 'P': 'pe', 'Q': 'ki', 'R': 'er', 'S': 'es', 'T': 'te', 'U': 'u',
    'V': 've', 'W': 'we', 'X': 'eks', 'Y': 'ye', 'Z': 'zet',
  };

  static String letterName(String letter) =>
      _letterNames[letter.toUpperCase()] ?? letter.toLowerCase();

  Future<void> _initTts() async {
    if (_ttsReady) return;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // mesin Google punya suara bahasa Indonesia yang paling natural
        final engines = (await _tts.getEngines as List?)?.cast<Object?>() ?? const [];
        if (engines.contains('com.google.android.tts')) {
          await _tts.setEngine('com.google.android.tts');
        }
      }
      await _tts.setLanguage('id-ID');
      await _pickBestVoice();
      await _tts.setSpeechRate(0.45); // sedikit pelan, cocok untuk anak
      await _tts.setPitch(1.05);
      _ttsReady = true;
    } catch (_) {}
  }

  /// Pilih suara bahasa Indonesia dengan kualitas tertinggi yang bisa dipakai offline.
  Future<void> _pickBestVoice() async {
    try {
      final voices = ((await _tts.getVoices) as List? ?? const [])
          .whereType<Map>()
          .where((v) => '${v['locale']}'.toLowerCase().replaceAll('_', '-').startsWith('id'))
          .toList();
      if (voices.isEmpty) return;

      int score(Map v) {
        final name = '${v['name']}'.toLowerCase();
        final quality = '${v['quality']}'.toLowerCase();
        var s = 0;
        if (quality.contains('premium')) s += 400; // iOS
        if (quality.contains('enhanced')) s += 300; // iOS
        final q = int.tryParse(quality); // Android: 100..500
        if (q != null) s += q ~/ 2;
        if ('${v['network_required']}' == '1' || name.contains('network')) s -= 150;
        if (name.contains('local')) s += 20;
        return s;
      }

      voices.sort((a, b) => score(b).compareTo(score(a)));
      final best = voices.first;
      await _tts.setVoice({'name': '${best['name']}', 'locale': '${best['locale']}'});
    } catch (_) {}
  }

  int _trackToken = 0; // naik setiap ada ucapan baru -> callback lama diabaikan

  Future<void> speak(String text) async {
    try {
      _trackToken++;
      await stopSpeaking();
      final key = clipKey(text);
      if ((await _loadClips()).contains(key)) {
        await _voice.play(AssetSource('voice/$key.mp3'));
        return;
      }
      await _initTts();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> speakLetter(String letter) => speak(letterName(letter));

  /// Bacakan [text] dengan suara perangkat sambil melaporkan posisi kata yang sedang
  /// diucapkan ([onWord]: indeks karakter awal & akhir) dan saat selesai ([onDone]).
  /// Dipakai Baca Bersama bila rekaman narasi belum ada.
  Future<void> speakTracked(
    String text, {
    void Function(int start, int end)? onWord,
    void Function()? onDone,
  }) async {
    await stopSpeaking(); // juga menaikkan _trackToken, jadi ambil token SESUDAHNYA
    final token = ++_trackToken;
    try {
      await _initTts();
      _tts.setProgressHandler((_, start, end, __) {
        if (token == _trackToken) onWord?.call(start, end);
      });
      _tts.setCompletionHandler(() {
        if (token == _trackToken) onDone?.call();
      });
      await _tts.speak(text);
    } catch (_) {
      if (token == _trackToken) onDone?.call();
    }
  }

  Future<void> stopSpeaking() async {
    _trackToken++;
    try {
      await _voice.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  // ---------------- Speech to Text ----------------
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  String? _localeId;

  /// Minta izin mikrofon + siapkan pengenalan suara. false = tidak tersedia.
  Future<bool> initListening() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize(onError: (_) {});
      if (_sttReady) {
        final locales = await _stt.locales();
        for (final l in locales) {
          if (l.localeId.toLowerCase().startsWith('id')) {
            _localeId = l.localeId; // pakai bahasa Indonesia bila ada
            break;
          }
        }
      }
    } catch (_) {
      _sttReady = false;
    }
    return _sttReady;
  }

  /// Dengarkan anak berbicara. Bawaan cocok untuk 1 huruf; untuk membaca kalimat
  /// (Baca Bersama) pakai [listenFor] & [pauseFor] yang lebih panjang.
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    Duration listenFor = const Duration(seconds: 6),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    await stopSpeaking();
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) =>
          onResult(r.recognizedWords, r.finalResult),
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: _localeId,
    );
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }

  Future<void> cancelListening() async {
    try {
      await _stt.cancel();
    } catch (_) {}
  }
}

/// Apakah ucapan [heard] cocok dengan huruf [letter]? (dibuat longgar,
/// karena pengenalan suara untuk 1 huruf sering berupa "a", "ah", "be", dst.)
bool spokenLetterMatches(String heard, String letter) {
  final h = heard.trim().toLowerCase();
  if (h.isEmpty) return false;
  final l = letter.toLowerCase();
  final name = SpeechService.letterName(letter);
  return h
      .split(RegExp(r'\s+'))
      .any((w) => w == l || w == name || (w.length <= 3 && w.startsWith(l)));
}
