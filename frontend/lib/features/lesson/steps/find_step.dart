import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';
import '../widgets/wood_tile.dart';

/// "Carilah Huruf A": ketuk semua kotak yang berisi huruf tersebut.
class FindStep extends StatefulWidget {
  final LessonStep step;
  final StepEnv env;
  const FindStep({super.key, required this.step, required this.env});

  @override
  State<FindStep> createState() => _FindStepState();
}

class _FindStepState extends State<FindStep>
    with SingleTickerProviderStateMixin {
  static const _targets = 2; // jumlah huruf yang harus ditemukan
  static const _green = Color(0xFF2ECC71);
  static const _red = Color(0xFFE74C3C);

  late final List<String> _letters;
  late final List<double> _angles;
  final Set<int> _found = {};
  int? _wrong;
  late final AnimationController _shake;

  bool get _complete => _found.length >= _targets;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final random = Random();
    final target = widget.step.letter.toUpperCase();
    _letters = [
      target,
      target,
      ...pickDistractors(target, widget.step.pool, 4, random),
    ]..shuffle(random);
    _angles = [
      for (var i = 0; i < _letters.length; i++) (random.nextDouble() - 0.5) * 0.7,
    ];
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (_found.contains(i) || _complete) return;
    final target = widget.step.letter.toUpperCase();

    if (_letters[i] == target) {
      HapticFeedback.lightImpact();
      setState(() => _found.add(i));
      widget.env.onCorrect();
      if (_complete) {
        widget.env.sfx(Sfx.success);
        widget.env.onDone();
      } else {
        widget.env.sfx(Sfx.correct);
        if (widget.env.sound) SpeechService.instance.speakLetter(target);
      }
    } else {
      HapticFeedback.mediumImpact();
      widget.env.sfx(Sfx.wrong, volume: 0.6);
      widget.env.onMistake();
      setState(() => _wrong = i);
      if (widget.env.animate) _shake.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final upper = widget.step.letter.toUpperCase();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: 'Carilah Huruf $upper',
          speech: 'Carilah huruf ${SpeechService.letterName(upper)}',
          autoSpeak: widget.env.sound,
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
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
                          letter: _letters[i],
                          size: 96,
                          rotation: _angles[i],
                          outline: _found.contains(i)
                              ? _green
                              : (_wrong == i ? _red : null),
                          badge: _found.contains(i)
                              ? const Icon(Icons.check_circle_rounded,
                                  color: _green, size: 30)
                              : null,
                        ),
                      ),
                      if (_found.contains(i) && widget.env.animate)
                        const Positioned.fill(
                          child: IgnorePointer(child: SparkleBurst()),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _complete ? 'Hebat!' : 'Ditemukan ${_found.length} dari $_targets',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _complete ? _green : const Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}
