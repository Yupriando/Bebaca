import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import { HttpError } from '../utils/errors.js';
import { env } from '../config/env.js';
import { supabaseAdmin } from '../config/supabase.js';
import { getEntitlement } from '../services/subscriptionService.js';

const router = Router();

/**
 * BEBACA PREMIUM - Integrasi Midtrans Payment Gateway
 *
 * Cara pakai:
 * 1. Daftar di https://dashboard.midtrans.com
 * 2. Isi MIDTRANS_SERVER_KEY dan MIDTRANS_CLIENT_KEY di .env
 * 3. Set MIDTRANS_ENV=sandbox untuk testing, production untuk live
 *
 * Alur pembayaran:
 * 1. Flutter -> POST /api/payment/create  -> dapat snapToken + paymentUrl
 * 2. Flutter buka paymentUrl di browser / WebView
 * 3. User bayar di Midtrans
 * 4. Midtrans -> POST /api/payment/notification (webhook)
 * 5. Backend aktifkan premium otomatis
 */

const PLANS = {
  monthly: { days: 30, price: 29000, name: 'Bebaca Premium Bulanan' },
  yearly:  { days: 365, price: 249000, name: 'Bebaca Premium Tahunan' },
};

// Helper: base64 encode untuk Basic Auth Midtrans
function midtransAuth() {
  return Buffer.from(`${env.midtransServerKey}:`).toString('base64');
}

// Helper: URL API Midtrans (sandbox atau production)
function midtransUrl(path) {
  const base = env.midtransEnv === 'production'
    ? 'https://app.midtrans.com'
    : 'https://app.sandbox.midtrans.com';
  return `${base}${path}`;
}

