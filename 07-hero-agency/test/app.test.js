import { test } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createApp } from '../src/app.js';
import { MemoryStore } from '../src/store.js';

async function fixture(t, store = new MemoryStore()) {
  const server = createApp({ store, limit: false }).listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const initial = await fetch(`${base}/api/heroes`);
  const cookie = initial.headers.get('set-cookie').split(';')[0];
  const vote = (heroId, options = {}) => fetch(`${base}/api/votes`, { method: 'POST', headers: { cookie, 'content-type': 'application/json', ...options.headers }, body: JSON.stringify({ heroId }) });
  return { base, cookie, vote };
}

test('un voto persiste, repetirlo es idempotente y cambiarlo devuelve 409', async (t) => {
  const { base, cookie, vote } = await fixture(t);
  assert.equal((await vote('aurora')).status, 201);
  const repeated = await vote('aurora');
  assert.equal(repeated.status, 200);
  assert.equal((await repeated.json()).replayed, true);
  assert.equal((await vote('volt')).status, 409);
  const state = await (await fetch(`${base}/api/heroes`, { headers: { cookie } })).json();
  assert.equal(state.total, 1); assert.equal(state.selected, 'aurora');
});
test('solicitudes simultáneas con la misma cookie registran un solo voto', async (t) => {
  const { base, vote } = await fixture(t);
  const responses = await Promise.all([vote('volt'), vote('marea')]);
  assert.deepEqual(responses.map((response) => response.status).sort(), [201, 409]);
  assert.equal((await (await fetch(`${base}/api/heroes`)).json()).total, 1);
});
test('rechaza candidato inválido y petición de otro origen sin contar votos', async (t) => {
  const { base, vote } = await fixture(t);
  assert.equal((await vote('<script>')).status, 400);
  assert.equal((await vote('aurora', { headers: { origin: 'https://otra-web.example' } })).status, 403);
  assert.equal((await (await fetch(`${base}/api/heroes`)).json()).total, 0);
});
test('health devuelve 503 si el almacenamiento no está disponible, sin filtrar detalles', async (t) => {
  const store = new MemoryStore(); store.healthy = async () => { throw new Error('sensitive-internal-detail'); };
  const { base } = await fixture(t, store);
  const response = await fetch(`${base}/health`);
  assert.equal(response.status, 503);
  assert.doesNotMatch(await response.text(), /sensitive/);
});
test('entrega UI con CSP y cookies HttpOnly, sin caché de los resultados', async (t) => {
  const { base } = await fixture(t);
  const page = await fetch(base);
  assert.match(await page.text(), /Tu próximo/);
  assert.match(page.headers.get('content-security-policy'), /frame-ancestors 'none'/);
  const api = await fetch(`${base}/api/heroes`);
  assert.match(api.headers.get('set-cookie'), /HttpOnly/);
  assert.equal(api.headers.get('cache-control'), 'no-store');
});
