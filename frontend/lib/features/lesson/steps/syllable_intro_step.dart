import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sky_background.dart';
import '../../../services/event_logger.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';
import '../widgets/wood_tile.dart';

/// "Suku Kata B": konsonan digabung dengan tiap huruf vokal (b + a = ba).
/// Ketuk tiap suku kata untuk mendengar bunyinya; selesai setelah kelimanya didengar.
class SyllableIntroStep extends StatefulWidget {
  final LessonStep step;
  final StepEnv env;
  const SyllableIntroStep({super.key, required this.step, required this.env});

  @override
  State<SyllableIntroStep> createState() => _SyllableIntroStepState();
}

class _SyllableIntroStepState extends State<SyllableIntroStep> {
  static const _green = Color(0xFF2ECC71);

  final _heard = <int>{};
  int _current = 0;
  bool _playingAll = false;
  bool _done = false;

  String get _c => widget.step.letter.toUpperCase();
  // suku kata ditulis huruf kecil, sama seperti di kata yang nanti dibaca (bo-la)
  List<String> get _syllables => [for (final v in vowels) '$_c$v'.toLowerCase()];

  @override
  void initState() {
    super.initState();
    // dengarkan kelimanya sekali di awal (kalau suara menyala)
    if (widget.env.sound) {
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted && _heard.isEmpty) _playAll();
      });
    }
  }

  void _say(int i, {bool tap = true}) {
    if (!mounted) return;
    setState(() {
      _current = i;
      _heard.add(i);
    });
    if (tap) widget.env.sfx(Sfx.tap, volume: 0.5);
    EventLogger.instance.ui('listen_letter', {'letter': _syllables[i]});
    SpeechService.instance.speak(_syllables[i]);
    if (_heard.length == _syllables.length && !_done) {
      _done = true;
      widget.env.report({'note': 'Sudah mendengar semua suku kata ${_syllables.join(', ')}'});
      widget.env.onDone();
    }
  }

  Future<void> _playAll() async {
    if (_playingAll) return;
    setState(() => _playingAll = true);
    for (var i = 0; i < _syllables.length; i++) {
      if (!mounted) return;
      _say(i, tap: false);
      await Future.delayed(const Duration(milliseconds: 1150));
    }
    if (mounted) setState(() => _playingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final v = vowels[_current];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: 'Suku Kata $_c',
          speech: 'Huruf ${SpeechService.letterName(_c)}, digabung dengan huruf vokal',
          autoSpeak: widget.env.sound,
          emphasis: true,
        ),
        const SizedBox(height: 14),
        // rumus gabung bunyi: B + A = BA
        SoftCard(
          radius: 26,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WoodTile(letter: _c.toLowerCase(), size: 74),
              _sign('+'),
              AnimatedSwitcher(
                duration: Duration(milliseconds: widget.env.animate ? 250 : 0),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: _VowelTile(key: ValueKey(v), vowel: v.toLowerCase()),
              ),
              _sign('='),
              AnimatedSwitcher(
                duration: Duration(milliseconds: widget.env.animate ? 250 : 0),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Text(
                  '$_c$v'.toLowerCase(),
                  key: ValueKey('$_c$v'),
                  style: GoogleFonts.fredoka(
                    fontSize: 62,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < _syllables.length; i++)
              BouncyTap(
                animate: widget.env.animate,
                onTap: () => _say(i),
                child: WoodTile(
                  letter: _syllables[i],
                  size: 92,
                  width: 128,
                  outline: i == _current && _heard.contains(i)
                      ? AppColors.primary
                      : _heard.contains(i)
                          ? _green
                          : null,
                  badge: _heard.contains(i)
                      ? const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22)
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: _playingAll ? null : _playAll,
          icon: const Icon(Icons.play_circle_fill_rounded, size: 30),
          label: Text('Dengarkan semua', style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        Text(
          _done ? 'Hebat! Sekarang ketuk Lanjut' : 'Ketuk setiap suku kata untuk mendengar bunyinya',
          style: GoogleFonts.fredoka(fontSize: 18, color: _done ? const Color(0xFF2E9E5B) : AppColors.hint),
        ),
      ],
    );
  }

  Widget _sign(String s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(s, style: GoogleFonts.fredoka(fontSize: 46, fontWeight: FontWeight.w700, color: AppColors.hint)),
      );
}

/// Huruf vokal dengan gaya berbeda dari kotak kayu (putih, huruf merah).
class _VowelTile extends StatelessWidget {
  final String vowel;
  const _VowelTile({super.key, required this.vowel});

  @override
  Widget build(BuildContext context) => Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red, width: 3),
        ),
        child: Text(
          vowel,
          style: GoogleFonts.itim(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.red),
        ),
      );
}
