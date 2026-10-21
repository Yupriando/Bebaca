import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../services/sound_service.dart';
import 'widgets/confetti.dart';
import 'widgets/effects.dart';

/// Layar setelah lesson selesai: fanfare, bintang yang muncul satu-satu
/// dengan ledakan kilau, sinar berputar, konfeti, dan status penyimpanan.
class LessonResultView extends StatefulWidget {
  final int stars;
  final int? streak;
  final bool saving;
  final String? error;
  final bool animate;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const LessonResultView({
    super.key,
    required this.stars,
    required this.streak,
    required this.saving,
    required this.error,
    required this.animate,
    required this.onRetry,
    required this.onClose,
  });

  @override
  State<LessonResultView> createState() => _LessonResultViewState();
}

class _LessonResultViewState extends State<LessonResultView> {
  @override
  void initState() {
    super.initState();
    _playSounds();
  }

  /// Fanfare di awal, lalu satu nada "ting" per bintang (nadanya makin tinggi).
  void _playSounds() {
    final sound = SoundService.instance;
    sound.play(widget.stars >= 2 ? Sfx.fanfare : Sfx.success);
    const starSfx = [Sfx.star1, Sfx.star2, Sfx.star3];
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 500 + i * 300), () {
        if (mounted) sound.play(starSfx[i]);
      });
    }
  }

  String get _message {
    switch (widget.stars) {
      case 3:
        return 'Sempurna! Tanpa salah sama sekali.';
      case 2:
        return 'Bagus! Sedikit lagi sempurna.';
      default:
        return 'Terus berlatih ya, kamu pasti bisa!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final animate = widget.animate;

    return Stack(
      children: [
        if (animate)
          const Positioned.fill(child: IgnorePointer(child: ConfettiOverlay())),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 340,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (animate) const Sunburst(size: 340),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: animate ? 0.0 : 1.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, v, child) =>
                                Transform.scale(scale: v, child: child),
                            child: const Text(
                              'Hebat!',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < 3; i++)
                                _Star(
                                  filled: i < widget.stars,
                                  index: i,
                                  animate: animate,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(_message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, color: Color(0xFF555555))),
                if (widget.streak != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Flame(animate: animate),
                      const SizedBox(width: 6),
                      Text(
                        'Belajar berturut-turut: ${widget.streak} hari',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8F00),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                if (widget.saving)
                  const CircularProgressIndicator()
                else if (widget.error != null) ...[
                  Text(widget.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: widget.onRetry, child: const Text('Coba lagi')),
                  TextButton(
                      onPressed: widget.onClose,
                      child: const Text('Keluar tanpa menyimpan')),
                ] else
                  PrimaryButton(
                      label: 'Lanjut', onPressed: widget.onClose, width: 240),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bintang: muncul berputar + membal, lalu meledak jadi kilau.
class _Star extends StatefulWidget {
  final bool filled;
  final int index;
  final bool animate;
  const _Star({required this.filled, required this.index, required this.animate});

  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> {
  bool _burst = false;

  @override
  void initState() {
    super.initState();
    if (widget.filled && widget.animate) {
      Future.delayed(Duration(milliseconds: 500 + widget.index * 300), () {
        if (mounted) setState(() => _burst = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: widget.animate ? 0.0 : 1.0, end: 1.0),
          // bintang berikutnya muncul sedikit lebih lambat
          duration: Duration(milliseconds: 500 + widget.index * 300),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.rotate(
            angle: (1 - v) * -0.9,
            child: Transform.scale(scale: v, child: child),
          ),
          child: Icon(
            Icons.star_rounded,
            size: 76,
            color: widget.filled ? const Color(0xFFFFB300) : const Color(0xFFD5D5D5),
          ),
        ),
        if (_burst)
          const Positioned.fill(
            child: IgnorePointer(child: SparkleBurst(radius: 80, count: 10)),
          ),
      ],
    );
  }
}

/// Api streak yang berdenyut.
class _Flame extends StatefulWidget {
  final bool animate;
  const _Flame({required this.animate});

  @override
  State<_Flame> createState() => _FlameState();
}

class _FlameState extends State<_Flame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 0.9 + 0.25 * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: const Icon(Icons.local_fire_department_rounded,
          color: Color(0xFFFF8F00), size: 32),
    );
  }
}
