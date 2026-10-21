import express from 'express';
import swaggerUi from 'swagger-ui-express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env.js';
import { supabaseAdmin } from './config/supabase.js';
import { requireAuth } from './middleware/auth.js';
import { errorHandler, notFound } from './middleware/error.js';
import { openapi } from './docs/openapi.js';
import authRoutes from './routes/auth.routes.js';
import lessonRoutes from './routes/lessons.routes.js';
import storyRoutes from './routes/stories.routes.js';
import profileRoutes from './routes/profile.routes.js';
import settingsRoutes from './routes/settings.routes.js';
import subscriptionRoutes from './routes/subscription.routes.js';

const app = express();

if (env.trustProxy) app.set('trust proxy', 1);

// Swagger UI dipasang SEBELUM helmet agar CSP bawaan helmet tidak memblokir halamannya
app.get('/docs.json', (req, res) => res.json(openapi));
app.use(
  '/docs',
  swaggerUi.serve,
  swaggerUi.setup(openapi, {
    customSiteTitle: 'Bebaca API Docs',
    swaggerOptions: { persistAuthorization: true, displayRequestDuration: true },
  })
);
app.get('/', (req, res) => res.redirect('/docs'));

app.use(helmet());
app.use(
  cors({
    origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(',').map((s) => s.trim()),
  })
);
app.use(express.json({ limit: '100kb' }));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Diagnosa skema database (hanya saat development): memberi tahu migrasi mana yang belum dijalankan.
if (process.env.NODE_ENV !== 'production') {
  app.get('/health/db', async (req, res) => {
    const checks = [
      ['profiles', 'id,nama,umur,tanggal_lahir,tingkat_kesulitan,hari_berturut,last_study_date,materi_terakhir,avatar_url'],
      ['user_settings', 'user_id,sound_effect,animation,listening_exercise,parental_control,time_limit_minutes,curfew,parent_pin_hash'],
      ['daily_usage', 'user_id,usage_date,minutes'],
      ['sections', 'id,unit,section,title,guide,is_premium'],
      ['lessons', 'id,section_id,order_index,title,kind,letters'],
      ['lesson_progress', 'user_id,lesson_id,completed_at,stars'],
      ['story_categories', 'id,name,sort_order'],
      ['stories', 'id,category_id,title,cover_url,video_url,content,is_premium,moral,quiz,page_images'],
      ['story_progress', 'user_id,story_id,last_page,completed_at,stars'],
      ['subscriptions', 'user_id,platform,product_id,store_id,expires_at,auto_renew,checked_at'],
    ];
    const problems = [];
    const results = await Promise.all(
      checks.map(async ([table, cols]) => ({
        table,
        ...(await supabaseAdmin.from(table).select(cols).limit(1)),
      }))
    );
    for (const r of results) {
      if (r.error) problems.push({ table: r.table, error: r.error.message });
    }
    const { error: rpcError } = await supabaseAdmin.rpc('add_usage', {
      p_user: '00000000-0000-0000-0000-000000000000',
      p_date: '2000-01-01',
      p_minutes: 0,
    });
    if (rpcError && !/foreign key|violates/i.test(rpcError.message)) {
      problems.push({ function: 'add_usage', error: rpcError.message });
    }
    res.status(problems.length ? 500 : 200).json({
      ok: problems.length === 0,
      problems,
      hint: problems.length
        ? 'Jalankan schema.sql (instalasi baru) atau migrations/001 sampai 005 di Supabase SQL Editor.'
        : 'Skema database lengkap.',
    });
  });
}

app.use('/api/auth', authRoutes);
app.use('/api/lessons', requireAuth, lessonRoutes);
app.use('/api/stories', requireAuth, storyRoutes);
app.use('/api/profile', requireAuth, profileRoutes);
app.use('/api/settings', requireAuth, settingsRoutes);
app.use('/api/subscription', requireAuth, subscriptionRoutes);

app.use(notFound);
app.use(errorHandler);

export default app;
