import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/settings_store.dart';
import '../../services/sound_service.dart';
import '../lesson/widgets/wood_tile.dart';

/// Splash screen animasi: langit malam berbintang, kotak huruf kayu melayang,
/// logo muncul membal, tulisan "Bebaca" muncul huruf demi huruf + nada pembuka.
/// Sambil animasi berjalan, aplikasi mengecek sesi login lalu pindah halaman.
///
/// - Mengikuti pengaturan Sound Effect & Animation terakhir (disimpan di perangkat).
/// - Animasi langsung berjalan tanpa perlu diketuk. (Di web, browser bisa memblokir
///   nada pembuka sebelum ada sentuhan; animasinya tetap jalan.)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // intro: berjalan sekali (3 detik) | loop: berulang untuk bintang & kotak melayang
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  late final List<_Sparkle> _sparkles;
  bool _started = false;
  bool _animate = true;

  static const _tiles = <_FloatTile>[
    _FloatTile('A', 0.07, 0.10, 62, -0.25, 0.00),
    _FloatTile('B', 0.76, 0.08, 56, 0.20, 0.30),
    _FloatTile('C', 0.04, 0.40, 48, 0.15, 0.80),
    _FloatTile('u', 0.84, 0.38, 50, -0.30, 0.45),
    _FloatTile('a', 0.12, 0.72, 58, 0.30, 0.60),
    _FloatTile('i', 0.78, 0.68, 64, -0.20, 0.15),
  ];

  @override
  void initState() {
    super.initState();
    final r = Random(42);
    _sparkles = List.generate(
      40,
      (_) => _Sparkle(
        r.nextDouble(),
        r.nextDouble(),
        3 + r.nextDouble() * 7,
        r.nextDouble(),
        1 + r.nextInt(2), // bilangan bulat -> animasi mulus saat berulang
      ),
    );
    _prepare();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    await SoundService.instance.load();
    await SettingsStore.instance.loadCache();
    if (!mounted) return;

    _animate = SettingsStore.instance.value.animation;
    _start();
  }

  void _start() {
    if (_started) return;
    _started = true;

    if (_animate) {
      _intro.forward();
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _intro.value = 1; // animasi dimatikan: langsung tampil utuh
    }
    _chime();
    _boot(minimum: Duration(milliseconds: _animate ? 3300 : 1300));
  }

  /// Nada berkilau saat logo muncul.
  Future<void> _chime() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) SoundService.instance.play(Sfx.chime, volume: 0.6);
  }

  Future<void> _boot({required Duration minimum}) async {
    final minimumTime = Future.delayed(minimum);
    final loggedIn = await AuthService().isLoggedIn();
    await minimumTime;
    if (!mounted) return;

    final route = loggedIn ? AppRoutes.main : AppRoutes.landing;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        settings: RouteSettings(name: route),
        transitionDuration: Duration(milliseconds: _animate ? 600 : 0),
        pageBuilder: (ctx, _, __) => AppRoutes.routes[route]!(ctx),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF08123A), Color(0xFF123A8C), Color(0xFF50A5DB)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _loop]),
          builder: (context, _) {
            final t = _intro.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _SparklePainter(_sparkles, _loop.value)),
                LayoutBuilder(
                  builder:
                      (context, box) => Stack(
                        children: [
                          for (var i = 0; i < _tiles.length; i++)
                            _floatingTile(_tiles[i], i, box, t),
                        ],
                      ),
                ),
                Center(child: _center(t)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 56,
                  child: Center(child: _loadingBar(t)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _floatingTile(_FloatTile tile, int i, BoxConstraints box, double t) {
    final appear = Interval(
      0.15 + i * 0.05,
      0.55 + i * 0.05,
      curve: Curves.easeOut,
    ).transform(t);
    final bob = sin(2 * pi * (_loop.value + tile.phase)) * 12;
    return Positioned(
      left: tile.fx * (box.maxWidth - tile.size),
      top: tile.fy * (box.maxHeight - tile.size),
      child: Opacity(
        opacity: (appear * 0.9).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, bob),
          child: WoodTile(
            letter: tile.letter,
            size: tile.size,
            rotation: tile.rotation,
          ),
        ),
      ),
    );
  }

  Widget _center(double t) {
    final logoScale = const Interval(
      0.0,
      0.45,
      curve: Curves.elasticOut,
    ).transform(t);
    final glow = 1 + 0.06 * sin(2 * pi * _loop.value * 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // cahaya di belakang logo
              Transform.scale(
                scale: glow,
                child: Opacity(
                  opacity: logoScale.clamp(0.0, 1.0),
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withAlpha(90),
                          Colors.white.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: logoScale,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 160,
                            height: 160,
                            color: const Color(0xFF123A8C),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 'Bebaca'.length; i++)
              _titleChar('Bebaca'[i], i, t),
          ],
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: const Interval(0.75, 1.0).transform(t),
          child: Text(
            'Belajar baca yang menyenangkan',
            textAlign: TextAlign.center,
            style: GoogleFonts.itim(
              fontSize: 22,
              color: Colors.white.withAlpha(215),
            ),
          ),
        ),
      ],
    );
  }

  Widget _titleChar(String ch, int i, double t) {
    final start = 0.38 + i * 0.05;
    final v = Interval(
      start,
      start + 0.22,
      curve: Curves.easeOutBack,
    ).transform(t);
    return Opacity(
      opacity: v.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - v) * 40),
        child: Text(
          ch,
          style: GoogleFonts.itim(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(color: Color(0xFF50A5DB), blurRadius: 18),
              Shadow(
                color: Color(0x66000000),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingBar(double t) {
    return SizedBox(
      width: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: Curves.easeInOut.transform(t),
          minHeight: 8,
          backgroundColor: Colors.white.withAlpha(50),
          color: const Color(0xFFFFC83D),
        ),
      ),
    );
  }
}

class _FloatTile {
  final String letter;
  final double fx, fy, size, rotation, phase;
  const _FloatTile(
    this.letter,
    this.fx,
    this.fy,
    this.size,
    this.rotation,
    this.phase,
  );
}

class _Sparkle {
  final double x, y, size, phase;
  final int speed;
  const _Sparkle(this.x, this.y, this.size, this.phase, this.speed);
}

/// Bintang kecil berkelap-kelip (bentuk berlian 4 sudut).
class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double t;
  _SparklePainter(this.sparkles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final twinkle = 0.5 + 0.5 * sin(2 * pi * (t * s.speed + s.phase));
      final r = s.size * (0.4 + 0.6 * twinkle);
      final cx = s.x * size.width;
      final cy = s.y * size.height;
      final path =
          Path()
            ..moveTo(cx, cy - r)
            ..quadraticBezierTo(cx, cy, cx + r, cy)
            ..quadraticBezierTo(cx, cy, cx, cy + r)
            ..quadraticBezierTo(cx, cy, cx - r, cy)
            ..quadraticBezierTo(cx, cy, cx, cy - r)
            ..close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withAlpha((60 + 190 * twinkle).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}
