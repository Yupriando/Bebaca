import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/subscription.dart';
import '../../services/premium_store.dart';
import '../lesson/widgets/confetti.dart';

/// Halaman Bebaca Premium (khusus orang tua, dibuka lewat gerbang orang tua).
///
/// MODE SIMULASI (belum ada pembayaran sungguhan):
/// - "Langganan Sekarang" -> akun langsung premium
/// - "Pulihkan pembelian"  -> akun kembali gratis
class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final _store = PremiumStore.instance;
  PremiumPlan _selected = PremiumPlan.yearly;
  late int _seenPurchases = _store.purchaseCount;
  bool _celebrate = false;

  // Harga contoh untuk tampilan. Nanti diganti harga asli dari Google Play / App Store.
  static const _prices = {
    PremiumPlan.monthly: 29000,
    PremiumPlan.yearly: 249000,
  };

  @override
  void initState() {
    super.initState();
    _store.clearError();
    _store.addListener(_onStore);
    _store.refresh();
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (_store.purchaseCount != _seenPurchases) {
      _seenPurchases = _store.purchaseCount;
      setState(() => _celebrate = true);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _celebrate = false);
      });
    }
  }

  static String _rupiah(num value) =>
      'Rp${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      PrimaryButton(
                        label: 'Back',
                        onPressed: () => Navigator.pop(context),
                        width: 100,
                        height: 44,
                        fontSize: 20,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _store,
                    builder: (context, _) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _store.isPremium
                                  ? _ActiveView(status: _store.status)
                                  : _offer(),
                              if (_store.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Text(
                                    _store.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.redAccent),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _store.busy || !_store.isPremium
                                    ? null
                                    : _store.deactivate,
                                child: const Text('Pulihkan pembelian',
                                    style: TextStyle(fontSize: 18)),
                              ),
                              const _SimulationNote(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_celebrate)
              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiOverlay(key: ValueKey(_seenPurchases)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _offer() {
    final monthly = _prices[PremiumPlan.monthly]!;
    final yearly = _prices[PremiumPlan.yearly]!;
    final savePercent = ((1 - yearly / (monthly * 12)) * 100).round();
    final busy = _store.busy;

    final cards = [
      _PlanCard(
        title: 'Tahunan',
        price: _rupiah(yearly),
        period: '/ tahun',
        note: '≈ ${_rupiah(yearly / 12)} / bulan',
        badge: 'Hemat $savePercent%',
        selected: _selected == PremiumPlan.yearly,
        onTap: busy ? null : () => setState(() => _selected = PremiumPlan.yearly),
      ),
      _PlanCard(
        title: 'Bulanan',
        price: _rupiah(monthly),
        period: '/ bulan',
        note: 'Fleksibel, bisa berhenti kapan saja',
        selected: _selected == PremiumPlan.monthly,
        onTap: busy ? null : () => setState(() => _selected = PremiumPlan.monthly),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 24),
        const _Benefit(Icons.school_rounded, 'Semua unit Belajar',
            'Lanjut dari huruf vokal ke konsonan, suku kata, dan seterusnya.'),
        const _Benefit(Icons.auto_stories_rounded, 'Semua dongeng',
            'Puluhan dongeng Nusantara dan dunia, ditambah cerita baru secara rutin.'),
        const _Benefit(Icons.devices_rounded, 'Satu akun, semua perangkat',
            'Masuk dengan akun Bebaca yang sama di HP atau tablet lain.'),
        const _Benefit(Icons.verified_user_rounded, 'Aman untuk anak',
            'Tanpa iklan. Kontrol orang tua tetap gratis untuk semua.'),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 480) {
            return Column(children: [
              for (final card in cards)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: card),
            ]);
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Langganan Sekarang',
          isLoading: busy,
          onPressed: busy ? null : () => _store.activate(_selected),
          height: 60,
          fontSize: 24,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset('assets/images/logo_icon.png',
              width: 110, height: 110, fit: BoxFit.cover),
        ),
        const SizedBox(height: 14),
        Text(
          'Bebaca Premium',
          textAlign: TextAlign.center,
          style: GoogleFonts.itim(
              fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Buka semua pelajaran dan dongeng untuk si kecil',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Benefit(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 16, color: AppColors.hint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String note;
  final String? badge;
  final bool selected;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.note,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFDDE6EE),
              width: selected ? 3 : 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? AppColors.primary : AppColors.hint,
                  ),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB81C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge!,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(TextSpan(children: [
                TextSpan(
                  text: price,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                TextSpan(
                  text: ' $period',
                  style: const TextStyle(fontSize: 18, color: AppColors.hint),
                ),
              ])),
              const SizedBox(height: 4),
              Text(note, style: const TextStyle(fontSize: 15, color: AppColors.hint)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Penanda bahwa ini masih uji coba, supaya tidak dikira pembayaran sungguhan.
class _SimulationNote extends StatelessWidget {
  const _SimulationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Mode uji coba: belum ada pembayaran sungguhan. '
        '"Langganan Sekarang" langsung mengaktifkan Premium, '
        '"Pulihkan pembelian" mengembalikan akun ke Gratis.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Color(0xFF7A5A00)),
      ),
    );
  }
}

class _ActiveView extends StatelessWidget {
  final SubscriptionStatus status;
  const _ActiveView({required this.status});

  @override
  Widget build(BuildContext context) {
    final plan = status.plan == PremiumPlan.yearly ? 'Tahunan' : 'Bulanan';
    final date = status.expiresAt == null
        ? '-'
        : SubscriptionStatus.formatDate(status.expiresAt!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFB81C), width: 3),
          ),
          child: Column(
            children: [
              const Text('⭐ Premium aktif ⭐',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text('Semua pelajaran dan dongeng sudah terbuka. Selamat belajar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.hint)),
              const Divider(height: 32),
              _row('Paket', plan),
              _row(status.autoRenew ? 'Diperpanjang pada' : 'Berlaku sampai', date),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 18, color: AppColors.hint))),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ],
        ),
      );
}