// -----------------------------------------------------------------------
// POST /api/payment/create  { plan: 'monthly' | 'yearly' }
// Buat transaksi Midtrans Snap -> dapat snapToken & paymentUrl
// -----------------------------------------------------------------------
router.post('/create', requireAuth, async (req, res) => {
  const { plan } = z
    .object({ plan: z.enum(['monthly', 'yearly'], { message: 'Paket harus monthly atau yearly' }) })
    .parse(req.body);

  const planInfo = PLANS[plan];
  if (!planInfo) throw new HttpError(400, 'Paket tidak dikenal');

  // Cek apakah sudah premium
  const entitlement = await getEntitlement(req.user.id);
  if (entitlement.isPremium) {
    throw new HttpError(409, 'Akun sudah aktif premium');
  }

  // Ambil profil untuk nama & email
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('nama')
    .eq('id', req.user.id)
    .maybeSingle();

  const orderId = `BEBACA-${plan.toUpperCase()}-${req.user.id.slice(0, 8)}-${Date.now()}`;

  if (!env.midtransServerKey || env.midtransServerKey.startsWith('SB-Mid-server-XXX')) {
    // Mode simulasi: Midtrans belum dikonfigurasi
    return res.json({
      orderId,
      snapToken: null,
      paymentUrl: null,
      simulationMode: true,
      message: 'Midtrans belum dikonfigurasi. Isi MIDTRANS_SERVER_KEY di .env untuk pembayaran nyata.',
      plan,
      price: planInfo.price,
    });
  }

  const payload = {
    transaction_details: {
      order_id: orderId,
      gross_amount: planInfo.price,
    },
    item_details: [
      {
        id: `bebaca_premium_${plan}`,
        price: planInfo.price,
        quantity: 1,
        name: planInfo.name,
      },
    ],
    customer_details: {
      first_name: profile?.nama || 'Pengguna Bebaca',
      email: req.user.email || '',
    },
    custom_field1: req.user.id,  // simpan userId untuk webhook
    custom_field2: plan,
  };

  try {
    const response = await fetch(midtransUrl('/snap/v1/transactions'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${midtransAuth()}`,
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('[Midtrans] Error create transaction:', data);
      throw new HttpError(502, `Midtrans error: ${data.error_messages?.join(', ') || 'Gagal membuat transaksi'}`);
    }

    res.json({
      orderId,
      snapToken: data.token,
      paymentUrl: data.redirect_url,
      simulationMode: false,
      plan,
      price: planInfo.price,
    });
  } catch (err) {
    if (err instanceof HttpError) throw err;
    throw new HttpError(502, 'Gagal menghubungi Midtrans');
  }
});

// -----------------------------------------------------------------------
// GET /api/payment/status/:orderId
// Cek status transaksi langsung ke Midtrans
// -----------------------------------------------------------------------
router.get('/status/:orderId', requireAuth, async (req, res) => {
  const { orderId } = z
    .object({ orderId: z.string().min(1) })
    .parse(req.params);

  if (!env.midtransServerKey || env.midtransServerKey.startsWith('SB-Mid-server-XXX')) {
    return res.json({ status: 'simulation_mode', message: 'Midtrans belum dikonfigurasi' });
  }

  try {
    const response = await fetch(midtransUrl(`/v2/${orderId}/status`), {
      headers: { 'Authorization': `Basic ${midtransAuth()}` },
    });
    const data = await response.json();
    res.json(data);
  } catch {
    throw new HttpError(502, 'Gagal mengambil status transaksi');
  }
});

// -----------------------------------------------------------------------
// POST /api/payment/notification
// Webhook dari Midtrans setelah pembayaran berhasil / gagal.
// PENTING: Pastikan URL ini bisa diakses publik (bukan localhost) saat produksi.
// Daftarkan di Midtrans Dashboard -> Settings -> Configuration -> Payment Notification URL
// -----------------------------------------------------------------------
router.post('/notification', async (req, res) => {
  const {
    order_id,
    transaction_status,
    fraud_status,
    custom_field1: userId,
    custom_field2: plan,
  } = req.body;

  console.log(`[Payment] Notifikasi: order=${order_id} status=${transaction_status} fraud=${fraud_status}`);

  // Verifikasi notifikasi ke Midtrans (hindari spoofing)
  if (env.midtransServerKey && !env.midtransServerKey.startsWith('SB-Mid-server-XXX')) {
    try {
      const verify = await fetch(midtransUrl(`/v2/${order_id}/status`), {
        headers: { 'Authorization': `Basic ${midtransAuth()}` },
      });
      const verified = await verify.json();
      if (verified.transaction_status !== transaction_status) {
        console.warn('[Payment] Status mismatch, kemungkinan spoofing:', order_id);
        return res.status(400).json({ message: 'Status tidak cocok' });
      }
    } catch {
      console.error('[Payment] Gagal verifikasi ke Midtrans');
    }
  }

  const isSuccess =
    transaction_status === 'capture' && fraud_status === 'accept' ||
    transaction_status === 'settlement';

  if (isSuccess && userId && plan) {
    const planInfo = PLANS[plan];
    if (planInfo) {
      const expiresAt = new Date(Date.now() + planInfo.days * 24 * 60 * 60 * 1000).toISOString();
      await supabaseAdmin.from('subscriptions').upsert(
        {
          user_id: userId,
          platform: 'manual',
          product_id: `bebaca_premium_${plan}`,
          store_id: order_id,
          expires_at: expiresAt,
          auto_renew: false,
          status: 'active',
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'platform,store_id' }
      );
      console.log(`[Payment] Premium diaktifkan: user=${userId} plan=${plan} expires=${expiresAt}`);
    }
  }

  res.json({ message: 'OK' });
});

// -----------------------------------------------------------------------
// GET /api/payment/client-key
// Kirim Midtrans Client Key ke frontend (aman karena hanya client key)
// -----------------------------------------------------------------------
router.get('/client-key', requireAuth, (req, res) => {
  res.json({
    clientKey: env.midtransClientKey || '',
    environment: env.midtransEnv,
    configured: !!(env.midtransServerKey && !env.midtransServerKey.startsWith('SB-Mid-server-XXX')),
  });
});

export default router;
