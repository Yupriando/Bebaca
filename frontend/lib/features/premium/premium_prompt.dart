import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/event_logger.dart';
import '../lesson/widgets/mascot.dart';
import '../settings/parental_gate.dart';
import 'premium_page.dart';

/// Buka halaman Bebaca Premium. Selalu lewat gerbang orang tua dulu
/// (aturan Google Play & App Store untuk pembelian di aplikasi anak).
Future<void> openPremium(BuildContext context) async {
  if (!await showParentalGate(context)) return;
  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => const PremiumPage()),
  );
}

/// Dialog ramah anak saat menekan konten premium: "minta ayah/ibu ya!".
/// [what] mis. "Cerita ini" atau "Pelajaran ini".
Future<void> showPremiumPrompt(BuildContext context, {required String what}) async {
  EventLogger.instance.ui('premium_prompt', {'what': what});
  final callParent = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(mood: MascotMood.idle, size: 96),
          const SizedBox(height: 16),
          Text(
            'Khusus Premium ⭐',
            textAlign: TextAlign.center,
            style: GoogleFonts.itim(
                fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '$what khusus Bebaca Premium.\nMinta ayah atau ibu untuk membukanya, ya!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: AppColors.textDark, height: 1.3),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Nanti saja', style: TextStyle(fontSize: 18)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          child: const Text('Panggil Ayah/Ibu', style: TextStyle(fontSize: 18)),
        ),
      ],
    ),
  );
  if (callParent == true && context.mounted) await openPremium(context);
}

/// Lencana kecil "⭐ Premium" / gembok untuk kartu & jalur lesson.
class PremiumBadge extends StatelessWidget {
  final bool compact;
  const PremiumBadge({super.key, this.compact = false});

  static const gold = Color(0xFFFFB81C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: compact ? 6 : 6),
      decoration: BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(compact ? 30 : 14),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: compact ? 16 : 18, color: Colors.white),
          if (!compact) ...[
            const SizedBox(width: 4),
            const Text('Premium',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ],
      ),
    );
  }
}
