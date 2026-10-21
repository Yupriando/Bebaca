import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/report.dart';
import '../../services/api_client.dart';
import '../../services/report_service.dart';
import '../premium/premium_page.dart';
import 'monitor_page.dart';

/// Laporan Perkembangan anak (khusus orang tua, dibuka lewat PIN).
/// Gratis: ringkasan minggu ini + aktivitas terbaru.
/// Premium: + grafik waktu belajar harian, penguasaan huruf, saran.
class ParentReportPage extends StatefulWidget {
  const ParentReportPage({super.key});

  @override
  State<ParentReportPage> createState() => _ParentReportPageState();
}

class _ParentReportPageState extends State<ParentReportPage> {
  final _service = ReportService();
  int _week = 0;
  ParentReport? _report;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.getReport(week: _week);
      if (mounted) setState(() => _report = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeWeek(int delta) {
    final next = (_week + delta).clamp(0, 52);
    if (next == _week) return;
    _week = next;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  PrimaryButton(
                    label: 'Back',
                    onPressed: () => Navigator.pop(context),
                    width: 100,
                    height: 44,
                    fontSize: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Laporan Perkembangan',
                        style: GoogleFonts.itim(
                            fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MonitorPage())),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Pantau Langsung'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: r == null
                  ? Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(_error ?? 'Laporan belum tersedia'),
                              TextButton(onPressed: _load, child: const Text('Coba lagi')),
                            ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 900),
                              child: Opacity(
                                opacity: _loading ? 0.5 : 1,
                                child: _content(r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ParentReport r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(r),
        const SizedBox(height: 14),
        _SummaryTiles(s: r.summary),
        const SizedBox(height: 14),
        if (r.detailed) ...[
          _Card(
            title: 'Waktu belajar per hari (menit)',
            child: _MinutesChart(days: r.days),
          ),
          _Card(title: 'Penguasaan huruf (30 hari terakhir)', child: _Letters(letters: r.letters)),
          _Card(
            title: '💡 Saran untuk Ayah/Ibu',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in r.suggestions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('•  ', style: TextStyle(fontSize: 18)),
                      Expanded(
                          child: Text(s,
                              style: const TextStyle(fontSize: 18, color: AppColors.textDark, height: 1.35))),
                    ]),
                  ),
              ],
            ),
          ),
        ] else
          _PremiumTeaser(onOpen: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PremiumPage()));
            _load();
          }),
        _Card(
          title: 'Aktivitas terbaru',
          child: r.recent.isEmpty
              ? const Text('Belum ada aktivitas. Ajak si kecil membuka Belajar atau Dongeng!',
                  style: TextStyle(fontSize: 17, color: AppColors.hint))
              : Column(children: [
                  for (final a in r.recent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        SizedBox(width: 32, child: Text(a.icon, style: const TextStyle(fontSize: 20))),
                        Expanded(
                            child: Text(a.text,
                                style: const TextStyle(fontSize: 17, color: AppColors.textDark))),
                        Text(_when(a.at), style: const TextStyle(fontSize: 14, color: AppColors.hint)),
                      ]),
                    ),
                ]),
        ),
      ],
    );
  }

  Widget _header(ParentReport r) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          backgroundImage: r.avatarUrl != null ? NetworkImage(r.avatarUrl!) : null,
          child: r.avatarUrl == null
              ? const Icon(Icons.child_care_rounded, size: 34, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.childName,
                  style: GoogleFonts.itim(
                      fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text(_range(r.weekFrom, r.weekTo),
                  style: const TextStyle(fontSize: 16, color: AppColors.hint)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Minggu sebelumnya',
          onPressed: _loading ? null : () => _changeWeek(1),
          icon: const Icon(Icons.chevron_left_rounded, size: 34),
        ),
        Text(_week == 0 ? 'Minggu ini' : _week == 1 ? 'Minggu lalu' : '$_week minggu lalu',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(
          tooltip: 'Minggu berikutnya',
          onPressed: _loading || _week == 0 ? null : () => _changeWeek(-1),
          icon: const Icon(Icons.chevron_right_rounded, size: 34),
        ),
      ],
    );
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  static String _range(String from, String to) {
    final a = DateTime.parse(from), b = DateTime.parse(to);
    return a.month == b.month
        ? '${a.day}–${b.day} ${_months[b.month - 1]} ${b.year}'
        : '${a.day} ${_months[a.month - 1]} – ${b.day} ${_months[b.month - 1]} ${b.year}';
  }

  static String _when(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final hm = '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
    if (t.year == now.year && t.month == now.month && t.day == now.day) return 'hari ini $hm';
    final y = now.subtract(const Duration(days: 1));
    if (t.year == y.year && t.month == y.month && t.day == y.day) return 'kemarin $hm';
    return '${t.day} ${_months[t.month - 1]} $hm';
  }
}

