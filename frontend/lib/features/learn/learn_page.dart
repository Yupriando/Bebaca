import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/async_body.dart';
import '../../core/widgets/sky_background.dart';
import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/lesson_service.dart';
import '../../services/profile_service.dart';
import '../../services/premium_store.dart';
import '../../services/settings_store.dart';
import '../../services/sound_service.dart';
import '../lesson/lesson_page.dart';
import '../premium/premium_prompt.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final _service = LessonService();
  late Future<List<LessonSection>> _future = _service.getSections();
  // nama & foto untuk kartu sapaan (gagal dimuat = sapaan umum)
  late Future<UserProfile?> _profile = _loadProfile();

  Future<UserProfile?> _loadProfile() async {
    try {
      return await ProfileService().getProfile();
    } catch (_) {
      return null;
    }
  }
  final _premium = PremiumStore.instance;
  late bool _wasPremium = _premium.isPremium;

  @override
  void initState() {
    super.initState();
    _premium.addListener(_onPremium);
  }

  @override
  void dispose() {
    _premium.removeListener(_onPremium);
    super.dispose();
  }

  // baru berlangganan / langganan habis -> muat ulang supaya gembok ikut berubah
  void _onPremium() {
    if (_premium.isPremium == _wasPremium) return;
    _wasPremium = _premium.isPremium;
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.getSections();
      _profile = _loadProfile(); // hari beruntun bisa bertambah
    });
  }

  Future<void> _openLesson(LessonSection section, Lesson lesson) async {
    if (section.premiumLocked) {
      await showPremiumPrompt(context, what: 'Pelajaran "${section.title}"');
      return;
    }
    // Navigator.of(context) = navigator milik tab Belajar (sidebar tetap tampil)
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonPage(section: section, lesson: lesson),
      ),
    );
    if (saved == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<List<LessonSection>>(
      future: _future,
      builder: (context, sections) {
        final stars = sections.expand((s) => s.lessons).fold<int>(0, (t, l) => t + l.stars);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FutureBuilder<UserProfile?>(
                      future: _profile,
                      builder: (context, snap) => _GreetingCard(profile: snap.data, stars: stars),
                    ),
                    const SizedBox(height: 18),
                    for (final section in sections) ...[
                      _SectionMap(
                        section: section,
                        onLessonTap: (lesson) => _openLesson(section, lesson),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Halo, Budi! 👋  Yuk, lanjut belajar hari ini!" + hari beruntun & total bintang.
class _GreetingCard extends StatelessWidget {
  final UserProfile? profile;
  final int stars;
  const _GreetingCard({required this.profile, required this.stars});

  @override
  Widget build(BuildContext context) {
    final name = profile?.nama.split(' ').first ?? 'Kakak';
    final avatar = profile?.avatarUrl;
    Widget chip(String icon, String text, Color bg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
          child: Text('$icon $text',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        );
    return SoftCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFE7B3),
            border: Border.all(color: AppColors.sun, width: 3),
            image: avatar != null ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null,
          ),
          child: avatar == null ? const Center(child: Text('🧒', style: TextStyle(fontSize: 34))) : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, $name! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            Text('Yuk, lanjut belajar hari ini!',
                style: GoogleFonts.fredoka(fontSize: 18, color: AppColors.hint)),
          ]),
        ),
        const SizedBox(width: 10),
        chip('🔥', '${profile?.hariBerturut ?? 0} hari', const Color(0xFFFFEDE0)),
        const SizedBox(width: 8),
        chip('⭐', '$stars', const Color(0xFFFFF4D1)),
      ]),
    );
  }
}

/// Satu section sebagai peta: rumput, pohon, jalan setapak berkelok, papan kayu unit.
class _SectionMap extends StatelessWidget {
  final LessonSection section;
  final ValueChanged<Lesson> onLessonTap;
  const _SectionMap({required this.section, required this.onLessonTap});

  static const _node = 78.0;
  static const _top = 150.0; // ruang untuk papan kayu
  static const _gap = 104.0;

  /// Posisi tengah node ke-i (berkelok kiri-kanan).
  static Offset center(int i, double w) => Offset(w / 2 + sin(i * 0.95) * w * 0.2, _top + i * _gap);

