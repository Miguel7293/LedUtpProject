import { createHash } from 'node:crypto';
import { TableClient } from '@azure/data-tables';
import { ManagedIdentityCredential } from '@azure/identity';

export const HEROES = Object.freeze([
  { id: 'aurora', name: 'Capitana Aurora', role: 'Rescate y protección', city: 'Arequipa', symbol: 'A', color: 'coral', description: 'Luz donde más hace falta. Convierte la energía solar en escudos para proteger a su ciudad.' },
  { id: 'volt', name: 'Volt', role: 'Energía y velocidad', city: 'Lima', symbol: 'V', color: 'lime', description: 'Siempre un paso adelante. Lleva energía limpia y ayuda a donde nadie más llega a tiempo.' },
  { id: 'marea', name: 'Marea', role: 'Agua y naturaleza', city: 'Trujillo', symbol: 'M', color: 'blue', description: 'La fuerza de cuidar. Protege nuestras costas y transforma el agua en nuevas oportunidades.' },
]);
export const voterKey = (token) => createHash('sha256').update(token).digest('hex');

function outcome(existing, heroId) {
  return existing === heroId ? { accepted: true, replayed: true } : { accepted: false, replayed: false };
}

export class MemoryStore {
  constructor() { this.ballots = new Map(); this.mode = 'memoria temporal'; }
  async vote(key, heroId) {
    if (this.ballots.has(key)) return outcome(this.ballots.get(key), heroId);
    this.ballots.set(key, heroId);
    return { accepted: true, replayed: false };
  }
  async snapshot(key) {
    const counts = Object.fromEntries(HEROES.map((hero) => [hero.id, 0]));
    for (const heroId of this.ballots.values()) counts[heroId]++;
    return { counts, selected: this.ballots.get(key) ?? null };
  }
  async healthy() { return true; }
}

export class AzureTableStore {
  constructor({ accountName, clientId, tableName = 'votes', election = 'hero-agency-v1' }) {
    this.client = new TableClient(`https://${accountName}.table.core.windows.net`, tableName, new ManagedIdentityCredential({ clientId }));
    this.election = election;
    this.mode = 'Azure Table Storage';
  }
  async vote(key, heroId) {
    try {
      await this.client.createEntity({ partitionKey: this.election, rowKey: key, heroId });
      return { accepted: true, replayed: false };
    } catch (error) {
      if (error.statusCode !== 409) throw error;
      const existing = await this.client.getEntity(this.election, key);
      return outcome(existing.heroId, heroId);
    }
  }
  async snapshot(key) {
    const counts = Object.fromEntries(HEROES.map((hero) => [hero.id, 0]));
    let selected = null;
    for await (const entity of this.client.listEntities({ queryOptions: { filter: `PartitionKey eq '${this.election}'`, select: ['RowKey', 'heroId'] } })) {
      if (Object.hasOwn(counts, entity.heroId)) counts[entity.heroId]++;
      if (entity.rowKey === key) selected = entity.heroId;
    }
    return { counts, selected };
  }
  async healthy() {
    // Una consulta real comprueba autenticación, permisos y disponibilidad de la tabla.
    const entities = this.client.listEntities({ queryOptions: { filter: `PartitionKey eq '${this.election}'`, select: ['RowKey'] } });
    await entities.byPage({ maxPageSize: 1 }).next();
    return true;
  }
}
