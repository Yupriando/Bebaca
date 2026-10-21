import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/sound_service.dart';
import '../../../services/speech_service.dart';
import '../lesson_steps.dart';
import '../widgets/effects.dart';
import '../widgets/step_common.dart';

// ======================= TATA LETAK KANVAS =======================
// Ukuran logis tetap, lalu diskalakan (FittedBox) sesuai layar.
// Angka diukur dari font Itim: huruf naik maks 161 px dan turun maks 54 px (huruf "g")
// dari garis dasar, jadi semua huruf muat tanpa terpotong.
const _canvasSize = Size(360, 300);
const _baseline = 215.0; // garis bawah (alas huruf)
const _topLine = 45.0; // garis atas
const _fontSize = 238.0;

// ======================= KETELITIAN =======================
// Dibuat ramah anak: goresan yang agak miring / tidak rapi / tidak sampai ujung tetap lulus,
// asalkan bentuk hurufnya kelihatan. Yang tetap ditolak:
//  - ada bagian huruf yang dilewati sama sekali (mis. garis silang huruf A tidak dibuat),
//  - hanya separuh huruf,
//  - coretan asal / mewarnai seluruh kotak.
// Ubah angka di bawah untuk mengatur seberapa ketat penilaian.
const _brush = 20.0; // tebal goresan jari yang TERLIHAT (px kanvas)
const _judgeBrush = 34.0; // tebal goresan saat DINILAI (lebih tebal = meleset sedikit tetap kena)
const _slack = 14.0; // goresan boleh keluar dari tepi huruf sejauh ini (px)
const _coreRatio = 0.5; // "garis tengah" huruf = bagian terdalam badan huruf (0..1, makin besar makin tipis)
const _needCore = 0.8; // minimal % garis tengah huruf yang harus tertelusuri
const _needCell = 0.35; // tiap bagian huruf (sel 24x24 px) minimal tersentuh sebesar ini
const _needPrecision = 0.7; // minimal % goresan yang berada di dekat huruf
const _cellMinPixels = 4; // sel dengan titik garis tengah lebih sedikit dari ini diabaikan
const _scale = 0.5; // bitmap penilaian = setengah ukuran kanvas (cepat)
const _cell = 12; // ukuran sel penilaian (px bitmap)

const _green = Color(0xFF2ECC71);
const _orange = Color(0xFFFF9800);

double get _canvasW => _canvasSize.width;

TextPainter _guidePainter(String glyph, {required Color color}) {
  final style = GoogleFonts.itim(fontSize: _fontSize, color: color);
  return TextPainter(
    text: TextSpan(text: glyph, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
}

/// Huruf diletakkan di tengah, alasnya tepat di garis bawah.
Offset _guideOffset(TextPainter tp) => Offset(
      (_canvasW - tp.width) / 2,
      _baseline - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic),
    );

void _drawStrokes(Canvas canvas, List<List<Offset>> strokes, Color color,
    {double width = _brush}) {
  final line = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final dot = Paint()..color = color;

  for (final s in strokes) {
    if (s.isEmpty) continue;
    if (s.length == 1) {
      canvas.drawCircle(s.first, width / 2, dot);
      continue;
    }
    final path = Path()..moveTo(s.first.dx, s.first.dy);
    for (final p in s.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);
  }
}

// ======================= PENILAIAN =======================

/// Jarak (chamfer 1 / 1,414) dari tiap piksel ke piksel "seed" terdekat.
Float32List _distanceTo(Uint8List seed, int w, int h) {
  const inf = 1e9;
  const diag = 1.41421356;
  final d = Float32List(w * h);
  for (var i = 0; i < d.length; i++) {
    d[i] = seed[i] == 1 ? 0 : inf;
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      var v = d[i];
      if (x > 0) v = math.min(v, d[i - 1] + 1);
      if (y > 0) {
        v = math.min(v, d[i - w] + 1);
        if (x > 0) v = math.min(v, d[i - w - 1] + diag);
        if (x < w - 1) v = math.min(v, d[i - w + 1] + diag);
      }
      d[i] = v;
    }
  }
  for (var y = h - 1; y >= 0; y--) {
    for (var x = w - 1; x >= 0; x--) {
      final i = y * w + x;
      var v = d[i];
      if (x < w - 1) v = math.min(v, d[i + 1] + 1);
      if (y < h - 1) {
        v = math.min(v, d[i + w] + 1);
        if (x < w - 1) v = math.min(v, d[i + w + 1] + diag);
        if (x > 0) v = math.min(v, d[i + w - 1] + diag);
      }
      d[i] = v;
    }
  }
  return d;
}

