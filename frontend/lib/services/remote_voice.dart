import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Rekaman suara AI yang disimpan di Supabase Storage (bucket publik "narasi"), bukan di
/// dalam aplikasi: narasi halaman dongeng (st_xxx.mp3 + .json waktu tiap kata) dan suara
/// pendek dongeng (pesan moral, kuis, pertanyaan ngobrol, arti kata baru).
/// Jadi APK tetap kecil, dan dongeng baru langsung bersuara tanpa update aplikasi.
///
/// Daftar rekaman yang tersedia ada di `manifest.json` (dibuat tool/generate_story_voice.py),
/// diambil sekali lalu disimpan di memori. Alamat bucket dikirim backend bersama detail dongeng.
class RemoteVoice {
  RemoteVoice._();
  static final RemoteVoice instance = RemoteVoice._();

  String? _base; // https://xxx.supabase.co/storage/v1/object/public/narasi/
  Set<String>? _keys;
  Future<Set<String>>? _loading;
  DateTime? _failedAt;
  final Map<String, Map<String, dynamic>> _timings = {};

  /// Dipanggil saat detail dongeng dimuat. Daftar rekaman langsung diambil di latar belakang.
  void setBase(String? base) {
    if (base == null || base.isEmpty) return;
    final b = base.endsWith('/') ? base : '$base/';
    if (b == _base) return;
    _base = b;
    _keys = null;
    _loading = null;
    _failedAt = null;
    unawaited(keys());
  }

  /// URL rekaman, mis. url('st_5efdabcc', 'mp3').
  String? url(String key, String ext) => _base == null ? null : '$_base$key.$ext';

  /// Sudah pasti ada (tanpa menunggu jaringan): dipakai untuk suara pendek supaya tidak tertunda.
  bool hasLoaded(String key) => _keys?.contains(key) ?? false;

  /// Daftar rekaman (menunggu jaringan bila belum diambil). Gagal = kosong, dicoba lagi 1 menit kemudian.
  Future<Set<String>> keys() {
    if (_keys != null) return Future.value(_keys!);
    final base = _base;
    if (base == null) return Future.value(const <String>{});
    if (_failedAt != null && DateTime.now().difference(_failedAt!) < const Duration(minutes: 1)) {
      return Future.value(const <String>{});
    }
    return _loading ??= () async {
      try {
        final res = await http.get(Uri.parse('${base}manifest.json')).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final list = (jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>).map((e) => '$e').toSet();
          if (base == _base) _keys = list;
          return list;
        }
      } catch (_) {
        // tidak ada internet / manifest belum dibuat
      }
      _failedAt = DateTime.now();
      _loading = null;
      return const <String>{};
    }();
  }

  /// Waktu tiap kata untuk narasi halaman ({text, words: [[mulai, selesai], ...]}).
  Future<Map<String, dynamic>?> timings(String key) async {
    final cached = _timings[key];
    if (cached != null) return cached;
    final u = url(key, 'json');
    if (u == null) return null;
    try {
      final res = await http.get(Uri.parse(u)).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      _timings[key] = json;
      return json;
    } catch (_) {
      return null;
    }
  }
}
