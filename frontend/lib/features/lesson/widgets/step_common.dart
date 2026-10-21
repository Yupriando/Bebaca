import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';

/// Hal yang diterima setiap langkah dari LessonPage.
class StepEnv {
  final bool sound; // pengaturan "Sound Effect"
  final bool animate; // pengaturan "Animation"
  final VoidCallback onDone; // langkah selesai -> tombol Next aktif
  /// salah / dilewati -> mengurangi bintang. [picked] = huruf yang (salah) dipilih anak,
  /// untuk laporan orang tua ("B sering tertukar dengan D").
  final void Function([String? picked]) onMistake;
  final VoidCallback onCorrect; // jawaban benar -> maskot bersorak

  /// Detail untuk Pantau Langsung orang tua, mis. {'options': [...]} atau {'note': '...'}.
  final void Function(Map<String, Object?> detail) report;

  static void _noReport(Map<String, Object?> _) {}

  const StepEnv({
    required this.sound,
    required this.animate,
    required this.onDone,
    required this.onMistake,
    required this.onCorrect,
    this.report = _noReport,
  });

  /// Putar efek suara (hanya jika "Sound Effect" menyala).
  void sfx(Sfx s, {double volume = 0.8}) {
    if (sound) SoundService.instance.play(s, volume: volume);
  }
}

const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// Pilih [count] huruf pengecoh dari [pool] (dilengkapi alfabet bila kurang).
List<String> pickDistractors(
  String letter,
  List<String> pool,
  int count,
  Random random,
) {
  final upper = letter.toUpperCase();
  final primary = pool
      .map((e) => e.toUpperCase())
      .toSet()
      .where((e) => e != upper)
      .toList()
    ..shuffle(random);
  final result = primary.take(count).toList();

  if (result.length < count) {
    final fill = alphabet
        .split('')
        .where((e) => e != upper && !result.contains(e))
        .toList()
      ..shuffle(random);
    result.addAll(fill.take(count - result.length));
  }
  return result;
}

/// Judul langkah + tombol speaker (anak yang belum lancar membaca bisa mendengarnya).
class StepPrompt extends StatefulWidget {
  final String text;
  final String speech;
  final bool autoSpeak;
  final bool emphasis;

  const StepPrompt({
    super.key,
    required this.text,
    required this.speech,
    this.autoSpeak = false,
    this.emphasis = false,
  });

  @override
  State<StepPrompt> createState() => _StepPromptState();
}

class _StepPromptState extends State<StepPrompt> {
  @override
  void initState() {
    super.initState();
    if (widget.autoSpeak) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) SpeechService.instance.speak(widget.speech);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.emphasis ? 36 : 24,
              fontWeight: FontWeight.bold,
              color: widget.emphasis ? Colors.black : const Color(0xFF555555),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Dengarkan',
          onPressed: () => SpeechService.instance.speak(widget.speech),
          icon: const Icon(Icons.volume_up_rounded,
              color: AppColors.primary, size: 30),
        ),
      ],
    );
  }
}