/// Bentuk huruf yang sudah dihitung sekali: garis tengah, area yang diizinkan, dan sel-sel.
class _Masks {
  final int w;
  final int h;
  final Uint8List allowed; // 1 = di dalam / dekat huruf
  final Int32List coreIdx; // indeks piksel garis tengah
  final Int32List coreCell; // sel milik tiap piksel garis tengah
  final List<int> cellTotal; // jumlah piksel garis tengah per sel
  final List<double> cellCx; // pusat sel (koordinat bitmap)
  final List<double> cellCy;
  final List<int> validCells; // sel yang cukup besar untuk dinilai

  _Masks({
    required this.w,
    required this.h,
    required this.allowed,
    required this.coreIdx,
    required this.coreCell,
    required this.cellTotal,
    required this.cellCx,
    required this.cellCy,
    required this.validCells,
  });

  bool get usable => coreIdx.isNotEmpty;
}

class _Eval {
  final double coverage; // % garis tengah tertelusuri
  final double minCell; // sel terburuk
  final double precision; // % goresan yang dekat huruf
  final List<Offset> hints; // bagian yang terlewat (koordinat kanvas)

  const _Eval(this.coverage, this.minCell, this.precision, this.hints);

  bool get ok =>
      coverage >= _needCore && minCell >= _needCell && precision >= _needPrecision;
}

Future<Uint8List> _renderMask(int w, int h, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(_scale);
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();

  final rgba = data!.buffer.asUint8List();
  final mask = Uint8List(w * h);
  for (var i = 0; i < mask.length; i++) {
    mask[i] = rgba[i * 4 + 3] > 127 ? 1 : 0;
  }
  return mask;
}

Future<_Masks> _buildMasks(String glyph) async {
  try {
    // pastikan font sudah siap sebelum bentuk huruf diukur
    await GoogleFonts.pendingFonts([GoogleFonts.itim()]);
  } catch (_) {}

  final w = (_canvasSize.width * _scale).round();
  final h = (_canvasSize.height * _scale).round();
  final n = w * h;

  final inside = await _renderMask(w, h, (c) {
    final tp = _guidePainter(glyph, color: const Color(0xFF000000));
    tp.paint(c, _guideOffset(tp));
  });

  // jarak ke luar huruf -> garis tengah = bagian terdalam badan huruf
  final outsideSeed = Uint8List(n);
  for (var i = 0; i < n; i++) {
    outsideSeed[i] = inside[i] == 1 ? 0 : 1;
  }
  final dIn = _distanceTo(outsideSeed, w, h);

  final depths = <double>[];
  for (var i = 0; i < n; i++) {
    if (inside[i] == 1) depths.add(dIn[i]);
  }
  final cols = (w / _cell).ceil();
  final rows = (h / _cell).ceil();
  final cellCount = cols * rows;

  if (depths.isEmpty) {
    return _Masks(
      w: w, h: h, allowed: Uint8List(n), coreIdx: Int32List(0), coreCell: Int32List(0),
      cellTotal: List.filled(cellCount, 0), cellCx: List.filled(cellCount, 0),
      cellCy: List.filled(cellCount, 0), validCells: const [],
    );
  }

  depths.sort();
  final ref = depths[(depths.length * 0.9).floor().clamp(0, depths.length - 1)];
  final threshold = ref * _coreRatio;

  final core = <int>[];
  final coreCellList = <int>[];
  final cellTotal = List<int>.filled(cellCount, 0);
  final sumX = List<double>.filled(cellCount, 0);
  final sumY = List<double>.filled(cellCount, 0);
  for (var i = 0; i < n; i++) {
    if (inside[i] == 1 && dIn[i] >= threshold) {
      final x = i % w;
      final y = i ~/ w;
      final c = (y ~/ _cell) * cols + (x ~/ _cell);
      core.add(i);
      coreCellList.add(c);
      cellTotal[c]++;
      sumX[c] += x;
      sumY[c] += y;
    }
  }

  // area yang diizinkan = huruf + pelebaran (setengah tebal kuas + kelonggaran)
  final dOut = _distanceTo(inside, w, h);
  final reach = (_judgeBrush / 2 + _slack) * _scale;
  final allowed = Uint8List(n);
  for (var i = 0; i < n; i++) {
    allowed[i] = (inside[i] == 1 || dOut[i] <= reach) ? 1 : 0;
  }

  final valid = <int>[];
  final cx = List<double>.filled(cellCount, 0);
  final cy = List<double>.filled(cellCount, 0);
  for (var c = 0; c < cellCount; c++) {
    if (cellTotal[c] > 0) {
      cx[c] = sumX[c] / cellTotal[c];
      cy[c] = sumY[c] / cellTotal[c];
    }
    if (cellTotal[c] >= _cellMinPixels) valid.add(c);
  }

  return _Masks(
    w: w,
    h: h,
    allowed: allowed,
    coreIdx: Int32List.fromList(core),
    coreCell: Int32List.fromList(coreCellList),
    cellTotal: cellTotal,
    cellCx: cx,
    cellCy: cy,
    validCells: valid,
  );
}

