import { supabaseAdmin } from '../config/supabase.js';
import { HttpError } from '../utils/errors.js';

/** Verifikasi header "Authorization: Bearer <access_token>" lewat Supabase Auth. */
export async function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : null;
  if (!token) throw new HttpError(401, 'Token tidak ditemukan');

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data?.user) throw new HttpError(401, 'Token tidak valid atau kedaluwarsa');

  req.user = data.user;
  req.token = token;
  next();
}