// ------------------------------------------------------------------ bagian-bagian

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.itim(
                    fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _SummaryTiles extends StatelessWidget {
  final ReportSummary s;
  const _SummaryTiles({required this.s});

  @override
  Widget build(BuildContext context) {
    final diff = s.minutes - s.prevMinutes;
    final tiles = <(String, String, String?)>[
      ('⏱ Waktu belajar', '${s.minutes} menit',
          s.prevMinutes == 0 && s.minutes == 0
              ? null
              : diff == 0
                  ? 'sama dengan minggu lalu'
                  : '${diff > 0 ? '▲' : '▼'} ${diff.abs()} mnt dari minggu lalu'),
      ('📅 Hari belajar', '${s.activeDays} / 7 hari', null),
      ('🔥 Hari beruntun', '${s.streak} hari', null),
      ('🏆 Lesson selesai', '${s.lessonsCompleted}',
          s.lessonsCompleted > 0 ? 'rata-rata ${s.avgStars.toStringAsFixed(1)} ⭐' : null),
      ('✅ Jawaban benar', s.answers == 0 ? '-' : '${s.accuracy}%',
          s.answers == 0 ? null : 'dari ${s.answers} jawaban'),
      ('📖 Dongeng selesai', '${s.storiesRead}',
          s.storiesOpened > s.storiesRead ? '${s.storiesOpened} dibuka' : null),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 3 : 2;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final t in tiles)
            Container(
              width: w,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.$1, style: const TextStyle(fontSize: 15, color: AppColors.hint)),
                const SizedBox(height: 4),
                Text(t.$2,
                    style: GoogleFonts.itim(
                        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                if (t.$3 != null)
                  Text(t.$3!, style: const TextStyle(fontSize: 13, color: AppColors.hint)),
              ]),
            ),
        ],
      );
    });
  }
}

/// Grafik batang waktu belajar Senin–Minggu. Satu seri -> tanpa legenda (judul menamainya).
/// Angka hanya ditulis pada hari tertinggi; hari lain lewat tooltip (ketuk batang).
class _MinutesChart extends StatelessWidget {
  final List<ReportDay> days;
  const _MinutesChart({required this.days});

  static const _bar = Color(0xFF2E7FB8); // kontras >= 3:1 di latar putih (dicek validator)
  static const _grid = Color(0xFFE6ECF1);

  @override
  Widget build(BuildContext context) {
    final maxMin = days.fold<int>(0, (m, d) => d.minutes > m ? d.minutes : m);
    if (maxMin == 0) {
      return const Text('Belum ada waktu belajar minggu ini.',
          style: TextStyle(fontSize: 17, color: AppColors.hint));
    }
    final peak = days.indexWhere((d) => d.minutes == maxMin);
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                message: '${days[i].label}: ${days[i].minutes} menit',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (i == peak)
                      Text('${days[i].minutes} mnt',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: days[i].minutes == 0 ? 2 : 4 + 126 * days[i].minutes / maxMin,
                      decoration: BoxDecoration(
                        color: days[i].minutes == 0 ? _grid : _bar,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    Container(height: 1, color: const Color(0xFFCFD8DC)),
                    const SizedBox(height: 6),
                    Text(days[i].label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: days[i].date == todayStr ? FontWeight.bold : FontWeight.normal,
                            color: days[i].date == todayStr ? AppColors.textDark : AppColors.hint)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Letters extends StatelessWidget {
  final List<LetterMastery> letters;
  const _Letters({required this.letters});

  // warna status selalu disertai ikon + tulisan (tidak hanya warna)
  static const _style = {
    MasteryStatus.mastered: (Color(0xFFE3F5EA), Color(0xFF1E7A43), Icons.check_circle_rounded, 'Dikuasai'),
    MasteryStatus.learning: (Color(0xFFFFF4D6), Color(0xFF8A5A00), Icons.hourglass_bottom_rounded, 'Sedang belajar'),
    MasteryStatus.practice: (Color(0xFFFDE4E1), Color(0xFFB3261E), Icons.warning_rounded, 'Perlu latihan'),
  };

  @override
  Widget build(BuildContext context) {
    if (letters.isEmpty) {
      return const Text(
          'Data huruf akan muncul setelah si kecil mengerjakan beberapa lesson.',
          style: TextStyle(fontSize: 17, color: AppColors.hint));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final l in letters)
              Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                message: '${l.accuracy}% benar dari ${l.total} jawaban'
                    '${l.confusedWith != null ? '\nSering tertukar dengan ${l.confusedWith}' : ''}',
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                  decoration: BoxDecoration(
                    color: _style[l.status]!.$1,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_style[l.status]!.$3, size: 20, color: _style[l.status]!.$2),
                    const SizedBox(width: 6),
                    Text(l.letter,
                        style: GoogleFonts.itim(
                            fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    Text('${l.accuracy}%',
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                    if (l.confusedWith != null)
                      Text('  ↔ ${l.confusedWith}',
                          style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 4, children: [
          for (final e in _style.values)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(e.$3, size: 18, color: e.$2),
              const SizedBox(width: 4),
              Text(e.$4, style: const TextStyle(fontSize: 14, color: AppColors.hint)),
            ]),
          const Text('↔ = sering tertukar dengan', style: TextStyle(fontSize: 14, color: AppColors.hint)),
        ]),
      ],
    );
  }
}

class _PremiumTeaser extends StatelessWidget {
  final VoidCallback onOpen;
  const _PremiumTeaser({required this.onOpen});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB81C), width: 2),
        ),
        child: Row(children: [
          const Icon(Icons.lock_rounded, size: 40, color: Color(0xFFE08A00)),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Grafik waktu belajar harian, huruf yang sudah dikuasai & perlu latihan, '
              'serta saran untuk Ayah/Ibu tersedia di Bebaca Premium.',
              style: TextStyle(fontSize: 17, color: AppColors.textDark, height: 1.35),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(onPressed: onOpen, child: const Text('Lihat Premium')),
        ]),
      );
}
