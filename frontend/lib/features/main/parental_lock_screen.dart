import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../services/api_client.dart';
import '../../services/settings_store.dart';
import '../lesson/widgets/effects.dart';
import '../settings/parental_gate.dart';

/// Layar penuh yang menutup aplikasi saat waktu belajar habis atau sudah jam malam.
/// Orang tua bisa membukanya dengan PIN orang tua.
class ParentalLockScreen extends StatelessWidget {
  final LockReason reason;
  const ParentalLockScreen({super.key, required this.reason});

  Future<void> _parentOptions(BuildContext context) async {
    if (!await showParentalGate(context)) return;
    if (!context.mounted) return;

    final store = SettingsStore.instance;
    final s = store.value;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilihan orang tua'),
        children: [
          if (reason == LockReason.timeLimit)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'extend'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Tambah 15 menit hari ini', style: TextStyle(fontSize: 18)),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'off'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Matikan kontrol orang tua', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
    if (choice == null) return;

    try {
      if (choice == 'extend') {
        await store.update(s.copyWith(timeLimitMinutes: s.timeLimitMinutes + 15));
      } else {
        await store.update(s.copyWith(parentalControl: false));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsStore.instance.value;
    final isCurfew = reason == LockReason.curfew;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Bob(
                  enabled: s.animation,
                  amplitude: 10,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: Icon(
                      isCurfew ? Icons.bedtime_rounded : Icons.hourglass_bottom_rounded,
                      size: 76,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  isCurfew ? 'Waktunya istirahat' : 'Waktu belajar habis',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Text(
                    isCurfew
                        ? 'Sekarang sudah lewat jam malam (${s.curfew}). Belajar lagi besok pagi ya!'
                        : 'Hari ini kamu sudah belajar ${s.timespentMinutes} menit dari batas ${s.timeLimitMinutes} menit. Sampai jumpa besok!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, color: Color(0xFF555555)),
                  ),
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: 'Untuk orang tua',
                  onPressed: () => _parentOptions(context),
                  width: 260,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
