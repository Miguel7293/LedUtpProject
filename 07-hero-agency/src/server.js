import { createApp } from './app.js';
import { MemoryStore, AzureTableStore } from './store.js';

const environment = process.env.APP_ENV ?? 'local';
if (environment !== 'local' && !process.env.TABLE_ACCOUNT) throw new Error('TABLE_ACCOUNT es obligatorio fuera del entorno local.');
const store = process.env.TABLE_ACCOUNT ? new AzureTableStore({ accountName: process.env.TABLE_ACCOUNT, clientId: process.env.AZURE_CLIENT_ID, tableName: process.env.TABLE_NAME }) : new MemoryStore();
const app = createApp({ store, environment, secureCookies: environment !== 'local' });
const server = app.listen(Number(process.env.PORT ?? 3000), '0.0.0.0', () => console.log(JSON.stringify({ event: 'server_started', environment, storage: store.mode })));
process.on('SIGTERM', () => server.close(() => process.exit(0)));
