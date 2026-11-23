import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/event_logger.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sky_background.dart';
import '../../../services/parent_mode.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../../stories/story_narrator.dart' show matchReadWords;
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';
import '../widgets/wood_tile.dart';
import '../word_pictures.dart';

enum _Phase { idle, listening, success, failed, notHeard, unavailable }

enum _Target { letter, syllable, word, sentence }

/// "Baca huruf / suku kata / kata / kalimat ini": anak membaca dengan suara,
/// dikenali lewat mikrofon. Kalau mikrofon tidak tersedia (atau 2x tidak terdengar),
/// anak bisa menekan "Aku sudah membaca". Mode Belajar Bersama: Ayah/Ibu bisa menilai
/// bacaan langsung ("Sudah benar" / "Coba lagi").
class ReadStep extends StatefulWidget {
  final LessonStep step;
  final StepEnv env;
  const ReadStep({super.key, required this.step, required this.env});

  @override
  State<ReadStep> createState() => _ReadStepState();
}

class _ReadStepState extends State<ReadStep>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF2ECC71);
  static const _red = Color(0xFFE74C3C);

  final _speech = SpeechService.instance;
  _Phase _phase = _Phase.idle;
  String _heard = '';
  bool _finished = false;
  bool _parentTried = false; // "Coba lagi" dari orang tua dihitung salah sekali saja
  int _misses =
      0; // berapa kali tidak terdengar / belum tepat -> tampilkan tombol lanjut
  Timer? _timeout;

  // gelombang yang memancar dari tombol mikrofon saat mendengarkan
  late final AnimationController _ripple;

  _Target get _kind => switch (widget.step.type) {
        LessonStepType.syllableRead => _Target.syllable,
        LessonStepType.wordRead => _Target.word,
        LessonStepType.sentenceRead => _Target.sentence,
        _ => _Target.letter,
      };

  /// Huruf dalam huruf besar, suku kata huruf kecil ("ba"), kata & kalimat apa adanya.
  String get _text => switch (_kind) {
        _Target.letter => widget.step.letter.toUpperCase(),
        _Target.syllable => widget.step.letter.toLowerCase(),
        _ => widget.step.letter,
      };

  /// Yang diucapkan (untuk contoh & pesan): nama huruf, atau tulisan itu sendiri.
  String get _spoken => switch (_kind) {
        _Target.letter => SpeechService.letterName(_text),
        _Target.sentence => _text,
        _ => _text.toLowerCase(),
      };

  String get _what => switch (_kind) {
        _Target.letter => 'huruf',
        _Target.syllable => 'suku kata',
        _Target.word => 'kata',
        _Target.sentence => 'kalimat',
      };

  void _speakTarget() =>
      _kind == _Target.letter ? _speech.speakLetter(_text) : _speech.speak(_spoken);

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _ripple.dispose();
    _speech.cancelListening();
    super.dispose();
  }

  void _setPhase(_Phase p) {
    setState(() => _phase = p);
    if (p == _Phase.listening && widget.env.animate) {
      _ripple.repeat();
    } else {
      _ripple.stop();
    }
  }

  void _finish({bool correct = false}) {
    setState(() => _finished = true);
    if (correct) widget.env.onCorrect();
    widget.env.onDone();
  }

  bool _matches(String heard) => switch (_kind) {
        _Target.letter => spokenLetterMatches(heard, _text),
        _Target.syllable => spokenSyllableMatches(heard, _text),
        _Target.word => spokenWordMatches(heard, _text),
        _Target.sentence => () {
            final words = sentenceWords(_text);
            return matchReadWords(words, heard) >= (words.length * 0.7).ceil();
          }(),
      };

  Future<void> _onMic() async {
    if (_finished) return;

    if (_phase == _Phase.listening) {
      _timeout?.cancel();
      await _speech.stopListening();
      if (mounted) _setPhase(_Phase.idle);
      return;
    }

    final ok = await _speech.initListening();
    if (!mounted) return;
    if (!ok) {
      _setPhase(_Phase.unavailable);
      return;
    }

    widget.env.sfx(Sfx.micOn, volume: 0.6);
    setState(() => _heard = '');
    _setPhase(_Phase.listening);
    widget.env.report({'note': 'Mikrofon aktif, sedang membaca $_what'});

    final sentence = _kind == _Target.sentence;
    // Batas waktu: kalau tidak ada suara sama sekali, beri tahu anak.
    _timeout?.cancel();
    _timeout = Timer(Duration(seconds: sentence ? 16 : 8), () async {
      if (_phase != _Phase.listening) return;
      await _speech.stopListening();
      _notHeard();
    });

    await _speech.listen(
      onResult: _onResult,
      listenFor: Duration(seconds: sentence ? 15 : 6),
      pauseFor: const Duration(seconds: 3),
      // ucapan pendek (huruf, suku kata, kata) sering salah tulis: periksa semua tebakan
      alternates: !sentence,
      hints: switch (_kind) {
        _Target.letter => [_spoken, _text.toLowerCase(), 'huruf $_spoken'],
        _Target.sentence => null,
        _ => [_spoken],
      },
      onError: (_) => _notHeard(),
      onDone: () {
        // selesai tanpa hasil yang cocok -> jangan diam saja
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _phase == _Phase.listening) _notHeard();
        });
      },
    );
  }

  /// Tidak ada suara yang dikenali (umum untuk ucapan yang sangat pendek).
  void _notHeard() {
    if (!mounted || _phase != _Phase.listening) return;
    _timeout?.cancel();
    _speech.cancelListening();
    _misses++;
    _setPhase(_Phase.notHeard);
    widget.env.report({'note': 'Mikrofon belum menangkap suara (percobaan ke-$_misses)'});
  }

  void _onResult(String words, bool isFinal) {
    if (!mounted || _phase != _Phase.listening) return;
    final first = _kind == _Target.sentence ? words : words.split(' ').first;

    if (_matches(words)) {
      _timeout?.cancel();
      _speech.stopListening();
      HapticFeedback.mediumImpact();
      widget.env.sfx(Sfx.success);
      setState(() => _heard = first);
      widget.env.report({'heard': first, 'note': 'Berhasil membaca $_what $_text'});
      _setPhase(_Phase.success);
      _finish(correct: true);
    } else if (isFinal) {
      _timeout?.cancel();
      if (words.trim().isEmpty) {
        _notHeard();
      } else {
        _misses++;
        widget.env.sfx(Sfx.wrong, volume: 0.6);
        widget.env.onMistake(first); // yang terdengar mikrofon
        setState(() => _heard = first);
        _setPhase(_Phase.failed);
      }
    } else {
      setState(() => _heard = first);
      final now = DateTime.now();
      if (words.trim().isNotEmpty &&
          (_lastHeardReport == null || now.difference(_lastHeardReport!).inMilliseconds > 1000)) {
        _lastHeardReport = now;
        widget.env.report({'heard': first, 'live': true});
      }
    }
  }

  DateTime? _lastHeardReport;

  // ---------------------------------------------------------------- penilaian orang tua

  void _parentCorrect() {
    if (_finished) return;
    _timeout?.cancel();
    _speech.cancelListening();
    HapticFeedback.mediumImpact();
    widget.env.sfx(Sfx.success);
    widget.env.report({'note': 'Dinilai Ayah/Ibu: $_what $_text sudah benar'});
    EventLogger.instance.ui('parent_judge', {'correct': true, 'text': _text});
    _setPhase(_Phase.success);
    _finish(correct: true);
  }

  void _parentRetry() {
    if (_finished) return;
    _timeout?.cancel();
    _speech.cancelListening();
    if (!_parentTried) {
      _parentTried = true;
      widget.env.onMistake();
    }
    widget.env.report({'note': 'Dinilai Ayah/Ibu: $_what $_text perlu dicoba lagi'});
    EventLogger.instance.ui('parent_judge', {'correct': false, 'text': _text});
    _setPhase(_Phase.idle);
    _speakTarget(); // contohkan dulu, lalu si kecil menirukan
  }

  // ---------------------------------------------------------------- tampilan

  String get _status {
    final verb = _kind == _Target.letter || _kind == _Target.syllable ? 'ucapkan' : 'bacakan';
    switch (_phase) {
      case _Phase.idle:
        return 'Ketuk mikrofon, lalu $verb ${_kind == _Target.letter ? 'hurufnya' : _kind == _Target.syllable ? 'suku katanya' : _kind == _Target.word ? 'katanya' : 'kalimatnya'}';
      case _Phase.listening:
        return 'Aku mendengarkan...';
      case _Phase.success:
        return 'Bagus sekali!';
      case _Phase.failed:
        return 'Hampir! Coba lagi ya';
      case _Phase.notHeard:
        return _kind == _Target.sentence
            ? 'Aku belum mendengar suaramu. Ketuk mikrofon, lalu bacakan kalimatnya dengan keras ya!'
            : 'Aku belum mendengar suaramu. Ketuk mikrofon, lalu $verb "$_spoken" dengan keras ya!';
      case _Phase.unavailable:
        return 'Mikrofon tidak tersedia. Bacalah $_what ini dengan suara keras, lalu ketuk tombol di bawah.';
    }
  }

  Color get _statusColor {
    switch (_phase) {
      case _Phase.success:
        return _green;
      case _Phase.failed:
        return _red;
      case _Phase.notHeard:
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFF777777);
    }
  }

  Widget _micButton(bool listening, {bool compact = false}) {
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: _finished ? _green : (listening ? _red : AppColors.primary),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _finished
            ? Icons.check_rounded
            : (listening ? Icons.stop_rounded : Icons.mic_rounded),
        color: Colors.white,
        size: 50,
      ),
    );

    return SizedBox(
      width: compact ? 150 : 190,
      height: compact ? 124 : 150,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (listening && widget.env.animate)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ripple,
                builder:
                    (context, _) =>
                        CustomPaint(painter: _RipplePainter(_ripple.value)),
              ),
            ),
          GestureDetector(onTap: _onMic, child: button),
        ],
      ),
    );
  }

  Widget _doneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () => _finish(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text('Aku sudah membaca', style: GoogleFonts.fredoka(fontSize: 20)),
      ),
    );
  }

  /// Tombol penilaian untuk Ayah/Ibu (mode Belajar Bersama).
  Widget _parentJudge() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.family_restroom_rounded, size: 20, color: Color(0xFF7B61FF)),
            const SizedBox(width: 6),
            Text('Ayah/Ibu, bagaimana bacaannya?',
                style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF5B45C9))),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton.icon(
              onPressed: _parentRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE67E22),
                side: const BorderSide(color: Color(0xFFE67E22), width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: Text('Coba lagi', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _parentCorrect,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E9E5B),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text('Sudah benar', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }

  /// Yang dibaca anak: kotak kayu (huruf / suku kata), kata per suku kata, atau kalimat.
  Widget _target() {
    final success = _phase == _Phase.success;
    Widget tappable(Widget child, VoidCallback onTap) => BouncyTap(
          animate: widget.env.animate,
          onTap: () {
            widget.env.sfx(Sfx.tap);
            onTap();
          },
          child: child,
        );
    const badge = Icon(Icons.volume_up_rounded, color: Colors.white, size: 28);

    switch (_kind) {
      case _Target.letter:
      case _Target.syllable:
        return tappable(
          WoodTile(
            letter: _text,
            size: 140,
            width: _kind == _Target.syllable ? 200 : null,
            outline: success ? _green : null,
            badge: badge,
          ),
          () {
            EventLogger.instance.ui('listen_letter', {'letter': _text});
            _speakTarget();
          },
        );
      case _Target.word:
        final picture = pictureFor(_text);
        final parts = widget.step.parts.isEmpty ? [_text] : widget.step.parts;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (picture != null) ...[
              tappable(
                SoftCard(radius: 24, padding: const EdgeInsets.all(14), child: Text(picture, style: const TextStyle(fontSize: 84))),
                _speakTarget,
              ),
              const SizedBox(width: 22),
            ],
            // tiap suku kata bisa diketuk untuk didengar sendiri
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('-', style: GoogleFonts.fredoka(fontSize: 40, color: AppColors.hint, fontWeight: FontWeight.w700)),
                ),
              tappable(
                WoodTile(
                  letter: parts[i],
                  size: 112,
                  width: WoodTile.widthFor(parts[i], 112),
                  outline: success ? _green : null,
                ),
                () {
                  EventLogger.instance.ui('listen_letter', {'letter': parts[i].toUpperCase()});
                  _speech.speak(parts[i]);
                },
              ),
            ],
            IconButton(
              tooltip: 'Dengarkan kata',
              onPressed: _speakTarget,
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 36),
            ),
          ],
        );
      case _Target.sentence:
        final picture = pictureFor(_text);
        final words = sentenceWords(_text);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (picture != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(picture, style: const TextStyle(fontSize: 76)),
              ),
            SoftCard(
              radius: 26,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final w in words)
                    GestureDetector(
                      onTap: () {
                        final clean = w.replaceAll(RegExp(r'[^\p{L}\p{N}-]', unicode: true), '');
                        EventLogger.instance.ui('word', {'word': clean});
                        _speech.speak(clean);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: success ? const Color(0xFFC8F0D4) : const Color(0xFFF4F8FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(w,
                            style: GoogleFonts.fredoka(
                                fontSize: 46,
                                fontWeight: FontWeight.w700,
                                color: success ? const Color(0xFF1E7A43) : AppColors.textDark)),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Dengarkan kalimat',
                    onPressed: _speakTarget,
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 36),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listening = _phase == _Phase.listening;
    final parentMode = ParentMode.instance.enabled;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: 'Baca $_what ini',
          speech: 'Baca $_what ini',
          autoSpeak: widget.env.sound,
        ),
        const SizedBox(height: 16),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _target(),
            if (_phase == _Phase.success && widget.env.animate)
              const Positioned.fill(
                child: IgnorePointer(
                  child: SparkleBurst(radius: 110, count: 16),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (parentMode && !_finished)
          // mikrofon & penilaian orang tua berdampingan, supaya tetap besar di layar HP
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_phase != _Phase.unavailable) _micButton(listening, compact: true),
              const SizedBox(width: 12),
              _parentJudge(),
            ],
          )
        else if (_phase == _Phase.unavailable && !_finished)
          _doneButton()
        else if (_phase != _Phase.unavailable) ...[
          _micButton(listening),
          // 2x tidak terdengar / belum tepat: anak boleh lanjut (dinilai orang tua)
          if (_misses >= 2 && !_finished && !listening) _doneButton(),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            _status,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _statusColor,
            ),
          ),
        ),
        if (_heard.isNotEmpty && _phase != _Phase.success)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Terdengar: "$_heard"',
              style: GoogleFonts.fredoka(fontSize: 16, color: const Color(0xFF999999)),
            ),
          ),
        if (!_finished)
          TextButton(
            onPressed: () {
              widget.env.onMistake();
              _finish();
            },
            child: Text(
              'Lewati',
              style: GoogleFonts.fredoka(fontSize: 18, color: const Color(0xFF888888)),
            ),
          ),
      ],
    );
  }
}

/// Tiga lingkaran yang memancar keluar dari tombol mikrofon.
class _RipplePainter extends CustomPainter {
  final double t;
  _RipplePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var k = 0; k < 3; k++) {
      final p = (t + k / 3) % 1.0;
      canvas.drawCircle(
        c,
        46 + p * 48,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFE74C3C).withAlpha(((1 - p) * 150).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.t != t;
}
