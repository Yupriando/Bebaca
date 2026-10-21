import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/app_settings.dart';
import '../../models/lesson.dart';
import '../../services/api_client.dart';
import '../../services/lesson_service.dart';
import '../../services/settings_store.dart';
import '../../services/sound_service.dart';
import '../../services/speech_service.dart';
import 'lesson_result_view.dart';
import 'lesson_steps.dart';
import 'steps/find_step.dart';
import 'steps/intro_step.dart';
import 'steps/listen_pick_step.dart';
import 'steps/read_step.dart';
import 'steps/trace_step.dart';
import 'widgets/mascot.dart';
import 'widgets/step_common.dart';

/// Halaman belajar satu lesson. Ditutup dengan hasil `true` jika lesson
/// berhasil disimpan ke backend (supaya daftar lesson dimuat ulang).
class LessonPage extends StatefulWidget {
  final LessonSection section;
  final Lesson lesson;

  const LessonPage({super.key, required this.section, required this.lesson});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  final _lessonService = LessonService();

  AppSettings? _settings;
  List<LessonStep> _steps = const [];
  int _index = 0;
  bool _stepDone = false;
  int _mistakes = 0;

  MascotMood _mood = MascotMood.idle;
  int _moodToken = 0;

  bool _finished = false;
  bool _saving = false;
  bool _saved = false;
  String? _saveError;
  int _stars = 3;
  int? _streak;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    SpeechService.instance.stopSpeaking();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await SettingsStore.instance.refresh();
    } catch (_) {
      // gagal: pakai pengaturan terakhir yang tersimpan
    }
    final settings = SettingsStore.instance.value;
    if (!mounted) return;

    // Huruf pengecoh diambil dari seluruh huruf di section ini (mis. semua vokal).
    final pool = widget.section.lessons
        .expand((l) => l.letters)
        .map((e) => e.toUpperCase())
        .toSet()
        .toList();

    setState(() {
      _settings = settings;
      _steps = buildSteps(
        widget.lesson,
        listening: settings.listeningExercise,
        pool: pool,
      );
    });
  }

  /// Maskot bereaksi sebentar, lalu kembali santai.
  void _react(MascotMood mood) {
    final token = ++_moodToken;
    setState(() => _mood = mood);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted && token == _moodToken) setState(() => _mood = MascotMood.idle);
    });
  }

  // ---- callback dari langkah (index dicek agar callback telat tidak salah sasaran)
  void _onStepDone(int index) {
    if (index != _index || _stepDone) return;
    setState(() => _stepDone = true);
    if (_steps[index].type != LessonStepType.intro) _react(MascotMood.cheer);
  }

  void _onCorrect(int index) {
    if (index != _index) return;
    _react(MascotMood.cheer);
  }

  void _onMistake(int index) {
    if (index != _index) return;
    _mistakes++;
    _react(MascotMood.sad);
  }

  void _onNext() {
    if (_settings!.soundEffect) SoundService.instance.play(Sfx.next, volume: 0.6);
    if (_index >= _steps.length - 1) {
      _finish();
    } else {
      setState(() {
        _index++;
        _stepDone = false;
        _mood = MascotMood.idle;
      });
    }
  }

  void _finish() {
    // 0 salah = 3 bintang, 1-2 salah = 2 bintang, selebihnya 1 bintang
    final stars = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
    setState(() {
      _finished = true;
      _stars = stars;
    });
    _save();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final streak =
          await _lessonService.completeLesson(widget.lesson.id, stars: _stars);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
        _streak = streak;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = e.message;
      });
    }
  }

  Future<void> _requestExit() async {
    if (_finished) {
      Navigator.pop(context, _saved);
      return;
    }
    SpeechService.instance.stopSpeaking();
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => _ExitDialog(
        done: _index + (_stepDone ? 1 : 0),
        total: _steps.length,
        animate: _settings?.animation ?? true,
      ),
    );
    if (leave == true && mounted) Navigator.pop(context, false);
  }

  Widget _buildStep(LessonStep step, int index) {
    final env = StepEnv(
      sound: _settings!.soundEffect,
      animate: _settings!.animation,
      onDone: () => _onStepDone(index),
      onMistake: () => _onMistake(index),
      onCorrect: () => _onCorrect(index),
    );
    switch (step.type) {
      case LessonStepType.intro:
        return IntroStep(step: step, env: env);
      case LessonStepType.find:
        return FindStep(step: step, env: env);
      case LessonStepType.listenPick:
        return ListenPickStep(step: step, env: env);
      case LessonStepType.traceUpper:
        return TraceStep(step: step, env: env, upper: true);
      case LessonStepType.traceLower:
        return TraceStep(step: step, env: env, upper: false);
      case LessonStepType.read:
        return ReadStep(step: step, env: env);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _settings == null
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lesson ini belum tersedia.',
                style: TextStyle(fontSize: 22)),
            const SizedBox(height: 16),
            PrimaryButton(
                label: 'Kembali',
                onPressed: () => Navigator.pop(context, false),
                width: 180),
          ],
        ),
      );
    }

    final animate = _settings!.animation;

    if (_finished) {
      return LessonResultView(
        stars: _stars,
        streak: _streak,
        saving: _saving,
        error: _saveError,
        animate: animate,
        onRetry: _save,
        onClose: () => Navigator.pop(context, _saved),
      );
    }

    final isLast = _index == _steps.length - 1;
    final progress = (_index + (_stepDone ? 1 : 0)) / _steps.length;

    return Column(
      children: [
        _LessonHeader(
          section: widget.section,
          lesson: widget.lesson,
          nextLabel: isLast ? 'Complete' : 'Next',
          nextEnabled: _stepDone,
          animate: animate,
          onNext: _onNext,
          onClose: _requestExit,
        ),
        _ProgressWithMascot(
          progress: progress,
          mood: _mood,
          animate: animate,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: animate ? 320 : 0),
            // langkah baru masuk dari kanan, langkah lama keluar ke kiri
            transitionBuilder: (child, anim) {
              final incoming = child.key == ValueKey(_index);
              final slide = Tween<Offset>(
                begin: Offset(incoming ? 0.18 : -0.18, 0),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: Padding(
              key: ValueKey(_index),
              padding: const EdgeInsets.all(16),
              child: _buildStep(_steps[_index], _index),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bar progres; maskot "berjalan" di atasnya mengikuti kemajuan.
class _ProgressWithMascot extends StatelessWidget {
  final double progress;
  final MascotMood mood;
  final bool animate;
  const _ProgressWithMascot({
    required this.progress,
    required this.mood,
    required this.animate,
  });

  static const _mascotSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 58,
        child: LayoutBuilder(
          builder: (context, box) {
            final maxLeft = box.maxWidth - _mascotSize;
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: Duration(milliseconds: animate ? 500 : 0),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE6E6E6),
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                  ),
                  Positioned(
                    left: v * maxLeft,
                    bottom: 12,
                    child: Mascot(mood: mood, size: _mascotSize, animate: animate),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  final LessonSection section;
  final Lesson lesson;
  final String nextLabel;
  final bool nextEnabled;
  final bool animate;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const _LessonHeader({
    required this.section,
    required this.lesson,
    required this.nextLabel,
    required this.nextEnabled,
    required this.animate,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unit ${section.unit}, Section ${section.section}',
                    style: white.copyWith(fontSize: 18)),
                Text(lesson.title, style: white.copyWith(fontSize: 22)),
              ],
            ),
          ),
          _NextButton(
            label: nextLabel,
            enabled: nextEnabled,
            animate: animate,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// Tombol Next: berdenyut pelan saat sudah boleh ditekan (mengajak anak lanjut).
class _NextButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final bool animate;
  final VoidCallback onPressed;
  const _NextButton({
    required this.label,
    required this.enabled,
    required this.animate,
    required this.onPressed,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.09)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _NextButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.enabled && widget.animate) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return ScaleTransition(
      scale: _scale,
      child: OutlinedButton(
        onPressed: enabled ? widget.onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          backgroundColor: enabled ? Colors.white24 : Colors.transparent,
          side: BorderSide(color: enabled ? Colors.white : Colors.white38, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(widget.label, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

/// Konfirmasi keluar yang ramah anak: maskot sedih, progres yang sudah dicapai,
/// dan tombol "Lanjut Belajar" yang paling menonjol (supaya anak terdorong lanjut).
class _ExitDialog extends StatelessWidget {
  final int done;
  final int total;
  final bool animate;
  const _ExitDialog({required this.done, required this.total, required this.animate});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final left = (total - done).clamp(0, total);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Mascot(mood: MascotMood.sad, size: 96, animate: animate),
              const SizedBox(height: 14),
              Text(
                'Yakin mau berhenti?',
                textAlign: TextAlign.center,
                style: GoogleFonts.itim(
                    fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                left <= 1
                    ? 'Sedikit lagi selesai! Kalau keluar sekarang, bintangmu belum tersimpan.'
                    : 'Tinggal $left langkah lagi. Kalau keluar sekarang, bintangmu belum tersimpan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.itim(fontSize: 19, color: AppColors.hint, height: 1.3),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14,
                        backgroundColor: const Color(0xFFE6E6E6),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$done/$total',
                      style: GoogleFonts.itim(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Lanjut Belajar',
                onPressed: () => Navigator.pop(context, false),
                height: 58,
                fontSize: 24,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: Text('Keluar',
                    style: GoogleFonts.itim(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
