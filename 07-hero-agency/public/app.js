const cards = document.querySelector('#cards');
const message = document.querySelector('#message');
let busy = false;

function render(data) {
  cards.replaceChildren();
  document.querySelector('#results').replaceChildren();
  document.querySelector('#total').textContent = data.total;
  for (const hero of data.heroes) {
    const card = document.createElement('article');
    card.className = `card ${hero.color}`;
    const portrait = document.createElement('div'); portrait.className = 'portrait';
    const city = document.createElement('span'); city.className = 'city'; city.textContent = `${hero.city.toUpperCase()} / PERÚ`;
    const symbol = document.createElement('span'); symbol.className = 'symbol'; symbol.textContent = hero.symbol;
    portrait.append(city, symbol);
    const body = document.createElement('div'); body.className = 'card-body';
    const role = document.createElement('span'); role.className = 'role'; role.textContent = hero.role;
    const name = document.createElement('h3'); name.textContent = hero.name;
    const description = document.createElement('p'); description.textContent = hero.description;
    const button = document.createElement('button'); button.type = 'button';
    button.textContent = data.selected === hero.id ? '✓ TU VOTO ESTÁ AQUÍ' : data.selected ? 'VOTACIÓN REGISTRADA' : 'VOTAR POR ESTE HÉROE ↗';
    button.disabled = Boolean(data.selected) || busy;
    button.addEventListener('click', () => vote(hero.id));
    body.append(role, name, description, button); card.append(portrait, body); cards.append(card);
    const result = document.createElement('div'); result.className = `result ${hero.color}`;
    const label = document.createElement('div'); label.className = 'result-label';
    const percent = data.total ? Math.round(hero.votes * 100 / data.total) : 0;
    const labelName = document.createElement('span'); labelName.textContent = hero.name;
    const count = document.createElement('span'); count.textContent = `${hero.votes} votos · ${percent}%`; label.append(labelName, count);
    const meter = document.createElement('progress'); meter.max = data.total || 1; meter.value = hero.votes; meter.setAttribute('aria-label', `${hero.name}: ${percent}%`);
    result.append(label, meter); document.querySelector('#results').append(result);
  }
}
async function request(url, options) {
  const response = await fetch(url, options); const body = await response.json();
  if (!response.ok) throw new Error(body.error ?? 'No pudimos conectar. Inténtalo otra vez.');
  return body;
}
async function load() {
  try { render(await request('/api/heroes')); message.textContent = ''; }
  catch (error) { message.textContent = error.message; }
}
async function vote(heroId) {
  if (busy) return;
  busy = true; cards.querySelectorAll('button').forEach((button) => { button.disabled = true; });
  try {
    const data = await request('/api/votes', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ heroId }) });
    busy = false; render(data); message.textContent = '¡Tu voto ya forma parte del cambio! Gracias por participar.';
  } catch (error) { busy = false; await load(); message.textContent = error.message; }
}
document.querySelector('#refresh').addEventListener('click', load);
load();
