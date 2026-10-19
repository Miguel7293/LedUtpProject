import express from 'express';
import { rateLimit } from 'express-rate-limit';
import { randomBytes } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { HEROES, voterKey } from './store.js';

export function createApp({ store, environment = 'local', secureCookies = false, limit = true }) {
  const app = express();
  app.disable('x-powered-by');
  // ACA añade el proxy inmediatamente anterior; la aplicación no usa IP para identificar votantes.
  if (environment !== 'local') app.set('trust proxy', 1);
  app.use((req, res, next) => {
    res.set({
      'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'",
      'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'same-origin',
    });
    next();
  });
  app.get('/health', async (req, res) => {
    try { await store.healthy(); res.json({ status: 'ok', service: 'hero-agency', environment, storage: store.mode }); }
    catch { res.status(503).json({ status: 'unavailable', service: 'hero-agency' }); }
  });
  app.use('/api', (req, res, next) => {
    res.set('Cache-Control', 'no-store');
    const token = req.headers.cookie?.split(';').map((part) => part.trim()).find((part) => part.startsWith('hero_voter='))?.slice(11);
    req.voter = token && /^[a-f0-9]{64}$/.test(token) ? token : randomBytes(32).toString('hex');
    if (req.voter !== token) res.cookie('hero_voter', req.voter, { httpOnly: true, sameSite: 'strict', secure: secureCookies, maxAge: 30 * 86400000, path: '/api' });
    next();
  });
  if (limit) app.use('/api/votes', rateLimit({ windowMs: 60000, limit: 20, standardHeaders: 'draft-8', legacyHeaders: false }));
  app.use(express.json({ limit: '2kb' }));
  async function state(req) {
    const snapshot = await store.snapshot(voterKey(req.voter));
    return { heroes: HEROES.map((hero) => ({ ...hero, votes: snapshot.counts[hero.id] })), selected: snapshot.selected, total: Object.values(snapshot.counts).reduce((sum, count) => sum + count, 0), environment, storage: store.mode };
  }
  app.get('/api/heroes', async (req, res) => res.json(await state(req)));
  app.post('/api/votes', async (req, res) => {
    const origin = req.get('origin');
    if (origin && origin !== `${secureCookies ? 'https' : req.protocol}://${req.get('host')}`) return res.status(403).json({ error: 'Origen no permitido.' });
    const heroId = req.body?.heroId;
    if (!HEROES.some((hero) => hero.id === heroId)) return res.status(400).json({ error: 'Selecciona un héroe válido.' });
    const result = await store.vote(voterKey(req.voter), heroId);
    if (!result.accepted) return res.status(409).json({ error: 'Este navegador ya registró un voto.' });
    res.status(result.replayed ? 200 : 201).json({ replayed: result.replayed, ...await state(req) });
  });
  app.use(express.static(fileURLToPath(new URL('../public', import.meta.url))));
  app.use((req, res) => res.status(404).json({ error: 'Ruta no encontrada.' }));
  app.use((error, req, res, next) => {
    if (error.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON no válido.' });
    if (error.status === 413) return res.status(413).json({ error: 'Solicitud demasiado grande.' });
    console.error(JSON.stringify({ event: 'request_failed', code: error.code ?? 'internal' }));
    res.status(503).json({ error: 'No pudimos acceder a los votos. Inténtalo de nuevo.' });
  });
  return app;
}
