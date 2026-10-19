import assert from 'node:assert/strict';
const base = process.argv[2];
if (!base || !/^https?:\/\//.test(base)) throw new Error('Uso: node scripts/smoke.mjs URL [--vote]');
let health;
for (let attempt = 1; attempt <= 12; attempt++) {
  try {
    const response = await fetch(`${base}/health`, { signal: AbortSignal.timeout(30000) });
    if (response.ok) { health = await response.json(); break; }
  } catch { /* Escalado desde cero o propagación inicial de RBAC. */ }
  console.log(`Esperando disponibilidad ${attempt}/12`);
  await new Promise((resolve) => setTimeout(resolve, 10000));
}
assert.equal(health?.status, 'ok', 'El health check debe comprobar acceso al almacenamiento.');
const response = await fetch(`${base}/api/heroes`);
assert.equal(response.status, 200);
const state = await response.json();
assert.equal(state.heroes.length, 3);
const cookie = response.headers.get('set-cookie')?.split(';')[0];
assert.ok(cookie, 'La sesión inicial debe emitir cookie.');
if (base.startsWith('https:')) assert.match(response.headers.get('set-cookie'), /Secure/);
if (process.argv.includes('--vote')) {
  const vote = (heroId) => fetch(`${base}/api/votes`, { method: 'POST', headers: { cookie, 'content-type': 'application/json' }, body: JSON.stringify({ heroId }) });
  const first = await vote('aurora'); assert.equal(first.status, 201);
  const repeat = await vote('aurora'); assert.equal(repeat.status, 200); assert.equal((await repeat.json()).replayed, true);
  assert.equal((await vote('volt')).status, 409);
  const later = await (await fetch(`${base}/api/heroes`, { headers: { cookie } })).json();
  assert.equal(later.selected, 'aurora'); assert.ok(later.total >= state.total + 1);
  console.log('VOTO_REAL_PASS: creación, repetición idempotente y cambio denegado. Se agregó un voto sintético.');
}
console.log(`HERO_HEALTH_PASS ${base} ${health.environment} ${health.storage}`);
