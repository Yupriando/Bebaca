import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/story.dart';
import '../../services/sound_service.dart';
import '../../services/speech_service.dart';
import '../../services/story_service.dart';
import 'story_cover.dart';
import 'story_end_view.dart';
import 'story_narrator.dart';
import 'story_pages.dart';

/// "Baca Bersama": dongeng sebagai buku bergambar.
/// - 🔊 Dengarkan : narasi membacakan halaman, kata yang dibaca menyala (karaoke),
///                  lalu otomatis pindah ke halaman berikutnya.
/// - Ketuk kata  : dengar kata itu saja.
/// - 🎤 Aku baca  : anak membaca sendiri; kata yang sudah terbaca jadi hijau.
/// Halaman terakhir disimpan ke server, jadi bisa dilanjutkan nanti.
class StoryReaderPage extends StatefulWidget {
  final StoryDetail story;
  final int startPage;
  const StoryReaderPage({super.key, required this.story, this.startPage = 0});

  @override
  State<StoryReaderPage> createState() => _StoryReaderPageState();
}

class _StoryReaderPageState extends State<StoryReaderPage> {
  late final List<String> _pages = splitPages(widget.story.content);
  late final PageController _controller;
  final _narrator = StoryNarrator();
  final _service = StoryService();

  late int _page;
  bool _autoRead = false; // "Dengarkan" berjalan terus sampai halaman terakhir
  bool _ended = false;

  // mode "Aku baca"
  bool _listening = false;
  int _readCount = 0; // kata halaman ini yang sudah terbaca anak
  int? _tappedWord;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _page = widget.startPage.clamp(0, _pages.isEmpty ? 0 : _pages.length - 1);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _narrator.dispose();
    SpeechService.instance.cancelListening();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- halaman

