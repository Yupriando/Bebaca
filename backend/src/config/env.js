import 'dotenv/config';

const required = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY'];
for (const key of required) {
  if (!process.env[key]) {
    console.error(`Environment variable ${key} belum diisi (lihat .env.example)`);
    process.exit(1);
  }
}

export const env = {
  port: Number(process.env.PORT) || 3000,
  supabaseUrl: process.env.SUPABASE_URL,
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY,
  supabaseServiceKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  corsOrigin: process.env.CORS_ORIGIN || '*',
  // Vercel / Render dsb. ada di belakang proxy -> wajib true (otomatis di Vercel)
  trustProxy: process.env.TRUST_PROXY === 'true' || Boolean(process.env.VERCEL),
  // Tombol premium simulasi (tanpa bayar). Di produksi mati, kecuali diizinkan di sini.
  allowPremiumSimulation:
    process.env.NODE_ENV !== 'production' || process.env.ALLOW_PREMIUM_SIMULATION === 'true',
};
