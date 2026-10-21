import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/app_settings.dart';
import '../../models/subscription.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/event_logger.dart';
import '../../services/premium_store.dart';
import '../../services/settings_store.dart';
import '../../services/sound_service.dart';
import '../parent/monitor_page.dart';
import '../parent/parent_report_page.dart';
import '../premium/premium_prompt.dart';
import 'parental_gate.dart';

/// Semua pengaturan di sini BERLAKU langsung di aplikasi:
///  - Sound Effect       : semua efek suara + suara otomatis (perintah & huruf dibacakan)
///  - Animation          : animasi lesson, jalur lesson, splash, konfeti, maskot
///  - Listening Exercise : langkah "Dengar lalu pilih" di lesson & kuis
///  - Parental Control   : kunci layar saat batas waktu habis / sudah jam malam
/// Paling atas: kartu Bebaca Premium (dibuka lewat gerbang orang tua).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _store = SettingsStore.instance;
  bool _loading = !SettingsStore.instance.loaded;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _store.refresh();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          // sudah ada data (dari perangkat)? tetap tampilkan, tanpa error
          _error = _store.loaded ? null : e.message;
        });
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _update(AppSettings next) async {
    final soundTurnedOn = next.soundEffect && !_store.value.soundEffect;
    try {
      await _store.update(next); // gagal -> otomatis dikembalikan seperti semula
      if (soundTurnedOn) SoundService.instance.play(Sfx.correct); // contoh bunyinya
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  /// Saat Parental Control menyala, mengubahnya butuh PIN orang tua.
  Future<bool> _allowParentalChange() async {
    if (!_store.value.parentalControl) return true;
    return showParentalGate(context);
  }

  Future<void> _toggleParental(bool value) async {
    if (!value && !await _allowParentalChange()) return; // mematikan = harus orang tua
    await _update(_store.value.copyWith(parentalControl: value));
  }

  Future<void> _pickTimeLimit() async {
    if (!await _allowParentalChange()) return;
    if (!mounted) return;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Batas waktu belajar per hari'),
        children: [
          for (final m in [0, 15, 30, 45, 60, 90, 120])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Text(m == 0 ? 'Tanpa batas' : '$m menit',
                  style: const TextStyle(fontSize: 18)),
            ),
        ],
      ),
    );
    if (picked != null) await _update(_store.value.copyWith(timeLimitMinutes: picked));
  }

  Future<void> _pickCurfew() async {
    if (!await _allowParentalChange()) return;
    if (!mounted) return;
    final parts = _store.value.curfew.split(':');
    final t = await showTimePicker(
      context: context,
      helpText: 'Jam malam (terkunci sampai 05:00)',
      initialTime: TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 20,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0),
    );
    if (t != null) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      await _update(_store.value.copyWith(curfew: '$hh:$mm'));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    EventLogger.instance.clear();
    await AuthService().logout();
    PremiumStore.instance.reset();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.landing, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => _content(_store.value),
    );
  }

  Widget _content(AppSettings s) {
    final remaining = _store.remainingMinutes;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PremiumCard(),
          const SizedBox(height: 16),
          const _ParentTools(),
          const SizedBox(height: 28),
          const Text('Preferences',
              style: TextStyle(
                  fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 28),
          const _SectionTitle('Lesson Experience'),
          const Divider(height: 8, thickness: 1.5, color: Colors.black87),
          _SwitchRow(
            label: 'Sound Effect',
            subtitle: 'Efek suara, serta perintah dan huruf yang dibacakan otomatis',
            value: s.soundEffect,
            onChanged: (v) => _update(s.copyWith(soundEffect: v)),
          ),
          _SwitchRow(
            label: 'Animation',
            subtitle: 'Animasi lesson, maskot, konfeti, dan splash screen',
            value: s.animation,
            onChanged: (v) => _update(s.copyWith(animation: v)),
          ),
          _SwitchRow(
            label: 'Listening Exercise',
            subtitle: 'Latihan "dengar lalu pilih huruf" di lesson dan kuis',
            value: s.listeningExercise,
            onChanged: (v) => _update(s.copyWith(listeningExercise: v)),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(child: _SectionTitle('Parental Control')),
              Switch(value: s.parentalControl, onChanged: _toggleParental),
            ],
          ),
          const Divider(height: 8, thickness: 1.5, color: Colors.black87),
          _ParentalPanel(
            enabled: s.parentalControl,
            timespent: '${s.timespentMinutes} menit',
            timeLimit: s.timeLimitMinutes == 0 ? 'Tanpa batas' : '${s.timeLimitMinutes} menit',
            curfew: s.curfew,
            onTimeLimitTap: _pickTimeLimit,
            onCurfewTap: _pickCurfew,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Text(
              s.parentalControl
                  ? [
                      if (remaining >= 0) 'Sisa waktu belajar hari ini: $remaining menit.',
                      'Aplikasi terkunci mulai pukul ${s.curfew} sampai 05:00. '
                          'Mengubah pengaturan ini butuh PIN orang tua.',
                    ].join('\n')
                  : 'Saat menyala: aplikasi terkunci bila batas waktu belajar habis atau sudah lewat jam malam.',
              style: const TextStyle(fontSize: 16, color: Color(0xFF777777)),
            ),
          ),
          const SizedBox(height: 20),
          _PinRow(hasPin: s.hasParentPin),
          const SizedBox(height: 40),
          Center(
            child: PrimaryButton(
              label: 'Logout',
              onPressed: _logout,
              width: 320,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu Bebaca Premium di atas halaman Settings.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    final store = PremiumStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final s = store.status;
        final title = s.isPremium ? 'Bebaca Premium aktif' : 'Bebaca Premium';
        final subtitle = s.isPremium
            ? (s.expiresAt == null
                ? 'Semua pelajaran dan dongeng terbuka'
                : '${s.autoRenew ? 'Diperpanjang' : 'Berlaku sampai'} '
                    '${SubscriptionStatus.formatDate(s.expiresAt!)}')
            : 'Buka semua unit Belajar dan semua dongeng. Paket bulanan atau tahunan.';

        return Material(
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFC93C), Color(0xFFFFA41B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: InkWell(
              onTap: () => openPremium(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.star_rounded,
                          size: 46, color: Color(0xFFFFA41B)),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 16, color: Color(0xFF5A3A00))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(s.isPremium ? 'Kelola' : 'Lihat Paket',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE08A00))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Untuk Orang Tua: Laporan Perkembangan & Pantau Langsung (QR). Dibuka lewat PIN.
class _ParentTools extends StatelessWidget {
  const _ParentTools();

  Future<void> _open(BuildContext context, Widget page) async {
    if (!await showParentalGate(context)) return;
    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color color, String title, String subtitle, Widget page) => Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _open(context, page),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                      Text(subtitle, style: const TextStyle(fontSize: 15, color: Color(0xFF888888))),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 30, color: Color(0xFFAAAAAA)),
                ]),
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Untuk Orang Tua',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 10),
        Row(children: [
          tile(Icons.insights_rounded, const Color(0xFF2E7FB8), 'Laporan Perkembangan',
              'Waktu belajar, huruf yang dikuasai, saran', const ParentReportPage()),
          const SizedBox(width: 14),
          tile(Icons.qr_code_2_rounded, const Color(0xFF2E9E5B), 'Pantau Langsung',
              'Scan QR, lihat si kecil belajar dari HP Ayah/Ibu', const MonitorPage()),
        ]),
      ],
    );
  }
}

