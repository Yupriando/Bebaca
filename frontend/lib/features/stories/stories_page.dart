import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_body.dart';
import '../../models/story.dart';
import '../../services/premium_store.dart';
import '../../services/story_service.dart';
import '../premium/premium_prompt.dart';
import 'story_cover.dart';
import 'story_detail_page.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  final _premium = PremiumStore.instance;
  late bool _wasPremium = _premium.isPremium;
  late Future<List<StoryCategory>> _future = StoryService().getCategories();

  @override
  void initState() {
    super.initState();
    _premium.addListener(_onPremium);
  }

  @override
  void dispose() {
    _premium.removeListener(_onPremium);
    super.dispose();
  }

  // baru berlangganan / langganan habis -> muat ulang supaya gembok ikut berubah
  void _onPremium() {
    if (_premium.isPremium == _wasPremium) return;
    _wasPremium = _premium.isPremium;
    _reload();
  }

  /// Muat ulang (mis. setelah selesai membaca: tanda ✅ & "Lanjutkan membaca" berubah).
  void _reload() {
    if (mounted) setState(() => _future = StoryService().getCategories());
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<List<StoryCategory>>(
      future: _future,
      builder: (context, categories) {
        // "Lanjutkan membaca": dongeng yang sudah dibuka tetapi belum selesai
        final seen = <String>{};
        final reading = [
          for (final c in categories)
            for (final s in c.stories)
              if (!s.locked &&
                  s.progress != null &&
                  !s.progress!.completed &&
                  s.progress!.lastPage > 0 &&
                  seen.add(s.id))
                s,
        ];
        final rows = [
          if (reading.isNotEmpty)
            StoryCategory(name: '📖 Lanjutkan membaca', stories: reading),
          ...categories,
        ];
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 24),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.black54),
          ),
          itemBuilder: (context, i) => _CategoryRow(
            key: ValueKey(rows[i].name),
            category: rows[i],
            onChanged: _reload,
          ),
        );
      },
    );
  }
}

/// Satu baris kategori yang bisa digeser ke samping: dengan jari, ditarik
/// pakai mouse, roda mouse, atau tombol panah kiri/kanan.
class _CategoryRow extends StatefulWidget {
  final StoryCategory category;
  final VoidCallback onChanged;
  const _CategoryRow({super.key, required this.category, required this.onChanged});

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  static const _cardStep = 235.0 + 20.0; // lebar kartu + jarak
  final _scroll = ScrollController();
  bool _canLeft = false;
  bool _canRight = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final left = p.pixels > 4;
    final right = p.pixels < p.maxScrollExtent - 4;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _scrollBy(int dir) {
    final p = _scroll.position;
    final step = (p.viewportDimension - 64)
        .clamp(_cardStep, double.infinity)
        .toDouble();
    _scroll.animateTo(
      (p.pixels + step * dir).clamp(0.0, p.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Roda mouse (atas/bawah) ikut menggeser baris ke samping.
  void _onWheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || !_scroll.hasClients) return;
    final delta = e.scrollDelta.dx != 0 ? e.scrollDelta.dx : e.scrollDelta.dy;
    final p = _scroll.position;
    final target = (p.pixels + delta).clamp(0.0, p.maxScrollExtent);
    if (target != p.pixels) {
      GestureBinding.instance.pointerSignalResolver.register(e, (_) {
        _scroll.jumpTo(target);
      });
    }
  }

  Widget _arrow(IconData icon, int dir) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _scrollBy(dir),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 32, color: AppColors.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.category.stories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(widget.category.name,
              style: const TextStyle(fontSize: 22, color: Colors.black)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              _updateArrows();
              return false;
            },
            child: Stack(
              children: [
                Listener(
                  onPointerSignal: _onWheel,
                  child: ScrollConfiguration(
                    // izinkan tarik pakai mouse/trackpad (web & desktop)
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: PointerDeviceKind.values.toSet(),
                      scrollbars: false,
                    ),
                    child: ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      itemCount: stories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 20),
                      itemBuilder: (context, i) =>
                          _StoryCard(story: stories[i], onChanged: widget.onChanged),
                    ),
                  ),
                ),
                if (_canLeft)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                        child: _arrow(Icons.chevron_left_rounded, -1)),
                  ),
                if (_canRight)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                        child: _arrow(Icons.chevron_right_rounded, 1)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Story story;
  final VoidCallback onChanged;
  const _StoryCard({required this.story, required this.onChanged});

  Future<void> _open(BuildContext context) async {
    if (story.locked) {
      showPremiumPrompt(context, what: 'Cerita "${story.title}"');
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StoryDetailPage(storyId: story.id, title: story.title),
      ),
    );
    if (changed == true) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = story.progress;
    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 235,
          height: 190,
          child: Stack(
            fit: StackFit.expand,
            children: [
              StoryCover(url: story.coverUrl, title: story.title, seed: story.id),
              if (story.locked) ...[
                Container(color: Colors.white24),
                const Positioned(top: 10, right: 10, child: PremiumBadge()),
              ] else if (p?.completed == true)
                const Positioned(top: 10, right: 10, child: _DoneBadge())
              else if (p != null && p.lastPage > 0)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _Pill(icon: Icons.menu_book_rounded, text: 'Hal. ${p.lastPage + 1}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ sudah selesai dibaca
class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E9E5B), size: 30),
      );
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ]),
      );
}
