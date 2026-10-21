import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import 'api_client.dart';
import 'subscription_service.dart';

/// Status Bebaca Premium yang berlaku sekarang. Halaman Belajar, Dongeng, Profil,
/// dan Settings ikut berubah seketika saat status berubah.
///
/// MODE SIMULASI: belum ada pembayaran sungguhan. [activate] langsung menjadikan
/// premium, [deactivate] ("Pulihkan pembelian") mengembalikan ke gratis.
class PremiumStore extends ChangeNotifier {
  PremiumStore._();
  static final PremiumStore instance = PremiumStore._();

  final _service = SubscriptionService();
  SubscriptionStatus _status = SubscriptionStatus.free;
  bool _busy = false;
  String? _error;
  int _purchaseCount = 0;

  SubscriptionStatus get status => _status;
  bool get isPremium => _status.isPremium;
  bool get busy => _busy;
  String? get error => _error;

  /// Bertambah setiap kali berhasil menjadi premium (untuk efek "selamat!").
  int get purchaseCount => _purchaseCount;

  /// Dipanggil setelah login (MainShell).
  void init() => refresh();

  /// Ambil status premium terbaru dari server.
  Future<void> refresh() async {
    try {
      _set(await _service.getStatus());
    } catch (_) {
      // offline: pakai status terakhir
    }
  }

  /// Saat logout: lupakan status akun sebelumnya.
  void reset() {
    _status = SubscriptionStatus.free;
    _error = null;
    _busy = false;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _set(SubscriptionStatus s) {
    _status = s;
    notifyListeners();
  }

  Future<void> activate(PremiumPlan plan) => _run(() async {
        _set(await _service.activate(plan));
        if (isPremium) _purchaseCount++;
      });

  Future<void> deactivate() => _run(() async => _set(await _service.deactivate()));

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _busy = false;
    notifyListeners();
  }
}