_Eval _evaluate(_Masks m, Uint8List ink) {
  var covered = 0;
  final cellCovered = List<int>.filled(m.cellTotal.length, 0);
  for (var k = 0; k < m.coreIdx.length; k++) {
    if (ink[m.coreIdx[k]] == 1) {
      covered++;
      cellCovered[m.coreCell[k]]++;
    }
  }
  final coverage = covered / m.coreIdx.length;

  var minCell = 1.0;
  final cells = <(double, int)>[];
  for (final c in m.validCells) {
    final frac = cellCovered[c] / m.cellTotal[c];
    if (frac < minCell) minCell = frac;
    cells.add((frac, c));
  }
  cells.sort((a, b) => a.$1.compareTo(b.$1));
  // titik oranye: bagian yang jelas terlewat; kalau tidak ada, 3 bagian yang paling tipis
  final weak = cells.where((e) => e.$1 < 0.5).toList();
  final shown = weak.isNotEmpty ? weak.take(6) : cells.where((e) => e.$1 < 0.9).take(3);
  final hints = [
    for (final e in shown) Offset(m.cellCx[e.$2] / _scale, m.cellCy[e.$2] / _scale),
  ];

  var inkCount = 0;
  var inkValid = 0;
  for (var i = 0; i < ink.length; i++) {
    if (ink[i] == 1) {
      inkCount++;
      if (m.allowed[i] == 1) inkValid++;
    }
  }
  final precision = inkCount == 0 ? 1.0 : inkValid / inkCount;

  return _Eval(coverage, minCell, precision, hints);
}

// ======================= TAMPILAN =======================

class _TracePainter extends CustomPainter {
  final String glyph;
  final List<List<Offset>> strokes;
  final List<Offset> hints;
  final double pulse; // 0..1, untuk titik petunjuk yang berdenyut
  _TracePainter(this.glyph, this.strokes, this.hints, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    // dua garis bantu (atas & bawah)
    final linePaint = Paint()
      ..color = const Color(0xFF8E8E8E)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(24, _topLine), Offset(size.width - 24, _topLine), linePaint);
    canvas.drawLine(const Offset(24, _baseline), Offset(size.width - 24, _baseline), linePaint);

    // huruf panduan (abu-abu)
    final tp = _guidePainter(glyph, color: const Color(0xFFC9C9C9));
    tp.paint(canvas, _guideOffset(tp));

    // goresan anak
    _drawStrokes(canvas, strokes, AppColors.primary.withAlpha(235));

    // titik oranye = bagian yang masih terlewat
    for (final h in hints) {
      canvas.drawCircle(
        h,
        13 + 7 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = _orange.withAlpha((230 - 110 * pulse).round()),
      );
      canvas.drawCircle(h, 6, Paint()..color = _orange);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}

/// "Gambarkan huruf A / a": anak menelusuri huruf dengan jari.
/// Dinyatakan benar jika bentuk hurufnya sudah kelihatan (tidak harus rapi):
///  - sebagian besar garis tengah huruf tertutup goresan,
///  - setiap bagian huruf setidaknya tersentuh (mis. garis silang huruf A),
///  - goresan tidak mencoret sembarangan.
class TraceStep extends StatefulWidget {
  final LessonStep step;
  final StepEnv env;
  final bool upper;
  const TraceStep({
    super.key,
    required this.step,
    required this.env,
    required this.upper,
  });

  @override
  State<TraceStep> createState() => _TraceStepState();
}

class _TraceStepState extends State<TraceStep> with SingleTickerProviderStateMixin {
  final List<List<Offset>> _strokes = [];
  Future<_Masks>? _masksFuture;

  double _coverage = 0;
  List<Offset> _hints = const [];
  String _message = 'Telusuri huruf abu-abu dengan jarimu';
  Color _messageColor = const Color(0xFF777777);

  bool _done = false;
  bool _celebrate = false; // true hanya jika benar-benar berhasil (bukan dilewati)
  int _attempts = 0; // berapa kali selesai menggores tetapi belum tepat
  int _clears = 0;
  int _checkId = 0;
  Timer? _liveTimer;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  String get _glyph => widget.upper
      ? widget.step.letter.toUpperCase()
      : widget.step.letter.toLowerCase();

