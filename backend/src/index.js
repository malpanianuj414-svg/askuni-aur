const config = require('./config/env');
const { dbManager } = require('./config/db');
const { createApp } = require('./app');
const { seedDatabaseIfEmpty } = require('./seed/seedData');

async function startServer() {
  await dbManager.connect();
  await seedDatabaseIfEmpty();

  const app = createApp();
  app.listen(config.port, () => {
    console.log(`[AskUni Backend] Listening on http://localhost:${config.port} (MOCK_MODE=${config.mockMode})`);
  });
}

startServer().catch((err) => {
  console.error('[AskUni Backend] Failed to start:', err);
  process.exit(1);
});