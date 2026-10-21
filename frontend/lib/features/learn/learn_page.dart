import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_body.dart';
import '../../models/lesson.dart';
import '../../services/lesson_service.dart';
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
      builder: (context, sections) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          for (final section in sections) ...[
            _SectionHeader(section: section),
            const SizedBox(height: 16),
            _LessonPath(
              lessons: section.lessons,
              premiumLocked: section.premiumLocked,
              onLessonTap: (lesson) => _openLesson(section, lesson),
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final LessonSection section;
  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unit ${section.unit}, Section ${section.section}',
                    style: white.copyWith(fontSize: 26)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(section.title,
                          style: white.copyWith(fontSize: 30)),
                    ),
                    if (section.premiumLocked) ...[
                      const SizedBox(width: 12),
                      const PremiumBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Panduan'),
                  content: Text(section.guide ??
                      'Panduan untuk ${section.title} segera hadir.'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2F7DB0), width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Panduan', style: white.copyWith(fontSize: 24)),
          ),
        ],
      ),
    );
  }
}

/// Jalur lesson berkelok: tengah -> kiri -> tengah -> kanan -> ...
class _LessonPath extends StatelessWidget {
  final List<Lesson> lessons;
  final bool premiumLocked;
  final ValueChanged<Lesson> onLessonTap;
  const _LessonPath({
    required this.lessons,
    required this.premiumLocked,
    required this.onLessonTap,
  });

  static const _size = 84.0;
  static const _pattern = [0, -1, 0, 1];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lessons.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Center(
              child: Transform.translate(
                offset: Offset(_pattern[i % _pattern.length] * _size, 0),
                child: _LessonNode(
                  lesson: lessons[i],
                  premiumLocked: premiumLocked,
                  size: _size,
                  onTap: () => onLessonTap(lessons[i]),
                ),
              ),
            ),
          ),
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
    if (_premium) return const Color(0xFFAFAFAF);
    switch (widget.lesson.status) {
      case LessonStatus.locked:
        return const Color(0xFFAFAFAF);
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
        boxShadow: _locked
            ? null
            : const [
                BoxShadow(
                    color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: Colors.white, size: completed ? size * 0.42 : size * 0.55),
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
