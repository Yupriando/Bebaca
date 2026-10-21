import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../core/config/app_orientation.dart';
import '../../core/theme/app_colors.dart';
import '../../services/event_logger.dart';

/// Pemutar video dongeng.
/// - Awalnya hanya menampilkan gambar sampul + tombol play (video belum diunduh,
///   hemat kuota). Video baru dimuat saat anak menekan play.
/// - Kontrol ala YouTube: jeda/lanjut, mundur & maju 10 detik, ketuk dua kali
///   sisi kiri/kanan untuk mundur/maju, geser bar di bawah untuk loncat.
///   Kontrol hilang sendiri 3 detik setelah video berjalan; ketuk untuk memunculkan.
/// - Tombol full layar: video memenuhi layar dan bar sistem disembunyikan.
///   Pemutar yang sama dipakai, jadi video lanjut dari detik yang sama.
class StoryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? posterUrl;
  final String? title; // judul dongeng (untuk Pantau Langsung orang tua)

  const StoryVideoPlayer({super.key, required this.videoUrl, this.posterUrl, this.title});

  @override
  State<StoryVideoPlayer> createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await controller.play();
      _videoEvent(controller, 'play', title: widget.title);
    } catch (_) {
      if (_controller == null) await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Video tidak bisa diputar';
      });
    }
  }

  Future<void> _openFullscreen(VideoPlayerController c) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => _FullscreenVideoPage(controller: c, title: widget.title),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildPoster() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.posterUrl != null)
          Image.network(
            widget.posterUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        Container(color: Colors.black26),
        Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : GestureDetector(
                  onTap: _start,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                    ),
                    child: Icon(
                      _error == null
                          ? Icons.play_arrow_rounded
                          : Icons.refresh_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        if (_error != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: c == null
              ? _buildPoster()
              : _VideoWithControls(
                  controller: c,
                  title: widget.title,
                  isFullscreen: false,
                  onFullscreenPressed: () => _openFullscreen(c),
                ),
        ),
      ),
    );
  }
}

