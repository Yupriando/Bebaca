import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { createAnonClient, supabaseAdmin } from '../config/supabase.js';
import { HttpError, must } from '../utils/errors.js';
import { jakartaDate } from '../utils/date.js';
import { checkPin, hashPin } from '../services/pinService.js';

const router = Router();

async function loadSettings(userId) {
  let row = must(
    await supabaseAdmin.from('user_settings').select('*').eq('user_id', userId).maybeSingle()
  );
  if (!row) {
    row = must(
      await supabaseAdmin.from('user_settings').insert({ user_id: userId }).select().single()
    );
  }

  const usage = must(
    await supabaseAdmin
      .from('daily_usage')
      .select('minutes')
      .eq('user_id', userId)
      .eq('usage_date', jakartaDate(0))
      .maybeSingle()
  );

  return {
    soundEffect: row.sound_effect,
    animation: row.animation,
    listeningExercise: row.listening_exercise,
    parentalControl: row.parental_control,
    timespentMinutes: usage?.minutes ?? 0,
    timeLimitMinutes: row.time_limit_minutes,
    curfew: row.curfew,
    hasParentPin: Boolean(row.parent_pin_hash),
  };
}

// GET /api/settings
router.get('/', async (req, res) => {
  res.json(await loadSettings(req.user.id));
});

const updateSchema = z
  .object({
    soundEffect: z.boolean().optional(),
    animation: z.boolean().optional(),
    listeningExercise: z.boolean().optional(),
    parentalControl: z.boolean().optional(),
    timeLimitMinutes: z.number().int().min(0).max(1440).optional(),
    curfew: z
      .string()
      .regex(/^([01][0-9]|2[0-3]):[0-5][0-9]$/, 'Format curfew harus HH:mm')
      .optional(),
  })
  .refine((o) => Object.keys(o).length > 0, { message: 'Tidak ada data yang diubah' });

// PUT /api/settings  (kirim hanya field yang berubah)
router.put('/', async (req, res) => {
  const b = updateSchema.parse(req.body);

  const patch = { user_id: req.user.id, updated_at: new Date().toISOString() };
  if (b.soundEffect !== undefined) patch.sound_effect = b.soundEffect;
  if (b.animation !== undefined) patch.animation = b.animation;
  if (b.listeningExercise !== undefined) patch.listening_exercise = b.listeningExercise;
  if (b.parentalControl !== undefined) patch.parental_control = b.parentalControl;
  if (b.timeLimitMinutes !== undefined) patch.time_limit_minutes = b.timeLimitMinutes;
  if (b.curfew !== undefined) patch.curfew = b.curfew;

  must(await supabaseAdmin.from('user_settings').upsert(patch, { onConflict: 'user_id' }));
  res.json(await loadSettings(req.user.id));
});

// POST /api/settings/usage  { minutes }  -> tambah waktu belajar hari ini
router.post('/usage', async (req, res) => {
  const { minutes } = z
    .object({
      minutes: z.number().int().min(1, 'Menit minimal 1').max(600, 'Menit terlalu besar'),
    })
    .parse(req.body);

  must(
    await supabaseAdmin.rpc('add_usage', {
      p_user: req.user.id,
      p_date: jakartaDate(0),
      p_minutes: minutes,
    })
  );
  res.json(await loadSettings(req.user.id));
});

// ================= PIN ORANG TUA =================
// Menggantikan soal penjumlahan. Membuat / mengganti PIN wajib memasukkan password akun
// (hanya orang tua yang tahu), jadi anak tidak bisa membuat PIN sendiri.

const pinSchema = z.string().regex(/^\d{4}$/, 'PIN harus 4 angka');

// Batasi tebakan PIN: 10 kali per 5 menit per akun.
const pinLimiter = rateLimit({
  windowMs: 5 * 60 * 1000,
  limit: 10,
  keyGenerator: (req) => req.user.id,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Terlalu banyak percobaan PIN, tunggu 5 menit lalu coba lagi' },
});

// POST /api/settings/parent-pin/verify  { pin } -> { ok: true } | 403 PIN salah
router.post('/parent-pin/verify', pinLimiter, async (req, res) => {
  const { pin } = z.object({ pin: pinSchema }).parse(req.body);
  const row = must(
    await supabaseAdmin
      .from('user_settings')
      .select('parent_pin_hash')
      .eq('user_id', req.user.id)
      .maybeSingle()
  );
  if (!row?.parent_pin_hash) throw new HttpError(409, 'PIN orang tua belum dibuat');
  if (!(await checkPin(pin, row.parent_pin_hash))) throw new HttpError(403, 'PIN salah');
  res.json({ ok: true });
});

// PUT /api/settings/parent-pin  { pin, password } -> buat / ganti PIN (juga untuk "Lupa PIN")
router.put('/parent-pin', pinLimiter, async (req, res) => {
  const { pin, password } = z
    .object({ pin: pinSchema, password: z.string().min(1, 'Password akun wajib diisi') })
    .parse(req.body);

  const { error } = await createAnonClient().auth.signInWithPassword({
    email: req.user.email,
    password,
  });
  if (error) throw new HttpError(403, 'Password akun salah');

  must(
    await supabaseAdmin
      .from('user_settings')
      .upsert(
        {
          user_id: req.user.id,
          parent_pin_hash: await hashPin(pin),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' }
      )
  );
  res.json(await loadSettings(req.user.id));
});

export default router;