  @override
  Widget build(BuildContext context) {
    final n = section.lessons.length;
    final height = _top + (n - 1) * _gap + _node / 2 + 40;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final pts = [for (var i = 0; i < n; i++) center(i, w)];
        return SizedBox(
          height: height,
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter(pts))),
            Positioned(left: 18, top: 16, child: _Signpost(section: section)),
            for (var i = 0; i < n; i++)
              Positioned(
                left: pts[i].dx - _node / 2,
                top: pts[i].dy - _node / 2,
                child: _LessonNode(
                  lesson: section.lessons[i],
                  premiumLocked: section.premiumLocked,
                  size: _node,
                  onTap: () => onLessonTap(section.lessons[i]),
                ),
              ),
          ]),
        );
      }),
    );
  }
}

/// Latar peta: langit tipis di atas, rumput, pohon-pohon, jalan setapak krem bergaris putus-putus.
class _MapPainter extends CustomPainter {
  final List<Offset> pts;
  _MapPainter(this.pts);

  void _tree(Canvas c, Offset base, double s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: base.translate(0, -s * 0.35), width: s * 0.22, height: s * 0.7),
          Radius.circular(s * 0.08)),
      Paint()..color = const Color(0xFF9A6A3A),
    );
    final leaf = Paint()..color = const Color(0xFF4CAF50);
    final light = Paint()..color = const Color(0xFF6CC56C);
    c.drawCircle(base.translate(0, -s * 0.95), s * 0.45, leaf);
    c.drawCircle(base.translate(-s * 0.32, -s * 0.72), s * 0.32, leaf);
    c.drawCircle(base.translate(s * 0.32, -s * 0.72), s * 0.32, leaf);
    c.drawCircle(base.translate(-s * 0.12, -s * 1.08), s * 0.18, light);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // rumput bergradasi
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC8EFB0), AppColors.grass, Color(0xFF76C65C)],
          stops: [0.0, 0.35, 1.0],
        ).createShader(Offset.zero & size),
    );
    // bukit lembut di belakang
    final hill = Path()
      ..moveTo(0, 120)
      ..quadraticBezierTo(w * 0.3, 60, w * 0.6, 110)
      ..quadraticBezierTo(w * 0.85, 150, w, 95)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFFDDF4CF));

    // jalan setapak melalui semua node
    if (pts.isNotEmpty) {
      final road = Path()..moveTo(pts.first.dx, pts.first.dy - 60);
      road.lineTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        road.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
      }
      canvas.drawPath(road, Paint()
        ..color = const Color(0xFFE6CF98)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 48
        ..strokeCap = StrokeCap.round);
      canvas.drawPath(road, Paint()
        ..color = AppColors.path
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40
        ..strokeCap = StrokeCap.round);
      // garis putus-putus di tengah jalan
      final dash = Paint()
        ..color = Colors.white.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (final m in road.computeMetrics()) {
        for (double d = 0; d < m.length; d += 22) {
          canvas.drawPath(m.extractPath(d, min(d + 10, m.length)), dash);
        }
      }
    }

    // pohon di sisi yang tidak dilalui jalan
    for (var i = 0; i < pts.length; i++) {
      final side = pts[i].dx > w / 2 ? -1 : 1;
      final x = w / 2 + side * w * (0.34 + (i % 3) * 0.04);
      _tree(canvas, Offset(x, pts[i].dy + 30), 46 + (i % 2) * 10);
    }
    _tree(canvas, Offset(w - 46, 120), 52);
    _tree(canvas, Offset(w - 96, 132), 38);
    // semak kecil
    final bush = Paint()..color = const Color(0xFF5DB64A);
    for (var i = 0; i < pts.length; i += 2) {
      final x = i.isEven ? w * 0.12 : w * 0.88;
      canvas.drawCircle(Offset(x, pts[i].dy + 54), 12, bush);
      canvas.drawCircle(Offset(x + 14, pts[i].dy + 58), 9, bush);
    }
    // tepi bawah sedikit gelap
    canvas.drawRect(Rect.fromLTWH(0, h - 10, w, 10), Paint()..color = const Color(0x22000000));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.pts.length != pts.length || old.pts.first != pts.first;
}

/// Papan kayu: "Unit 1 / Huruf Vokal / ⭐ 2/8" + tombol panduan (dan gembok Premium).
class _Signpost extends StatelessWidget {
  final LessonSection section;
  const _Signpost({required this.section});