  void _onPageChanged(int i) {
    _stopListening();
    setState(() {
      _page = i;
      _readCount = 0;
      _tappedWord = null;
    });
    // simpan halaman terakhir (ditunda sebentar supaya tidak tiap geser)
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      _service.saveProgress(widget.story.id, page: i).catchError((_) => null);
    });
    if (_autoRead) {
      _narrate();
    } else {
      _narrator.stop();
    }
  }

  void _go(int delta) {
    final target = _page + delta;
    if (target < 0) return;
    if (target >= _pages.length) {
      _finish();
      return;
    }
    SoundService.instance.play(Sfx.next, volume: 0.5);
    _controller.animateToPage(target,
        duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _finish() {
    _narrator.stop();
    _stopListening();
    setState(() {
      _autoRead = false;
      _ended = true;
    });
  }

  // ---------------------------------------------------------------- narasi

  Future<void> _narrate() async {
    final page = _page;
    await _narrator.play(_pages[page], onFinished: () {
      if (!mounted || !_autoRead || page != _page) return;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _autoRead && page == _page) _go(1);
      });
    });
  }

  void _toggleListen() {
    _stopListening();
    if (_narrator.playing || _autoRead) {
      setState(() => _autoRead = false);
      _narrator.stop();
    } else {
      setState(() => _autoRead = true);
      _narrate();
    }
  }

  void _tapWord(int i, String word) {
    if (_listening) return;
    setState(() {
      _autoRead = false;
      _tappedWord = i;
    });
    _narrator.stop();
    final clean = word.replaceAll(RegExp(r'[^\p{L}\p{N}-]', unicode: true), '');
    if (clean.isNotEmpty) SpeechService.instance.speak(clean);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _tappedWord == i) setState(() => _tappedWord = null);
    });
  }

  // ---------------------------------------------------------------- "Aku baca"

  Future<void> _toggleMic() async {
    if (_listening) {
      _stopListening();
      return;
    }
    setState(() => _autoRead = false);
    await _narrator.stop();
    if (!await SpeechService.instance.initListening()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mikrofon tidak tersedia. Periksa izin mikrofon ya.'),
        ));
      }
      return;
    }
    if (!mounted) return;
    SoundService.instance.play(Sfx.micOn);
    setState(() {
      _listening = true;
      _readCount = 0;
    });

    final words = wordsOf(_pages[_page]);
    final page = _page;
    await SpeechService.instance.listen(
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 4),
      onResult: (heard, isFinal) {
        if (!mounted || page != _page) return;
        final n = matchReadWords(words, heard);
        if (n > _readCount) setState(() => _readCount = n);
        if (n >= words.length || isFinal) _doneReading(words.length);
      },
    );
  }

  void _doneReading(int total) {
    if (!_listening) return;
    _stopListening();
    final good = total == 0 || _readCount / total >= 0.7;
    SoundService.instance.play(good ? Sfx.correct : Sfx.wrong, volume: good ? 0.8 : 0.4);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: good ? const Color(0xFF2E9E5B) : null,
        content: Text(good
            ? 'Hebat! Kamu sudah membaca halaman ini 🎉'
            : 'Hampir! Coba baca lagi pelan-pelan ya'),
      ));
  }

  void _stopListening() {
    if (!_listening) return;
    SpeechService.instance.stopListening();
    if (mounted) setState(() => _listening = false);
  }

  // ---------------------------------------------------------------- tampilan

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.story.title)),
        body: const Center(child: Text('Cerita belum tersedia.', style: TextStyle(fontSize: 22))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: SafeArea(
        child: _ended
            ? StoryEndView(
                story: widget.story,
                lastPage: _pages.length - 1,
                onReadAgain: () {
                  setState(() {
                    _ended = false;
                    _page = 0;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_controller.hasClients) _controller.jumpToPage(0);
                  });
                },
              )
            : Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) => _pageView(i),
                    ),
                  ),
                  _controls(),
                ],
              ),
      ),
    );
  }

  Widget _topBar() {
    final progress = (_page + 1) / _pages.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Tutup',
            iconSize: 34,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.itim(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 350),
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFEDE4D3),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text('${_page + 1} / ${_pages.length}',
              style: GoogleFonts.itim(
                  fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.hint)),
        ],
      ),
    );
  }

  Widget _pageView(int i) {
    final images = widget.story.pageImages;
    final image = i < images.length && images[i].isNotEmpty ? images[i] : widget.story.coverUrl;

    final picture = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: StoryCover(
        url: image,
        title: widget.story.title,
        seed: widget.story.id,
        showTitle: false,
      ),
    );
    final text = AnimatedBuilder(
      animation: _narrator,
      builder: (context, _) => _pageText(i),
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 760;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: wide
            ? Row(
                children: [
                  Expanded(flex: 5, child: AspectRatio(aspectRatio: 4 / 3, child: picture)),
                  const SizedBox(width: 28),
                  Expanded(flex: 6, child: Center(child: SingleChildScrollView(child: text))),
                ],
              )
            : Column(
                children: [
                  Flexible(flex: 5, child: Center(child: AspectRatio(aspectRatio: 4 / 3, child: picture))),
                  const SizedBox(height: 16),
                  Expanded(flex: 4, child: SingleChildScrollView(child: text)),
                ],
              ),
      );
    });
  }

  Widget _pageText(int i) {
    final words = wordsOf(_pages[i]);
    final isCurrent = i == _page;
    final narrating = isCurrent ? _narrator.wordIndex : -1;
    final size = MediaQuery.of(context).size.width < 500 ? 26.0 : 32.0;

    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 6,
      children: [
        for (var w = 0; w < words.length; w++)
          GestureDetector(
            onTap: () => _tapWord(w, words[w]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: w == narrating || (isCurrent && w == _tappedWord)
                    ? const Color(0xFFFFD54F)
                    : isCurrent && w < _readCount
                        ? const Color(0xFFC8F0D4)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                words[w],
                style: GoogleFonts.itim(
                  fontSize: size,
                  height: 1.35,
                  fontWeight: FontWeight.bold,
                  color: isCurrent && w < _readCount
                      ? const Color(0xFF1E7A43)
                      : AppColors.textDark,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _controls() {
    final last = _page == _pages.length - 1;
    return AnimatedBuilder(
      animation: _narrator,
      builder: (context, _) {
        final speaking = _narrator.playing || _autoRead;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              _navButton(Icons.chevron_left_rounded, _page > 0 ? () => _go(-1) : null),
              const Spacer(),
              _bigButton(
                icon: speaking ? Icons.pause_rounded : Icons.volume_up_rounded,
                label: speaking ? 'Berhenti' : 'Dengarkan',
                color: AppColors.primary,
                onTap: _toggleListen,
              ),
              const SizedBox(width: 14),
              _bigButton(
                icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
                label: _listening ? 'Selesai' : 'Aku baca',
                color: _listening ? Colors.redAccent : const Color(0xFF2E9E5B),
                onTap: _toggleMic,
              ),
              const Spacer(),
              last
                  ? _navButton(Icons.flag_rounded, () => _go(1), highlight: true)
                  : _navButton(Icons.chevron_right_rounded, () => _go(1)),
            ],
          ),
        );
      },
    );
  }

  Widget _navButton(IconData icon, VoidCallback? onTap, {bool highlight = false}) {
    return Material(
      color: onTap == null
          ? const Color(0xFFEDEDED)
          : highlight
              ? const Color(0xFFFFB300)
              : Colors.white,
      shape: const CircleBorder(),
      elevation: onTap == null ? 0 : 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon,
              size: 40,
              color: onTap == null
                  ? Colors.black26
                  : highlight
                      ? Colors.white
                      : AppColors.primary),
        ),
      ),
    );
  }

  Widget _bigButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.itim(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
