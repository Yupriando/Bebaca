import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/story.dart';
import '../../services/settings_store.dart';
import '../../services/sound_service.dart';
import '../../services/speech_service.dart';
import '../../services/story_service.dart';
import '../lesson/widgets/confetti.dart';
import '../lesson/widgets/mascot.dart';

/// Akhir Baca Bersama: pesan moral -> kuis mini -> bintang + konfeti.
/// Bintang: 3 jika kuis dijawab tanpa salah, berkurang 1 tiap salah (min. 1).
class StoryEndView extends StatefulWidget {
  final StoryDetail story;
  final int lastPage;
  final VoidCallback onReadAgain;
  const StoryEndView({
    super.key,
    required this.story,
    required this.lastPage,
    required this.onReadAgain,
  });

  @override
  State<StoryEndView> createState() => _StoryEndViewState();
}

enum _Stage { moral, quiz, result }

class _StoryEndViewState extends State<StoryEndView> {
  late _Stage _stage = widget.story.moral?.isNotEmpty == true
      ? _Stage.moral
      : widget.story.quiz.isNotEmpty
          ? _Stage.quiz
          : _Stage.result;
  int _q = 0;
  int _mistakes = 0;
  int? _picked; // jawaban yang dipilih pada soal sekarang
  bool _saved = false;

  bool get _animate => SettingsStore.instance.value.animation;

  @override
  void initState() {
    super.initState();
    if (_stage == _Stage.moral) {
      SpeechService.instance.speak('Pesan dari cerita ini. ${widget.story.moral}');
    }
    if (_stage == _Stage.result) _showResult();
  }

  int get _stars => widget.story.quiz.isEmpty ? 3 : max(1, 3 - _mistakes);

  void _next() {
    SpeechService.instance.stopSpeaking();
    if (_stage == _Stage.moral && widget.story.quiz.isNotEmpty) {
      setState(() => _stage = _Stage.quiz);
      _readQuestion();
    } else {
      _showResult();
    }
  }

  void _readQuestion() =>
      SpeechService.instance.speak(widget.story.quiz[_q].question);

  void _answer(int i) {
    if (_picked != null && _picked == widget.story.quiz[_q].answer) return;
    final correct = i == widget.story.quiz[_q].answer;
    setState(() => _picked = i);
    if (!correct) {
      _mistakes++;
      SoundService.instance.play(Sfx.wrong, volume: 0.5);
      return;
    }
    SoundService.instance.play(Sfx.correct);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_q + 1 < widget.story.quiz.length) {
        setState(() {
          _q++;
          _picked = null;
        });
        _readQuestion();
      } else {
        _showResult();
      }
    });
  }

  void _showResult() {
    if (_stage != _Stage.result) setState(() => _stage = _Stage.result);
    SoundService.instance.play(Sfx.fanfare);
    if (_saved) return;
    _saved = true;
    StoryService()
        .saveProgress(widget.story.id, page: widget.lastPage, completed: true, stars: _stars)
        .catchError((_) => null);
  }

  @override
  void dispose() {
    SpeechService.instance.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_stage) {
      _Stage.moral => _moral(),
      _Stage.quiz => _quiz(),
      _Stage.result => _result(),
    };
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(key: ValueKey('$_stage$_q'), child: content),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 8,
          child: IconButton(
            tooltip: 'Tutup',
            iconSize: 34,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
          ),
        ),
        if (_stage == _Stage.result && _animate)
          const Positioned.fill(child: IgnorePointer(child: ConfettiOverlay())),
      ],
    );
  }

  TextStyle _title(double size) =>
      GoogleFonts.itim(fontSize: size, fontWeight: FontWeight.bold, color: AppColors.textDark);

  Widget _moral() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Mascot(mood: MascotMood.idle, size: 110, animate: _animate),
        const SizedBox(height: 16),
        Text('Ceritanya selesai! 📖', style: _title(34), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFB300), width: 3),
          ),
          child: Column(
            children: [
              Text('💡 Pesan dari cerita ini', style: _title(24)),
              const SizedBox(height: 10),
              Text(widget.story.moral!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.itim(fontSize: 26, color: AppColors.textDark, height: 1.3)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: widget.story.quiz.isNotEmpty ? 'Ayo Jawab Kuis!' : 'Selesai',
          onPressed: _next,
          width: 320,
          height: 60,
          fontSize: 24,
        ),
      ],
    );
  }

  Widget _quiz() {
    final q = widget.story.quiz[_q];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Kuis ${_q + 1} dari ${widget.story.quiz.length}',
            style: GoogleFonts.itim(fontSize: 20, color: AppColors.hint)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(q.question, textAlign: TextAlign.center, style: _title(30))),
            IconButton(
              tooltip: 'Dengarkan',
              onPressed: _readQuestion,
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 32),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < q.options.length; i++) ...[
          _option(i, q),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _option(int i, QuizQuestion q) {
    final picked = _picked == i;
    final correct = i == q.answer;
    final color = !picked
        ? Colors.white
        : correct
            ? const Color(0xFFC8F0D4)
            : const Color(0xFFFFD6D6);
    final border = !picked
        ? const Color(0xFFDDE6EE)
        : correct
            ? const Color(0xFF2E9E5B)
            : Colors.redAccent;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _answer(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 3),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Text(String.fromCharCode(65 + i),
                    style: GoogleFonts.itim(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(q.options[i],
                    style: GoogleFonts.itim(fontSize: 24, color: AppColors.textDark)),
              ),
              if (picked)
                Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: border, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _result() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Mascot(mood: MascotMood.cheer, size: 120, animate: _animate),
        const SizedBox(height: 16),
        Text('Hebat, kamu selesai membaca!', style: _title(32), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(widget.story.title,
            style: GoogleFonts.itim(fontSize: 22, color: AppColors.hint)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: _animate ? 450 + i * 250 : 1),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Icon(Icons.star_rounded,
                    size: 72,
                    color: i < _stars ? const Color(0xFFFFB300) : const Color(0xFFDDDDDD)),
              ),
          ],
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Kembali ke Dongeng',
          onPressed: () => Navigator.pop(context, true),
          width: 320,
          height: 58,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: widget.onReadAgain,
          icon: const Icon(Icons.replay_rounded),
          label: Text('Baca lagi', style: GoogleFonts.itim(fontSize: 20)),
        ),
      ],
    );
  }
}
