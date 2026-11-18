import 'package:flutter/material.dart';
import '../../../core/widgets/sky_background.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/event_logger.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';

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

  void _speakLetter(String letter) {
    widget.env.sfx(Sfx.tap);
    EventLogger.instance.ui('listen_letter', {'letter': letter});
    SpeechService.instance.speakLetter(widget.step.letter.toUpperCase());
  }

  /// Kartu huruf besar "Aa" (seperti banner) dengan tombol suara.
  Widget _letterCard(String upper, String lower) {
    final card = SoftCard(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(36, 20, 36, 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFBFD9F7), width: 2.5, strokeAlign: BorderSide.strokeAlignInside),
          ),
          child: Text('$upper$lower',
              style: GoogleFonts.fredoka(
                fontSize: 120,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
                shadows: const [Shadow(color: Color(0x33F0473C), offset: Offset(0, 5))],
              )),
        ),
        const SizedBox(height: 12),
        Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _speakLetter(upper),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 32),
            ),
          ),
        ),
      ]),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: widget.env.animate ? 0.0 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.elasticOut,
      builder: (context, v, c) => Transform.scale(scale: v, child: c),
      child: BouncyTap(animate: widget.env.animate, onTap: () => _speakLetter(upper), child: card),
    );
  }

  /// Gambar contoh kata yang diawali huruf ini (mis. 🍎 Apel), ketuk -> kata dibacakan.
  Widget _exampleCard(String upper) {
    final ex = letterExamples[upper];
    if (ex == null) return const SizedBox.shrink();
    final (emoji, word) = ex;
    return Bob(
      enabled: widget.env.animate,
      phase: 0.4,
      child: BouncyTap(
        animate: widget.env.animate,
        onTap: () {
          widget.env.sfx(Sfx.tap);
          EventLogger.instance.ui('listen_letter', {'letter': upper, 'word': word});
          SpeechService.instance.speak(word);
        },
        child: SoftCard(
          radius: 30,
          padding: const EdgeInsets.fromLTRB(30, 14, 30, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 108)),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: word.substring(0, 1), style: const TextStyle(color: AppColors.red)),
                TextSpan(text: word.substring(1)),
              ]),
              style: GoogleFonts.fredoka(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ]),
        ),
      ),
    );
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
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 36,
          runSpacing: 20,
          children: [_letterCard(upper, lower), _exampleCard(upper)],
        ),
        const SizedBox(height: 18),
        Text(
          'Ketuk huruf atau gambar untuk mendengar suaranya',
          style: GoogleFonts.fredoka(fontSize: 18, color: AppColors.hint),
        ),
      ],
    );
  }
}

/// Contoh kata (dengan gambar emoji) untuk tiap huruf.
const letterExamples = <String, (String, String)>{
  'A': ('🍎', 'Apel'),
  'B': ('⚽', 'Bola'),
  'C': ('🌶️', 'Cabai'),
  'D': ('🎲', 'Dadu'),
  'E': ('🦅', 'Elang'),
  'F': ('📷', 'Foto'),
  'G': ('🐘', 'Gajah'),
  'H': ('🐯', 'Harimau'),
  'I': ('🐟', 'Ikan'),
  'J': ('🍊', 'Jeruk'),
  'K': ('🐱', 'Kucing'),
  'L': ('🍋', 'Lemon'),
  'M': ('🥭', 'Mangga'),
  'N': ('🍍', 'Nanas'),
  'O': ('🦧', 'Orang utan'),
  'P': ('🍌', 'Pisang'),
  'Q': ('📜', 'Quran'),
  'R': ('🍞', 'Roti'),
  'S': ('🐄', 'Sapi'),
  'T': ('🍅', 'Tomat'),
  'U': ('🐍', 'Ular'),
  'V': ('🏺', 'Vas'),
  'W': ('🥕', 'Wortel'),
  'X': ('🎶', 'Xilofon'),
  'Y': ('🪀', 'Yoyo'),
  'Z': ('🦓', 'Zebra'),
};
