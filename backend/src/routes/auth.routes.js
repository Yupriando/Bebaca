import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { supabaseAdmin, createAnonClient } from '../config/supabase.js';
import { requireAuth } from '../middleware/auth.js';
import { HttpError } from '../utils/errors.js';
import { ensureUserRows } from '../services/userService.js';

const router = Router();

router.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 50,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Terlalu banyak percobaan, coba lagi nanti' },
  })
);

const registerSchema = z.object({
  umur: z.coerce
    .number({ error: 'Umur harus berupa angka' })
    .int('Umur harus berupa angka bulat')
    .min(1, 'Umur tidak valid')
    .max(120, 'Umur tidak valid'),
  nama: z.string().trim().min(1, 'Nama wajib diisi').max(60, 'Nama terlalu panjang'),
  email: z.string().trim().email('Email tidak valid'),
  password: z.string().min(6, 'Password minimal 6 karakter').max(72, 'Password terlalu panjang'),
});

const loginSchema = z.object({
  email: z.string().trim().email('Email tidak valid'),
  password: z.string().min(1, 'Password wajib diisi'),
});

function sessionResponse(data) {
  return {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_at: data.session.expires_at,
    user: { id: data.user.id, email: data.user.email },
  };
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { umur, nama, email, password } = registerSchema.parse(req.body);

  const { data, error } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true, // langsung aktif; ubah ke false jika ingin verifikasi email
    user_metadata: { nama },
  });

  if (error) {
    const msg = (error.message || '').toLowerCase();
    if (error.code === 'email_exists' || msg.includes('already') || msg.includes('registered')) {
      throw new HttpError(409, 'Email sudah terdaftar');
    }
    throw new HttpError(400, error.message);
  }

  try {
    await ensureUserRows(data.user, { nama, umur });
  } catch (e) {
    // rollback supaya tidak ada akun tanpa profil
    await supabaseAdmin.auth.admin.deleteUser(data.user.id);
    throw e;
  }

  res.status(201).json({ message: 'Akun berhasil dibuat' });
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = loginSchema.parse(req.body);

  const client = createAnonClient();
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error || !data?.session) throw new HttpError(401, 'Email atau password salah');

  res.json(sessionResponse(data));
});

// POST /api/auth/refresh  { refresh_token }
router.post('/refresh', async (req, res) => {
  const { refresh_token } = z
    .object({ refresh_token: z.string().min(1, 'refresh_token wajib diisi') })
    .parse(req.body);

  const client = createAnonClient();
  const { data, error } = await client.auth.refreshSession({ refresh_token });
  if (error || !data?.session) throw new HttpError(401, 'Sesi berakhir, silakan login lagi');

  res.json(sessionResponse(data));
});

// POST /api/auth/logout
router.post('/logout', requireAuth, async (req, res) => {
  try {
    await supabaseAdmin.auth.admin.signOut(req.token);
  } catch (e) {
    console.error('signOut gagal:', e);
  }
  res.json({ message: 'Berhasil logout' });
});

export default router;
