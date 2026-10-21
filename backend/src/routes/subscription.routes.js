import { Router } from 'express';
import { z } from 'zod';
import { activate, deactivate, getEntitlement } from '../services/subscriptionService.js';
import { HttpError } from '../utils/errors.js';
import { env } from '../config/env.js';

const router = Router();

// GET /api/subscription -> { isPremium, plan, expiresAt, autoRenew, platform }
router.get('/', async (req, res) => {
  res.json(await getEntitlement(req.user.id));
});

// ---- MODE SIMULASI: tanpa pembayaran sungguhan. ----
// Mati saat NODE_ENV=production (termasuk Vercel), kecuali ALLOW_PREMIUM_SIMULATION=true.
router.use((req, res, next) => {
  if (!env.allowPremiumSimulation) {
    throw new HttpError(403, 'Mode simulasi premium tidak tersedia di produksi');
  }
  next();
});

// POST /api/subscription/activate  { plan: 'monthly' | 'yearly' }
router.post('/activate', async (req, res) => {
  const { plan } = z
    .object({ plan: z.enum(['monthly', 'yearly'], { message: 'Paket harus monthly atau yearly' }) })
    .parse(req.body);
  res.json(await activate(req.user.id, plan));
});

// POST /api/subscription/deactivate -> kembali ke gratis
router.post('/deactivate', async (req, res) => {
  res.json(await deactivate(req.user.id));
});

export default router;