/// PIN orang tua: dipakai untuk Parental Control, layar terkunci, dan Bebaca Premium.
class _PinRow extends StatelessWidget {
  final bool hasPin;
  const _PinRow({required this.hasPin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lock_rounded, size: 32, color: Color(0xFF333333)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PIN Orang Tua',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              Text(
                hasPin
                    ? 'Sudah dibuat. Dipakai untuk pengaturan orang tua dan Premium.'
                    : 'Belum dibuat. Buat PIN 4 angka agar anak tidak bisa mengubah pengaturan.',
                style: const TextStyle(fontSize: 15, color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => showSetParentPin(context, firstTime: !hasPin),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(hasPin ? 'Ganti PIN' : 'Buat PIN', style: const TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF333333)));
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333))),
                Text(subtitle,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF888888))),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ParentalPanel extends StatelessWidget {
  final bool enabled;
  final String timespent;
  final String timeLimit;
  final String curfew;
  final VoidCallback onTimeLimitTap;
  final VoidCallback onCurfewTap;

  const _ParentalPanel({
    required this.enabled,
    required this.timespent,
    required this.timeLimit,
    required this.curfew,
    required this.onTimeLimitTap,
    required this.onCurfewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      // Abu gelap saat nonaktif (sesuai desain), terang saat aktif.
      color: enabled ? const Color(0xFFF1F1F1) : const Color(0xFF808080),
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          children: [
            _ValueRow(label: 'Timespent', value: timespent),
            _ValueRow(label: 'Time Limit', value: timeLimit, onTap: onTimeLimitTap),
            _ValueRow(label: 'Curfew', value: curfew, onTap: onCurfewTap),
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _ValueRow({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222))),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 280,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(value,
                  style: const TextStyle(fontSize: 22, color: AppColors.textDark)),
            ),
          ),
        ],
      ),
    );
  }
}