/// Halaman full layar: hitam penuh, bar sistem disembunyikan.
/// Tombol back HP atau tombol ⛶ untuk keluar.
class _FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String? title;
  const _FullscreenVideoPage({required this.controller, this.title});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  @override
  void initState() {
    super.initState();
    // aplikasi sudah selalu landscape; cukup sembunyikan bar sistem
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _videoEvent(widget.controller, 'fullscreen', title: widget.title);
  }

  @override
  void dispose() {
    // kembali ke tampilan aplikasi biasa (landscape + layar penuh)
    applyAppSystemUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _VideoWithControls(
        controller: widget.controller,
        title: widget.title,
        isFullscreen: true,
        onFullscreenPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Video + kontrol (dipakai di tampilan biasa dan full layar).
/// Catat keadaan video untuk Pantau Langsung: play / pause / seek / fullscreen / selesai.
void _videoEvent(VideoPlayerController c, String state, {String? title}) {
  final v = c.value;
  EventLogger.instance.ui('video', {
    'state': state,
    if (title != null) 'title': title,
    'position': v.position.inSeconds,
    'duration': v.duration.inSeconds,
  });
}

class _VideoWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final String? title;
  final bool isFullscreen;
  final VoidCallback onFullscreenPressed;

  const _VideoWithControls({
    required this.controller,
    this.title,
    required this.isFullscreen,
    required this.onFullscreenPressed,
  });

  @override
  State<_VideoWithControls> createState() => _VideoWithControlsState();
}

class _VideoWithControlsState extends State<_VideoWithControls> {
  static const _skip = Duration(seconds: 10);

  bool _showControls = true;
  int _seekFlash = 0; // -1 / 1 sebentar setelah mundur / maju
  Timer? _hideTimer;
  Timer? _flashTimer;

  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
    if (_c.value.isPlaying) _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _flashTimer?.cancel();
    _c.removeListener(_onTick);
    super.dispose();
  }

  bool _endLogged = false;

  void _onTick() {
    final v = _c.value;
    final ended = v.duration > Duration.zero && v.position >= v.duration && !v.isPlaying;
    if (ended && !_endLogged) _videoEvent(_c, 'ended', title: widget.title);
    _endLogged = ended;
    if (mounted) setState(() {});
  }

  void _toggle() {
    final v = _c.value;
    if (v.isPlaying) {
      _c.pause();
      _videoEvent(_c, 'pause', title: widget.title);
      _hideTimer?.cancel();
      setState(() => _showControls = true);
      return;
    }
    if (v.duration > Duration.zero && v.position >= v.duration) {
      _c.seekTo(Duration.zero);
    }
    _c.play();
    _videoEvent(_c, 'play', title: widget.title);
    _scheduleHide();
  }

  /// Mundur (dir = -1) atau maju (dir = 1) 10 detik.
  void _seekBy(int dir) {
    final v = _c.value;
    var target = v.position + _skip * dir;
    if (target < Duration.zero) target = Duration.zero;
    if (target > v.duration) target = v.duration;
    _c.seekTo(target);
    EventLogger.instance.ui('video', {
      'state': dir < 0 ? 'back10' : 'forward10',
      if (widget.title != null) 'title': widget.title,
      'position': target.inSeconds,
      'duration': v.duration.inSeconds,
    });
    setState(() => _seekFlash = dir);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekFlash = 0);
    });
    if (v.isPlaying) _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _c.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onTapVideo() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _c.value.isPlaying) _scheduleHide();
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  Widget _roundButton(IconData icon, VoidCallback onTap,
      {double size = 56, double iconSize = 36}) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    final finished = v.duration > Duration.zero &&
        v.position >= v.duration &&
        !v.isPlaying;
    final visible = _showControls || !v.isPlaying;
    // full layar: tombol sedikit lebih besar & jauh dari tepi layar
    final big = widget.isFullscreen;
    final edge = big ? 28.0 : 14.0;
    final timeStyle = TextStyle(
        color: Colors.white,
        fontSize: big ? 16 : 14,
        fontWeight: FontWeight.bold);

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: v.aspectRatio,
            child: VideoPlayer(_c),
          ),
        ),
        // ketuk sekali: tampil/sembunyikan kontrol,
        // ketuk dua kali sisi kiri/kanan: mundur/maju 10 detik
        Row(
          children: [
            for (final dir in const [-1, 1])
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onTapVideo,
                  onDoubleTap: () => _seekBy(dir),
                ),
              ),
          ],
        ),
        IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(child: Container(color: Colors.black26)),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _roundButton(Icons.replay_10_rounded, () => _seekBy(-1),
                          size: big ? 68 : 56, iconSize: big ? 42 : 36),
                      SizedBox(width: big ? 56 : 36),
                      if (v.isBuffering && v.isPlaying)
                        SizedBox(
                          width: big ? 88 : 76,
                          height: big ? 88 : 76,
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      else
                        _roundButton(
                          finished
                              ? Icons.replay_rounded
                              : v.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          _toggle,
                          size: big ? 88 : 76,
                          iconSize: big ? 60 : 52,
                        ),
                      SizedBox(width: big ? 56 : 36),
                      _roundButton(Icons.forward_10_rounded, () => _seekBy(1),
                          size: big ? 68 : 56, iconSize: big ? 42 : 36),
                    ],
                  ),
                ),
                Positioned(
                  left: edge,
                  right: edge / 2,
                  bottom: big ? 12 : 2,
                  child: Row(
                    children: [
                      Text(_fmt(v.position), style: timeStyle),
                      const SizedBox(width: 10),
                      Expanded(
                        child: VideoProgressIndicator(
                          _c,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          colors: const VideoProgressColors(
                            playedColor: AppColors.primary,
                            bufferedColor: Colors.white54,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(_fmt(v.duration), style: timeStyle),
                      IconButton(
                        onPressed: widget.onFullscreenPressed,
                        tooltip: big ? 'Keluar layar penuh' : 'Layar penuh',
                        iconSize: big ? 36 : 30,
                        color: Colors.white,
                        icon: Icon(big
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_seekFlash != 0)
          Align(
            alignment: Alignment(_seekFlash * 0.65, 0),
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _seekFlash < 0 ? '« 10 detik' : '10 detik »',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
