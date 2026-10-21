import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../services/api_client.dart';
import '../../services/report_service.dart';

/// Pantau Langsung: QR yang di-scan HP orang tua -> halaman web yang menampilkan
/// apa yang sedang dipelajari anak, diperbarui otomatis (tanpa memasang aplikasi).
/// Yang dikirim hanya aktivitas belajar, bukan isi layar / foto / suara anak.
class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  static const _prefKey = 'monitor_url';
  final _service = ReportService();
  String? _url;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final active = await _service.monitorActive();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (!active) await prefs.remove(_prefKey);
      if (mounted) setState(() => _url = active ? saved : null);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = await _service.createMonitorLink();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, url);
      if (mounted) setState(() => _url = url);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _revoke() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Matikan Pantau Langsung?'),
        content: const Text('Semua HP yang pernah scan QR ini tidak bisa memantau lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Matikan', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await _service.revokeMonitorLink();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      if (mounted) setState(() => _url = null);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                PrimaryButton(
                  label: 'Back',
                  onPressed: () => Navigator.pop(context),
                  width: 100,
                  height: 44,
                  fontSize: 20,
                ),
                const SizedBox(width: 16),
                Text('Pantau Langsung',
                    style: GoogleFonts.itim(
                        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: _url == null ? _intro() : _qr(_url!),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _steps() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Step('1', 'Buka kamera di HP Ayah/Ibu, arahkan ke QR.'),
          _Step('2', 'Ketuk tautan yang muncul. Halaman pantau terbuka di browser, tanpa memasang aplikasi.'),
          _Step('3', 'Lihat langsung: sedang belajar apa, jawaban benar/salah, waktu belajar hari ini.'),
        ],
      );

  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.phonelink_ring_rounded, size: 80, color: AppColors.primary),
        const SizedBox(height: 12),
        Text('Pantau si kecil belajar dari HP Ayah/Ibu',
            textAlign: TextAlign.center,
            style: GoogleFonts.itim(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        _steps(),
        const SizedBox(height: 12),
        const _PrivacyNote(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
          ),
        const SizedBox(height: 20),
        Center(child: PrimaryButton(label: 'Buat QR', onPressed: _create, width: 280, height: 56)),
      ],
    );
  }

  Widget _qr(String url) {
    final qr = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: QrImageView(data: url, size: 260, backgroundColor: Colors.white),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scan dengan HP Ayah/Ibu',
            style: GoogleFonts.itim(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 12),
        _steps(),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.hint)),
          ),
          IconButton(
            tooltip: 'Salin tautan',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan disalin. Kirim ke HP orang tua.')));
            },
          ),
        ]),
        const _PrivacyNote(),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Ganti QR'),
          ),
          TextButton.icon(
            onPressed: _revoke,
            icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
            label: const Text('Matikan', style: TextStyle(color: Colors.redAccent)),
          ),
        ]),
        const SizedBox(height: 6),
        const Text('Ganti QR = HP yang memakai QR lama tidak bisa memantau lagi.',
            style: TextStyle(fontSize: 13, color: AppColors.hint)),
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 640) {
        return Column(children: [qr, const SizedBox(height: 20), info]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        qr,
        const SizedBox(width: 28),
        Expanded(child: info),
      ]);
    });
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step(this.n, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, color: AppColors.textDark))),
        ]),
      );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFE8F3FB), borderRadius: BorderRadius.circular(12)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.shield_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Yang terlihat hanya aktivitas belajar (mis. "Cari huruf B: benar"), '
              'bukan isi layar, foto, atau suara anak. Jangan bagikan QR ke orang lain.',
              style: TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
          ),
        ]),
      );
}