  @override
  Widget build(BuildContext context) {
    final done = section.lessons.where((l) => l.status == LessonStatus.completed).length;
    final ink = GoogleFonts.fredoka(color: const Color(0xFF4A2A0C), fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE2A866), AppColors.wood]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.woodDark, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Unit ${section.unit}${section.section > 1 ? ' · Bagian ${section.section}' : ''}',
                  style: ink.copyWith(fontSize: 17)),
              Text(section.title, style: ink.copyWith(fontSize: 24)),
              Text('⭐ $done/${section.lessons.length}', style: ink.copyWith(fontSize: 17)),
            ]),
            const SizedBox(width: 10),
            if (section.premiumLocked)
              const Padding(padding: EdgeInsets.only(right: 6), child: PremiumBadge())
            else
              IconButton(
                tooltip: 'Panduan',
                style: IconButton.styleFrom(backgroundColor: const Color(0x33FFFFFF)),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Panduan: ${section.title}'),
                    content: Text(section.guide ?? 'Panduan untuk ${section.title} segera hadir.',
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                icon: const Icon(Icons.lightbulb_rounded, color: Color(0xFF4A2A0C)),
              ),
          ]),
        ),
        // tiang papan
        Container(width: 12, height: 22, color: AppColors.woodDark),
      ],
    );
  }
}

class _LessonNode extends StatefulWidget {
  final Lesson lesson;
  final bool premiumLocked; // section premium, akun belum berlangganan
  final double size;
  final VoidCallback onTap;
  const _LessonNode({
    required this.lesson,
    required this.premiumLocked,
    required this.size,
    required this.onTap,
  });

  @override
  State<_LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<_LessonNode>
    with TickerProviderStateMixin {
  // cincin yang memancar = "ayo kerjakan yang ini!"
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  // goyang saat lesson terkunci diketuk
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _pressed = false;

  bool get _premium => widget.premiumLocked;
  bool get _locked => widget.lesson.status == LessonStatus.locked || _premium;
  bool get _current => widget.lesson.status == LessonStatus.unlocked && !_premium;

  bool get _animate => SettingsStore.instance.value.animation;

  @override
  void initState() {
    super.initState();
    SettingsStore.instance.addListener(_onSettings);
    _syncPulse();
  }

  void _syncPulse() {
    if (_current && _animate) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  void _onSettings() {
    _syncPulse();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _LessonNode old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  @override
  void dispose() {
    SettingsStore.instance.removeListener(_onSettings);
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  Color get _color {
    if (_premium) return const Color(0xFFCFD8DC);
    switch (widget.lesson.status) {
      case LessonStatus.locked:
        return const Color(0xFFCFD8DC);
      case LessonStatus.unlocked:
        return AppColors.primary;
      case LessonStatus.completed:
        return const Color(0xFFFFB300); // emas = sudah selesai
    }
  }

  /// Ikon sesuai jenis lesson (huruf = bintang).
  IconData get _icon {
    switch (widget.lesson.kind) {
      case LessonKind.letter:
        return Icons.star_rounded;
      case LessonKind.review:
        return Icons.edit_rounded;
      case LessonKind.quiz:
        return Icons.help_rounded;
      case LessonKind.challenge:
        return Icons.emoji_events_rounded;
    }
  }

  void _handleTap() {
    if (_premium) {
      SoundService.instance.play(Sfx.tap);
      widget.onTap(); // LearnPage menampilkan ajakan Premium
      return;
    }
    if (_locked) {
      SoundService.instance.play(Sfx.wrong, volume: 0.5);
      _shake.forward(from: 0);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Selesaikan lesson sebelumnya dulu ya'),
        ));
      return;
    }
    SoundService.instance.play(Sfx.tap);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final completed = widget.lesson.status == LessonStatus.completed;

    final node = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: _locked ? const Color(0xFF90A4AE) : Color.lerp(_color, Colors.black, 0.3)!,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_locked ? Icons.lock_rounded : _icon,
              color: _locked ? const Color(0xFF78909C) : Colors.white,
              size: completed ? size * 0.42 : size * 0.5),
          if (completed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: i < widget.lesson.stars ? Colors.white : Colors.white38,
                  ),
              ],
            ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shake]),
      builder: (context, child) {
        final dx = sin(_shake.value * pi * 6) * 8 * (1 - _shake.value);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_current && _animate)
                  Positioned.fill(
                    child: Center(
                      child: OverflowBox(
                        maxWidth: size * 2,
                        maxHeight: size * 2,
                        child: Container(
                          width: size * (1 + 0.5 * _pulse.value),
                          height: size * (1 + 0.5 * _pulse.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary
                                  .withAlpha(((1 - _pulse.value) * 170).round()),
                              width: 5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                child!,
                if (_premium)
                  const Positioned(right: -4, top: -4, child: PremiumBadge(compact: true)),
              ],
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: node,
        ),
      ),
    );
  }
}
