import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/event_logger.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';
import '../widgets/wood_tile.dart';

/// Dengarkan suara huruf / suku kata, lalu pilih kotak yang benar.
/// (Huruf: aktif jika "Latihan Mendengar" menyala. Suku kata: kalau latihan mendengar
/// mati, soalnya menjadi "Mana suku kata BA?" yang dicocokkan dengan tulisan.)
class ListenPickStep extends StatefulWidget {
  final LessonStep step;
  final StepEnv env;
  const ListenPickStep({super.key, required this.step, required this.env});

  @override
  State<ListenPickStep> createState() => _ListenPickStepState();
}

class _ListenPickStepState extends State<ListenPickStep>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF2ECC71);
  static const _red = Color(0xFFE74C3C);

  late final List<String> _letters;
  int? _correct;
  int? _wrong;
  late final AnimationController _shake;

  String get _target => widget.step.letter.toUpperCase();
  bool get _syllable => widget.step.type == LessonStepType.syllablePick;
  bool get _visual => _syllable && widget.step.visual;

  void _speakTarget() => _syllable
      ? SpeechService.instance.speak(_target.toLowerCase())
      : SpeechService.instance.speakLetter(_target);

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final random = Random();
    _letters = [
      _target,
      ...(_syllable
          ? syllableDistractors(_target, widget.step.pool, 2, random)
          : pickDistractors(_target, widget.step.pool, 2, random)),
    ]..shuffle(random);
    widget.env.report({'options': _letters});

    // Latihan mendengar: suara selalu diputar di awal.
    if (!_visual) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _speakTarget();
      });
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (_correct != null) return;
    if (_letters[i] == _target) {
      HapticFeedback.lightImpact();
      widget.env.sfx(Sfx.correct);
      if (_syllable) _speakTarget(); // dengar lagi bunyi yang benar
      setState(() => _correct = i);
      widget.env.onCorrect();
      widget.env.onDone();
    } else {
      HapticFeedback.mediumImpact();
      widget.env.sfx(Sfx.wrong, volume: 0.6);
      widget.env.onMistake(_letters[i]);
      setState(() => _wrong = i);
      if (widget.env.animate) _shake.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: _visual
              ? 'Mana suku kata ${_target.toLowerCase()}?'
              : _syllable
                  ? 'Suku kata apa yang kamu dengar?'
                  : 'Huruf apa yang kamu dengar?',
          speech: _visual
              ? 'Mana suku kata ${_target.toLowerCase()}?'
              : _syllable
                  ? 'Suku kata apa yang kamu dengar?'
                  : 'Huruf apa yang kamu dengar?',
          autoSpeak: _visual && widget.env.sound,
        ),
        const SizedBox(height: 16),
        BouncyTap(
          animate: widget.env.animate,
          onTap: () {
            EventLogger.instance.ui('listen_letter', {'letter': '?'});
            _speakTarget();
          },
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 46),
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 24,
          children: [
            for (var i = 0; i < _letters.length; i++)
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final dx = _wrong == i
                      ? sin(_shake.value * pi * 6) * 10 * (1 - _shake.value)
                      : 0.0;
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    BouncyTap(
                      animate: widget.env.animate,
                      onTap: () => _tap(i),
                      child: WoodTile(
                        letter: _syllable ? _letters[i].toLowerCase() : _letters[i],
                        size: 104,
                        width: _syllable ? 150 : null,
                        outline: _correct == i
                            ? _green
                            : (_wrong == i ? _red : null),
                        badge: _correct == i
                            ? const Icon(Icons.check_circle_rounded,
                                color: _green, size: 30)
                            : null,
                      ),
                    ),
                    if (_correct == i && widget.env.animate)
                      const Positioned.fill(
                        child: IgnorePointer(child: SparkleBurst(radius: 80)),
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (_correct != null)
          Text('Betul sekali!',
              style: GoogleFonts.fredoka(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _green)),
      ],
    );
  }
}
