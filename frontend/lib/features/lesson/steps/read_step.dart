import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/event_logger.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';
import '../widgets/wood_tile.dart';

enum _Phase { idle, listening, success, failed, notHeard, unavailable }

/// "Baca huruf ini": anak mengucapkan huruf, dikenali lewat mikrofon.
/// Kalau mikrofon tidak tersedia, anak bisa menekan "Aku sudah membaca".
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
  int _misses =
      0; // berapa kali tidak terdengar / belum tepat -> tampilkan tombol lanjut
  Timer? _timeout;

  // gelombang yang memancar dari tombol mikrofon saat mendengarkan
  late final AnimationController _ripple;

  String get _letter => widget.step.letter.toUpperCase();

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
    widget.env.report({'note': 'Mikrofon aktif, sedang mengucapkan huruf'});

    // Batas waktu: kalau tidak ada suara sama sekali, beri tahu anak.
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 8), () async {
      if (_phase != _Phase.listening) return;
      await _speech.stopListening();
      _notHeard();
    });

    final name = SpeechService.letterName(_letter);
    await _speech.listen(
      onResult: _onResult,
      alternates: true, // 1 huruf sering salah tulis: periksa semua tebakan
      hints: [name, _letter.toLowerCase(), 'huruf $name'],
      onError: (_) => _notHeard(),
      onDone: () {
        // selesai tanpa hasil yang cocok -> jangan diam saja
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _phase == _Phase.listening) _notHeard();
        });
      },
    );
  }

  /// Tidak ada suara yang dikenali (umum untuk ucapan 1 huruf yang sangat pendek).
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

    if (spokenLetterMatches(words, _letter)) {
      _timeout?.cancel();
      _speech.stopListening();
      HapticFeedback.mediumImpact();
      widget.env.sfx(Sfx.success);
      setState(() => _heard = words);
      widget.env.report({'heard': words.split(' ').first, 'note': 'Berhasil mengucapkan huruf $_letter'});
      _setPhase(_Phase.success);
      _finish(correct: true);
    } else if (isFinal) {
      _timeout?.cancel();
      if (words.trim().isEmpty) {
        _notHeard();
      } else {
        _misses++;
        widget.env.sfx(Sfx.wrong, volume: 0.6);
        widget.env.onMistake(words.split(' ').first); // yang terdengar mikrofon
        setState(() => _heard = words.split(' ').first);
        _setPhase(_Phase.failed);
      }
    } else {
      setState(() => _heard = words);
      final now = DateTime.now();
      if (words.trim().isNotEmpty &&
          (_lastHeardReport == null || now.difference(_lastHeardReport!).inMilliseconds > 1000)) {
        _lastHeardReport = now;
        widget.env.report({'heard': words.split(' ').first, 'live': true});
      }
    }
  }

  DateTime? _lastHeardReport;

  String get _status {
    switch (_phase) {
      case _Phase.idle:
        return 'Ketuk mikrofon, lalu ucapkan hurufnya';
      case _Phase.listening:
        return 'Aku mendengarkan...';
      case _Phase.success:
        return 'Bagus sekali!';
      case _Phase.failed:
        return 'Hampir! Coba lagi ya';
      case _Phase.notHeard:
        return 'Aku belum mendengar suaramu. Ketuk mikrofon, lalu ucapkan "${SpeechService.letterName(_letter)}" dengan keras ya!';
      case _Phase.unavailable:
        return 'Mikrofon tidak tersedia. Bacalah hurufnya dengan suara keras, lalu ketuk tombol di bawah.';
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

  Widget _micButton(bool listening) {
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
      width: 190,
      height: 150,
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
        child: const Text('Aku sudah membaca', style: TextStyle(fontSize: 20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listening = _phase == _Phase.listening;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: 'Baca huruf ini',
          speech: 'Baca huruf ini',
          autoSpeak: widget.env.sound,
        ),
        const SizedBox(height: 16),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            BouncyTap(
              animate: widget.env.animate,
              onTap: () {
                widget.env.sfx(Sfx.tap);
                EventLogger.instance.ui('listen_letter', {'letter': _letter});
                _speech.speakLetter(_letter);
              },
              child: WoodTile(
                letter: _letter,
                size: 140,
                outline: _phase == _Phase.success ? _green : null,
                badge: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            if (_phase == _Phase.success && widget.env.animate)
              const Positioned.fill(
                child: IgnorePointer(
                  child: SparkleBurst(radius: 110, count: 16),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_phase == _Phase.unavailable && !_finished)
          _doneButton()
        else ...[
          _micButton(listening),
          // 2x tidak terdengar / belum tepat: anak boleh lanjut (dinilai orang tua)
          if (_misses >= 2 && !_finished && !listening) _doneButton(),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
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
              style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
            ),
          ),
        if (!_finished)
          TextButton(
            onPressed: () {
              widget.env.onMistake();
              _finish();
            },
            child: const Text(
              'Lewati',
              style: TextStyle(fontSize: 18, color: Color(0xFF888888)),
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
