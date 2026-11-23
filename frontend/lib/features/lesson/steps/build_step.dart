import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sky_background.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';
import '../widgets/wood_tile.dart';
import '../word_pictures.dart';

/// "Susun kata": pilih potongan suku kata sesuai urutan bunyinya (bo + la = bola).
/// "Susun kalimat": pilih kata-kata sesuai urutan kalimat ("Ini" "bola").
class BuildStep extends StatefulWidget {
  final LessonStep step;
  final StepEnv env;
  const BuildStep({super.key, required this.step, required this.env});

  @override
  State<BuildStep> createState() => _BuildStepState();
}

class _Piece {
  final String text; // yang tampil di kotak
  final String key; // untuk dicocokkan (huruf kecil, tanpa tanda baca)
  bool used = false;
  _Piece(this.text) : key = norm(text);
  static String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _BuildStepState extends State<BuildStep> with SingleTickerProviderStateMixin {
  late final List<String> _parts; // urutan yang benar
  late final List<_Piece> _pieces; // diacak (+ 1 pengecoh untuk kata)
  int _filled = 0;
  _Piece? _wrong;
  bool _done = false;
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  bool get _sentence => widget.step.type == LessonStepType.sentenceBuild;
  String get _target => widget.step.letter;

  /// Kata pada kotak kalimat tampil tanpa titik / tanda tanya.
  static String _clean(String w) => w.replaceAll(RegExp(r'[.,!?]+$'), '');

  @override
  void initState() {
    super.initState();
    final random = Random();
    _parts = _sentence ? widget.step.parts.map(_clean).toList() : widget.step.parts;
    final pieces = [for (final p in _parts) _Piece(p)];
    if (!_sentence) {
      final extra = _distractor(random);
      if (extra != null) pieces.add(_Piece(extra));
    }
    // acak, tetapi jangan sampai urutannya sudah benar
    for (var tries = 0; tries < 6; tries++) {
      pieces.shuffle(random);
      final inOrder = [for (var i = 0; i < _parts.length && i < pieces.length; i++) pieces[i].key == _Piece.norm(_parts[i])]
          .every((x) => x);
      if (!inOrder || pieces.length < 2) break;
    }
    _pieces = pieces;
    widget.env.report({'options': [for (final p in _pieces) p.text]});
  }

  /// Suku kata pengecoh dari kata lain di section ini (atau buatan, mis. "BI").
  String? _distractor(Random random) {
    final taken = _parts.map(_Piece.norm).toSet();
    final fromPool = <String>{
      for (final w in widget.step.pool)
        if (w.contains('-')) ...syllablesOf(w),
    }.where((s) => !taken.contains(_Piece.norm(s))).toList();
    if (fromPool.isNotEmpty) return fromPool[random.nextInt(fromPool.length)];
    final first = _parts.first.toLowerCase();
    if (first.length < 2) return null;
    final c = first.substring(0, first.length - 1);
    final options = vowels.map((v) => '$c${v.toLowerCase()}').where((s) => !taken.contains(s)).toList();
    return options.isEmpty ? null : options[random.nextInt(options.length)];
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _speakTarget() => SpeechService.instance.speak(_sentence ? _target : _target.toLowerCase());

  void _tap(_Piece p) {
    if (_done || p.used) return;
    final expected = _Piece.norm(_parts[_filled]);
    if (p.key == expected) {
      HapticFeedback.lightImpact();
      setState(() {
        p.used = true;
        _filled++;
      });
      if (_filled == _parts.length) {
        widget.env.sfx(Sfx.correct);
        setState(() => _done = true);
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _speakTarget();
        });
        widget.env.report({'note': '${_sentence ? 'Kalimat' : 'Kata'} "$_target" berhasil disusun'});
        widget.env.onCorrect();
        widget.env.onDone();
      } else {
        widget.env.sfx(Sfx.tap, volume: 0.6);
        SpeechService.instance.speak(p.text.toLowerCase());
      }
    } else {
      HapticFeedback.mediumImpact();
      widget.env.sfx(Sfx.wrong, volume: 0.6);
      widget.env.onMistake(p.text);
      setState(() => _wrong = p);
      if (widget.env.animate) _shake.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final picture = pictureFor(_target);
    final tileSize = _sentence ? 76.0 : 92.0;

    final slots = Wrap(
      alignment: WrapAlignment.center,
      spacing: _sentence ? 10 : 6,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _parts.length; i++)
          _Slot(
            text: i < _filled ? _parts[i] : null,
            active: i == _filled && !_done,
            width: WoodTile.widthFor(_parts[i], tileSize),
            height: tileSize,
            done: _done,
          ),
      ],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: _sentence ? 'Susun kalimatnya' : 'Susun katanya',
          speech: _sentence ? 'Ayo susun kalimat. $_target' : 'Ayo susun kata ${_target.toLowerCase()}',
          autoSpeak: widget.env.sound,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (picture != null) ...[
              BouncyTap(
                animate: widget.env.animate,
                onTap: _speakTarget,
                child: SoftCard(
                  radius: 24,
                  padding: const EdgeInsets.all(14),
                  child: Text(picture, style: const TextStyle(fontSize: 78)),
                ),
              ),
              const SizedBox(width: 22),
            ],
            Flexible(child: slots),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Dengarkan',
              onPressed: _speakTarget,
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 34),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final p in _pieces)
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final dx = _wrong == p ? sin(_shake.value * pi * 6) * 10 * (1 - _shake.value) : 0.0;
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: p.used ? 0.25 : 1,
                  child: BouncyTap(
                    animate: widget.env.animate && !p.used,
                    onTap: () => _tap(p),
                    child: WoodTile(
                      letter: p.text,
                      size: tileSize,
                      width: WoodTile.widthFor(p.text, tileSize),
                      outline: _wrong == p ? const Color(0xFFE74C3C) : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              _done
                  ? (_sentence ? _target : 'Hebat! ${_parts.join(' - ')} = ${_target.toLowerCase()}')
                  : (_sentence ? 'Ketuk kata sesuai urutan kalimat' : 'Ketuk potongan sesuai urutan bunyinya'),
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: _done ? 26 : 18,
                fontWeight: _done ? FontWeight.w700 : FontWeight.w500,
                color: _done ? const Color(0xFF2E9E5B) : AppColors.hint,
              ),
            ),
            if (_done && widget.env.animate)
              const Positioned.fill(child: IgnorePointer(child: SparkleBurst(radius: 90))),
          ],
        ),
      ],
    );
  }
}

/// Tempat kosong untuk satu potongan; berisi tulisan setelah diisi.
class _Slot extends StatelessWidget {
  final String? text;
  final bool active;
  final bool done;
  final double width;
  final double height;
  const _Slot({required this.text, required this.active, required this.done, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final filled = text != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(height * 0.16),
        border: Border.all(
          color: done
              ? const Color(0xFF2ECC71)
              : active
                  ? AppColors.primary
                  : const Color(0xFFBFD3EA),
          width: active || done ? 3.5 : 2.5,
        ),
      ),
      child: filled
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text!,
                style: GoogleFonts.itim(fontSize: height * 0.55, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            )
          : null,
    );
  }
}
