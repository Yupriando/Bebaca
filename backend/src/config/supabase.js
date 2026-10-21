import { createClient } from '@supabase/supabase-js';
import { env } from './env.js';

const options = { auth: { autoRefreshToken: false, persistSession: false } };

// Client admin (service role): untuk query database & fungsi admin.
// JANGAN dipakai untuk signIn, karena akan mengubah sesi client bersama.
export const supabaseAdmin = createClient(env.supabaseUrl, env.supabaseServiceKey, options);

// Client anon baru per request: untuk login/refresh agar sesi tidak tercampur antar user.
export const createAnonClient = () =>
  createClient(env.supabaseUrl, env.supabaseAnonKey, options);
