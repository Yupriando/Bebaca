import { Router } from 'express';
import multer from 'multer';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase.js';
import { HttpError, must } from '../utils/errors.js';
import { ensureUserRows } from '../services/userService.js';
import { MAX_AVATAR_BYTES, removeAvatarByUrl, uploadAvatar } from '../services/avatarService.js';
import { jakartaDate, ageFromBirthDate, isValidBirthDate } from '../utils/date.js';

const router = Router();

async function readProfile(user) {
  let p = must(
    await supabaseAdmin.from('profiles').select('*').eq('id', user.id).maybeSingle(),
    undefined,
    'baca profil'
  );
  if (!p) {
    await ensureUserRows(user);
    p = must(
      await supabaseAdmin.from('profiles').select('*').eq('id', user.id).single(),
      undefined,
      'baca profil (baru)'
    );
  }
  return p;
}

async function loadProfile(user) {
  const p = await readProfile(user);

  // Streak dianggap putus kalau terakhir belajar bukan hari ini/kemarin
  const alive = [jakartaDate(0), jakartaDate(-1)].includes(p.last_study_date);

  return {
    nama: p.nama,
    email: user.email,
    tanggalLahir: p.tanggal_lahir,
    umur: p.tanggal_lahir ? ageFromBirthDate(p.tanggal_lahir) : p.umur,
    tingkatKesulitan: p.tingkat_kesulitan,
    hariBerturut: alive ? p.hari_berturut : 0,
    materiTerakhir: p.materi_terakhir,
    avatarUrl: p.avatar_url,
  };
}

// GET /api/profile
router.get('/', async (req, res) => {
  res.json(await loadProfile(req.user));
});

const updateSchema = z
  .object({
    nama: z.string().trim().min(1, 'Nama wajib diisi').max(60, 'Nama terlalu panjang').optional(),
    // null = hapus tanggal lahir
    tanggalLahir: z
      .string()
      .regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal lahir harus YYYY-MM-DD')
      .refine(isValidBirthDate, 'Tanggal lahir tidak valid')
      .nullable()
      .optional(),
    umur: z.coerce.number().int().min(1, 'Umur tidak valid').max(120, 'Umur tidak valid').optional(),
    tingkatKesulitan: z.enum(['Mudah', 'Sedang', 'Sulit']).optional(),
  })
  .refine((o) => Object.keys(o).length > 0, { message: 'Tidak ada data yang diubah' });

// PUT /api/profile
// - tanggalLahir diisi  -> umur dihitung otomatis dari tanggal lahir
// - tanggalLahir null   -> tanggal lahir dihapus, umur memakai nilai `umur`
// - hanya umur dikirim  -> tanggal lahir lama dihapus (umur manual yang berlaku)
router.put('/', async (req, res) => {
  const b = updateSchema.parse(req.body);

  const patch = {};
  if (b.nama !== undefined) patch.nama = b.nama;
  if (b.tingkatKesulitan !== undefined) patch.tingkat_kesulitan = b.tingkatKesulitan;

  if (b.tanggalLahir) {
    patch.tanggal_lahir = b.tanggalLahir;
    patch.umur = Math.min(120, Math.max(1, ageFromBirthDate(b.tanggalLahir)));
  } else {
    if (b.tanggalLahir === null) patch.tanggal_lahir = null;
    if (b.umur !== undefined) {
      patch.umur = b.umur;
      patch.tanggal_lahir = null;
    }
  }

  await ensureUserRows(req.user);
  const updated = must(
    await supabaseAdmin.from('profiles').update(patch).eq('id', req.user.id).select('id'),
    undefined,
    'update profil'
  );
  if (!updated.length) throw new HttpError(404, 'Profil tidak ditemukan');

  res.json(await loadProfile(req.user));
});

// ---------------- Foto profil ----------------
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_AVATAR_BYTES, files: 1 },
});

// POST /api/profile/avatar  (multipart/form-data, field "avatar")
router.post('/avatar', upload.single('avatar'), async (req, res) => {
  const old = (await readProfile(req.user)).avatar_url;
  const url = await uploadAvatar(req.user.id, req.file);

  must(
    await supabaseAdmin.from('profiles').update({ avatar_url: url }).eq('id', req.user.id),
    undefined,
    'simpan avatar_url'
  );
  await removeAvatarByUrl(old); // hapus foto lama agar storage tidak menumpuk

  res.json(await loadProfile(req.user));
});

// DELETE /api/profile/avatar
router.delete('/avatar', async (req, res) => {
  const old = (await readProfile(req.user)).avatar_url;
  must(
    await supabaseAdmin.from('profiles').update({ avatar_url: null }).eq('id', req.user.id),
    undefined,
    'hapus avatar_url'
  );
  await removeAvatarByUrl(old);
  res.json(await loadProfile(req.user));
});

export default router;
