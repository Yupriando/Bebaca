import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_body.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/story.dart';
import '../../services/story_service.dart';
import 'story_cover.dart';
import 'story_pages.dart';
import 'story_reader_page.dart';
import 'story_video_player.dart';

/// Halaman depan dongeng: sampul, info singkat, lalu pilih
/// 📖 Baca Bersama (buku bergambar + narasi) atau ▶ Tonton video.
/// Ditutup dengan `true` jika ada progres baru (supaya daftar dongeng dimuat ulang).
class StoryDetailPage extends StatefulWidget {
  final String storyId;
  final String title;

  const StoryDetailPage({super.key, required this.storyId, required this.title});

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  late Future<StoryDetail> _future = StoryService().getStory(widget.storyId);
  bool _changed = false;

  Future<void> _read(StoryDetail story, {required int startPage}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StoryReaderPage(story: story, startPage: startPage),
    ));
    if (!mounted) return;
    _changed = true;
    setState(() => _future = StoryService().getStory(widget.storyId)); // progres terbaru
  }

  void _watch(StoryDetail story) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _VideoPage(story: story),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF2),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    PrimaryButton(
                      label: 'Back',
                      onPressed: () => Navigator.pop(context, _changed),
                      width: 100,
                      height: 44,
                      fontSize: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AsyncBody<StoryDetail>(
                  future: _future,
                  builder: (context, story) => _Overview(
                    story: story,
                    onRead: (page) => _read(story, startPage: page),
                    onWatch: () => _watch(story),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final StoryDetail story;
  final ValueChanged<int> onRead;
  final VoidCallback onWatch;
  const _Overview({required this.story, required this.onRead, required this.onWatch});

  @override
  Widget build(BuildContext context) {
    final pages = splitPages(story.content);
    final minutes = readingMinutes(story.content);
    final p = story.progress;
    final hasVideo = story.videoUrl?.isNotEmpty == true;
    final resume = p != null && !p.completed && p.lastPage > 0 && p.lastPage < pages.length;

    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: StoryCover(
            url: story.coverUrl, title: story.title, seed: story.id, titleSize: 34),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(story.title,
            style: GoogleFonts.itim(
                fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (minutes > 0) _chip(Icons.timer_rounded, '$minutes menit'),
            if (pages.isNotEmpty) _chip(Icons.menu_book_rounded, '${pages.length} halaman'),
            if (hasVideo) _chip(Icons.smart_display_rounded, 'Ada video'),
            if (p?.completed == true)
              _chip(Icons.check_circle_rounded, 'Sudah dibaca',
                  color: const Color(0xFF2E9E5B)),
          ],
        ),
        if (p?.completed == true && p!.stars > 0) ...[
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < 3; i++)
              Icon(Icons.star_rounded,
                  size: 34,
                  color: i < p.stars ? const Color(0xFFFFB300) : const Color(0xFFDDDDDD)),
          ]),
        ],
        const SizedBox(height: 24),
        if (pages.isEmpty)
          const Text('Cerita untuk dibaca belum tersedia.',
              style: TextStyle(fontSize: 20, color: AppColors.hint))
        else ...[
          _ActionButton(
            icon: Icons.auto_stories_rounded,
            label: resume ? 'Lanjut Baca (hal. ${p.lastPage + 1})' : 'Baca Bersama',
            subtitle: 'Didengarkan & dibaca, kata menyala',
            color: AppColors.primary,
            onTap: () => onRead(resume ? p.lastPage : 0),
          ),
          if (resume)
            TextButton(
              onPressed: () => onRead(0),
              child: Text('Mulai dari awal', style: GoogleFonts.itim(fontSize: 18)),
            ),
        ],
        if (hasVideo) ...[
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.play_circle_fill_rounded,
            label: 'Tonton Video',
            subtitle: 'Dongeng dalam bentuk video',
            color: const Color(0xFFE5533D),
            onTap: onWatch,
          ),
        ],
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 820;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: cover),
                      const SizedBox(width: 32),
                      Expanded(flex: 5, child: info),
                    ],
                  )
                : Column(children: [cover, const SizedBox(height: 20), info]),
          ),
        ),
      );
    });
  }

  Widget _chip(IconData icon, String text, {Color color = AppColors.hint}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E1D3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.itim(fontSize: 17, color: color)),
        ]),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 44, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.itim(
                            fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(subtitle,
                        style: GoogleFonts.itim(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 36, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Video dongeng (pemutar dengan kontrol ala YouTube + layar penuh).
class _VideoPage extends StatelessWidget {
  final StoryDetail story;
  const _VideoPage({required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    iconSize: 34,
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(story.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.itim(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: StoryVideoPlayer(
                      key: ValueKey(story.videoUrl),
                      videoUrl: story.videoUrl!,
                      posterUrl: story.coverUrl,
                      title: story.title,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
