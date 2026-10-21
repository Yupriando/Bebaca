import { supabaseAdmin } from '../config/supabase.js';
import { HttpError, must } from '../utils/errors.js';

/**
 * Bebaca Premium - MODE SIMULASI (belum ada pembayaran sungguhan).
 * Tombol "Langganan" langsung mengaktifkan premium, "Pulihkan pembelian" mengembalikan ke gratis.
 * Nanti saat memakai Google Play / App Store, cukup ganti activate() dengan verifikasi ke toko.
 */
export const PLANS = {
  monthly: { productId: 'bebaca_premium_monthly', days: 30 },
  yearly: { productId: 'bebaca_premium_yearly', days: 365 },
};
const PLAN_BY_PRODUCT = Object.fromEntries(
  Object.entries(PLANS).map(([plan, p]) => [p.productId, plan])
);

const simulatedId = (userId) => `simulasi-${userId}`;

/** Status premium user: { isPremium, plan, expiresAt, autoRenew, platform }. */
export async function getEntitlement(userId) {
  const rows = must(
    await supabaseAdmin
      .from('subscriptions')
      .select('platform, product_id, expires_at, auto_renew')
      .eq('user_id', userId)
      .gt('expires_at', new Date().toISOString())
      .order('expires_at', { ascending: false })
      .limit(1),
    undefined,
    'baca subscriptions'
  );
  const active = rows[0];
  if (!active) return { isPremium: false, plan: null, expiresAt: null, autoRenew: false, platform: null };
  return {
    isPremium: true,
    plan: PLAN_BY_PRODUCT[active.product_id] ?? 'monthly',
    expiresAt: active.expires_at,
    autoRenew: active.auto_renew,
    platform: active.platform,
  };
}

/** Simulasi beli: aktifkan premium selama 30 / 365 hari. */
export async function activate(userId, plan) {
  const p = PLANS[plan];
  if (!p) throw new HttpError(400, 'Paket tidak dikenal');
  must(
    await supabaseAdmin.from('subscriptions').upsert(
      {
        user_id: userId,
        platform: 'manual',
        product_id: p.productId,
        store_id: simulatedId(userId),
        expires_at: new Date(Date.now() + p.days * 24 * 60 * 60 * 1000).toISOString(),
        auto_renew: true,
        status: 'simulasi',
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'platform,store_id' }
    ),
    undefined,
    'aktifkan premium'
  );
  return getEntitlement(userId);
}

/** Simulasi: kembalikan akun ke gratis (hapus semua langganan user ini). */
export async function deactivate(userId) {
  must(
    await supabaseAdmin.from('subscriptions').delete().eq('user_id', userId),
    undefined,
    'nonaktifkan premium'
  );
  return getEntitlement(userId);
}
