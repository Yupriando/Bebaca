import 'dart:async';
import 'api_client.dart';

/// Pencatat kejadian belajar (untuk Laporan Perkembangan & Pantau Langsung orang tua).
/// Kejadian dikumpulkan lalu dikirim berkelompok tiap ~2 detik (hemat kuota).
/// Kalau gagal (offline), disimpan sebentar dan dicoba lagi. Tidak pernah melempar error.
///
/// Yang dicatat hanya aktivitas belajar (mis. "jawab huruf B: salah, memilih D"),
/// BUKAN isi layar, foto, atau suara anak.
class EventLogger {
  EventLogger._();
  static final EventLogger instance = EventLogger._();

  static const _maxQueue = 300;
  final _queue = <Map<String, Object?>>[];
  Timer? _timer;
  bool _sending = false;
  int _failures = 0;

  void log(String type, [Map<String, Object?> data = const {}]) {
    _queue.add({
      'type': type,
      'data': data,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    if (_queue.length > _maxQueue) _queue.removeRange(0, _queue.length - _maxQueue);
    _schedule(const Duration(seconds: 2));
  }

  void _schedule(Duration delay) {
    _timer ??= Timer(delay, () {
      _timer = null;
      flush();
    });
  }

  Future<void> flush() async {
    if (_sending || _queue.isEmpty) return;
    _sending = true;
    final batch = _queue.take(50).toList();
    try {
      await ApiClient.instance.post('/api/events', body: {'events': batch});
      _queue.removeRange(0, batch.length);
      _failures = 0;
    } catch (_) {
      _failures++;
    } finally {
      _sending = false;
    }
    if (_queue.isNotEmpty) {
      // gagal -> tunggu makin lama (maks. 1 menit); berhasil -> kirim sisanya segera
      _schedule(Duration(seconds: _failures == 0 ? 1 : (5 * _failures).clamp(5, 60)));
    }
  }

  /// Saat logout: buang kejadian akun sebelumnya.
  void clear() {
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    _failures = 0;
  }
}
