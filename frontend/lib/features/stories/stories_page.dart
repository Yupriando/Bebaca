import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_body.dart';
import '../../core/widgets/sky_background.dart';
import '../../models/story.dart';
import '../../services/premium_store.dart';
import '../../services/story_service.dart';
import '../premium/premium_prompt.dart';
import 'story_cover.dart';
import 'story_detail_page.dart';

/// Rak dongeng ala banner: judul "Dongeng", filter kategori berbentuk pil,
/// lalu kartu dongeng (gambar, judul, kategori, status bintang / halaman / Premium).
class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  static const _all = 'Semua';
  static const _continue = 'Lanjutkan';

  final _premium = PremiumStore.instance;
  late bool _wasPremium = _premium.isPremium;
  late Future<List<StoryCategory>> _future = StoryService().getCategories();
  String _filter = _all;

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

  /// Muat ulang (mis. setelah selesai membaca: tanda selesai & "Lanjutkan" berubah).
  void _reload() {
    if (mounted) setState(() => _future = StoryService().getCategories());
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<List<StoryCategory>>(
      future: _future,
      builder: (context, categories) {
        // (dongeng, nama kategori) semua dongeng
        final all = [
          for (final c in categories)
            for (final s in c.stories) (s, c.name),
        ];
        // "Lanjutkan": sudah dibuka tetapi belum selesai
        final reading = all
            .where((e) =>
                !e.$1.locked && e.$1.progress != null && !e.$1.progress!.completed && e.$1.progress!.lastPage > 0)
            .toList();
        final filters = [_all, if (reading.isNotEmpty) _continue, for (final c in categories) c.name];
        if (!filters.contains(_filter)) _filter = _all;
        final shown = switch (_filter) {
          _all => all,
          _continue => reading,
          _ => all.where((e) => e.$2 == _filter).toList(),
        };

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
                child: Row(children: [
                  Text('Dongeng',
                      style: GoogleFonts.fredoka(
                          fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(width: 12),
                  Text('${all.length} cerita',
                      style: GoogleFonts.fredoka(fontSize: 18, color: AppColors.hint)),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _FilterChip(
                    label: filters[i] == _continue ? '📖 $_continue' : filters[i],
                    selected: filters[i] == _filter,
                    onTap: () => setState(() => _filter = filters[i]),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
              sliver: SliverLayoutBuilder(builder: (context, c) {
                final cols = c.crossAxisExtent >= 980 ? 3 : (c.crossAxisExtent >= 600 ? 2 : 1);
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 128,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _StoryCard(story: shown[i].$1, category: shown[i].$2, onChanged: _reload),
                    childCount: shown.length,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 3))]
              : const [BoxShadow(color: Color(0x141C5FC7), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: Text(label,
                    style: GoogleFonts.fredoka(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textDark)),
              ),
            ),
          ),
        ),
      );
}

class _StoryCard extends StatelessWidget {
  final Story story;
  final String category;
  final VoidCallback onChanged;
  const _StoryCard({required this.story, required this.category, required this.onChanged});

  Future<void> _open(BuildContext context) async {
    if (story.locked) {
      showPremiumPrompt(context, what: 'Cerita "${story.title}"');
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StoryDetailPage(storyId: story.id, title: story.title)),
    );
    if (changed == true) onChanged();
  }

  /// Baris status: bintang (selesai), halaman terakhir, Premium, atau belum dibaca.
  Widget _status() {
    final p = story.progress;
    final style = GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600);
    if (story.locked) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_rounded, size: 17, color: AppColors.sunDark),
        const SizedBox(width: 4),
        Text('Premium', style: style.copyWith(color: AppColors.sunDark)),
      ]);
    }
    if (p?.completed == true) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Icon(Icons.star_rounded, size: 19, color: i < p!.stars ? AppColors.sun : const Color(0xFFDDE3EA)),
        const SizedBox(width: 6),
        Text('Selesai', style: style.copyWith(color: const Color(0xFF2E9E5B))),
      ]);
    }
    if (p != null && p.lastPage > 0) {
      return Text('📖 Lanjut halaman ${p.lastPage + 1}', style: style.copyWith(color: AppColors.primary));
    }
    return Text('Belum dibaca', style: style.copyWith(color: AppColors.hint, fontWeight: FontWeight.w500));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _open(context),
        child: SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 132,
                height: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  StoryCover(url: story.coverUrl, title: story.title, seed: story.id, titleSize: 14),
                  if (story.locked) Container(color: Colors.white38),
                ]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                          fontSize: 20, height: 1.15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(fontSize: 15, color: AppColors.hint)),
                  const SizedBox(height: 6),
                  _status(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