  @override
  void initState() {
    super.initState();
    _masksFuture = _buildMasks(_glyph); // dihitung di awal supaya penilaian cepat
    if (widget.env.animate) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// [finish] = true saat jari diangkat: boleh menyatakan selesai & menampilkan petunjuk.
  /// false = hanya memperbarui bar progres selagi menggores.
  Future<void> _check({required bool finish}) async {
    if (_done || _strokes.isEmpty) return;
    final id = ++_checkId;
    final masks = await _masksFuture!;
    if (!mounted || id != _checkId) return;

    // Font gagal dimuat -> bentuk huruf tidak bisa dinilai; terima goresan yang cukup panjang.
    if (!masks.usable) {
      if (finish) _complete();
      return;
    }

    final ink = await _renderMask(masks.w, masks.h, (c) {
      _drawStrokes(c, _strokes, const Color(0xFF000000), width: _judgeBrush);
    });
    if (!mounted || id != _checkId) return; // ada goresan baru / dihapus

    final e = _evaluate(masks, ink);
    if (!finish) {
      setState(() => _coverage = e.coverage);
      return;
    }

    if (e.ok) {
      _complete();
      return;
    }

    _attempts++;
    widget.env.report({
      'note': 'Tulisan belum tepat (percobaan ke-$_attempts, ${(e.coverage * 100).round()}% tertelusuri)',
    });
    setState(() {
      _coverage = e.coverage;
      _hints = e.hints;
      if (e.precision < _needPrecision) {
        _message = 'Ikuti garis hurufnya ya, jangan keluar jalur';
      } else {
        _message = 'Masih ada bagian yang belum ditelusuri (ikuti titik oranye)';
      }
      _messageColor = const Color(0xFFE65100);
    });
  }

  void _complete() {
    HapticFeedback.mediumImpact();
    setState(() {
      _done = true;
      _celebrate = true;
      _hints = const [];
      _message = 'Hebat! Hurufnya sudah jadi';
      _messageColor = _green;
    });
    widget.env.sfx(Sfx.success);
    widget.env.onCorrect();
    widget.env.onDone();
  }

  void _scheduleLive() {
    _liveTimer ??= Timer(const Duration(milliseconds: 300), () {
      _liveTimer = null;
      _check(finish: false);
    });
  }

  void _clear() {
    _checkId++; // batalkan penilaian yang sedang berjalan
    _liveTimer?.cancel();
    _liveTimer = null;
    setState(() {
      _strokes.clear();
      _coverage = 0;
      _hints = const [];
      _clears++;
      _message = 'Telusuri huruf abu-abu dengan jarimu';
      _messageColor = const Color(0xFF777777);
    });
  }

  void _skip() {
    widget.env.onMistake();
    setState(() {
      _done = true;
      _hints = const [];
    });
    widget.env.onDone();
  }

  Widget _canvas() {
    return Container(
      width: _canvasSize.width,
      height: _canvasSize.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) {
                if (_done) return;
                setState(() => _strokes.add([d.localPosition]));
              },
              onPanUpdate: (d) {
                if (_done || _strokes.isEmpty) return;
                final p = d.localPosition;
                if ((p - _strokes.last.last).distance > 2) {
                  setState(() => _strokes.last.add(p));
                  _scheduleLive();
                }
              },
              onPanEnd: (_) {
                _liveTimer?.cancel();
                _liveTimer = null;
                _check(finish: true);
              },
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => CustomPaint(
                  painter: _TracePainter(
                    _glyph,
                    _strokes,
                    _hints,
                    widget.env.animate ? _pulse.value : 0.5,
                  ),
                ),
              ),
            ),
          ),
          if (_celebrate && widget.env.animate)
            const Positioned.fill(
              child: IgnorePointer(child: SparkleBurst(radius: 170, count: 18)),
            ),
          if (_done)
            Positioned(
              top: 8,
              right: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: widget.env.animate ? 0.0 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: const Icon(Icons.check_circle_rounded, color: _green, size: 40),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // bar penuh hanya jika benar-benar selesai (tidak pernah 100% sebelum lulus)
    final progress = _done ? 1.0 : (_coverage / _needCore).clamp(0.0, 0.97);
    final showSkip = !_done && (_attempts >= 3 || _clears >= 2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StepPrompt(
          text: 'Gambarkan huruf $_glyph',
          speech: 'Gambarkan huruf ${SpeechService.letterName(widget.step.letter)}',
          autoSpeak: widget.env.sound,
        ),
        const SizedBox(height: 8),
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, child: _canvas()),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE0E0E0),
              color: _done ? _green : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: _messageColor),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _done ? null : _clear,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Hapus', style: TextStyle(fontSize: 18)),
            ),
            if (showSkip)
              TextButton(
                onPressed: _skip,
                child: const Text('Lewati',
                    style: TextStyle(fontSize: 18, color: Color(0xFF888888))),
              ),
          ],
        ),
      ],
    );
  }
}
