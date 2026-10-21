import { Router } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';
import { HttpError, must } from '../utils/errors.js';
import { getEntitlement } from '../services/subscriptionService.js';

const router = Router();

const toProgress = (p) =>
  p
    ? {
        lastPage: p.last_page,
        completed: Boolean(p.completed_at),
        stars: p.stars,
        updatedAt: p.updated_at,
      }
    : null;

// GET /api/stories -> [{name, stories:[{id,title,coverUrl,isPremium,locked,progress}]}]
// Dongeng premium tetap ditampilkan (dengan gembok) supaya anak tahu ada cerita lain.
router.get('/', async (req, res) => {
  const [categoriesRes, progressRes, entitlement] = await Promise.all([
    supabaseAdmin
      .from('story_categories')
      .select('id, name, sort_order, stories(id, title, cover_url, sort_order, is_premium)')
      .order('sort_order'),
    supabaseAdmin
      .from('story_progress')
      .select('story_id, last_page, completed_at, stars, updated_at')
      .eq('user_id', req.user.id),
    getEntitlement(req.user.id),
  ]);
  const categories = must(categoriesRes);
  const progress = new Map(must(progressRes).map((p) => [p.story_id, p]));

  res.json(
    categories.map((c) => ({
      name: c.name,
      stories: [...c.stories]
        .sort((a, b) => a.sort_order - b.sort_order)
        .map((s) => ({
          id: s.id,
          title: s.title,
          coverUrl: s.cover_url,
          isPremium: s.is_premium,
          locked: s.is_premium && !entitlement.isPremium,
          progress: toProgress(progress.get(s.id)),
        })),
    }))
  );
});

async function loadStory(req, columns) {
  const { id } = z.object({ id: z.string().uuid('ID dongeng tidak valid') }).parse(req.params);
  const story = must(
    await supabaseAdmin.from('stories').select(`id, is_premium, ${columns}`).eq('id', id).maybeSingle()
  );
  if (!story) throw new HttpError(404, 'Dongeng tidak ditemukan');
  if (story.is_premium && !(await getEntitlement(req.user.id)).isPremium) {
    throw new HttpError(402, 'Dongeng ini khusus Bebaca Premium');
  }
  return story;
}

// GET /api/stories/:id -> detail + isi cerita + pesan moral + kuis + progres
// (402 jika premium & user belum berlangganan)
router.get('/:id', async (req, res) => {
  const story = await loadStory(req, 'title, cover_url, video_url, content, moral, quiz, page_images');
  const progress = must(
    await supabaseAdmin
      .from('story_progress')
      .select('last_page, completed_at, stars, updated_at')
      .eq('user_id', req.user.id)
      .eq('story_id', story.id)
      .maybeSingle()
  );

  res.json({
    id: story.id,
    title: story.title,
    coverUrl: story.cover_url,
    videoUrl: story.video_url,
    content: story.content,
    moral: story.moral,
    quiz: story.quiz ?? [],
    pageImages: story.page_images ?? [],
    progress: toProgress(progress),
  });
});

const progressSchema = z.object({
  page: z.number().int().min(0).max(500),
  completed: z.boolean().optional(),
  stars: z.number().int().min(0).max(3).optional(),
});

// POST /api/stories/:id/progress  { page, completed?, stars? }
// Menyimpan halaman terakhir. Sekali selesai tetap selesai; bintang hanya naik.
router.post('/:id/progress', async (req, res) => {
  const story = await loadStory(req, 'title');
  const b = progressSchema.parse(req.body);

  const old = must(
    await supabaseAdmin
      .from('story_progress')
      .select('completed_at, stars')
      .eq('user_id', req.user.id)
      .eq('story_id', story.id)
      .maybeSingle()
  );

  const row = must(
    await supabaseAdmin
      .from('story_progress')
      .upsert(
        {
          user_id: req.user.id,
          story_id: story.id,
          last_page: b.page,
          completed_at: old?.completed_at ?? (b.completed ? new Date().toISOString() : null),
          stars: Math.max(old?.stars ?? 0, b.stars ?? 0),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,story_id' }
      )
      .select('last_page, completed_at, stars, updated_at')
      .single()
  );
  res.json(toProgress(row));
});

export default router;
