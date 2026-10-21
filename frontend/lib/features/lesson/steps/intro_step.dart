import 'package:flutter/material.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';
import '../widgets/wood_tile.dart';

/// "Ini Huruf A": tampilkan huruf besar & kecil. Ketuk kotak untuk mendengar suaranya.
class IntroStep extends StatefulWidget {
  final LessonStep step;
  final StepEnv env;
  const IntroStep({super.key, required this.step, required this.env});

  @override
  State<IntroStep> createState() => _IntroStepState();
}

class _IntroStepState extends State<IntroStep> {
  @override
  void initState() {
    super.initState();
    // Langkah perkenalan langsung dianggap selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.env.onDone());
  }

  /// Muncul membal, lalu melayang pelan; ketuk -> memantul + bersuara.
  Widget _tile(String letter, int index) {
    final tile = TweenAnimationBuilder<double>(
      tween: Tween(begin: widget.env.animate ? 0.0 : 1.0, end: 1.0),
      duration: Duration(milliseconds: 450 + index * 200),
      curve: Curves.elasticOut,
      builder: (context, v, c) => Transform.scale(scale: v, child: c),
      child: Bob(
        enabled: widget.env.animate,
        phase: index * 0.5,
        child: BouncyTap(
          animate: widget.env.animate,
          onTap: () {
            widget.env.sfx(Sfx.tap);
            SpeechService.instance.speakLetter(widget.step.letter.toUpperCase());
          },
          child: WoodTile(letter: letter, size: 120),
        ),
      ),
    );
    return tile;
  }

  @override
  Widget build(BuildContext context) {
    final upper = widget.step.letter.toUpperCase();
    final lower = widget.step.letter.toLowerCase();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: 'Ini Huruf $upper',
          speech: 'Ini huruf ${SpeechService.letterName(upper)}',
          autoSpeak: widget.env.sound,
          emphasis: true,
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 28,
          runSpacing: 20,
          children: [_tile(upper, 0), _tile(lower, 1)],
        ),
        const SizedBox(height: 24),
        const Text(
          'Ketuk huruf untuk mendengar suaranya',
          style: TextStyle(fontSize: 18, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}
