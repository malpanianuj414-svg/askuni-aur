const { dbManager } = require('../backend/src/config/db');
const { createApp } = require('../backend/src/app');
const { seedDatabaseIfEmpty } = require('../backend/src/seed/seedData');

let cachedApp = null;
let initPromise = null;

async function getInitializedApp() {
  if (cachedApp) {
    return cachedApp;
  }
  if (!initPromise) {
    initPromise = (async () => {
      await dbManager.connect();
      await seedDatabaseIfEmpty();
      cachedApp = createApp();
      return cachedApp;
    })().catch((err) => {
      initPromise = null;
      throw err;
    });
  }
  return initPromise;
}

module.exports = async (req, res) => {
  try {
    const app = await getInitializedApp();
    return app(req, res);
  } catch (err) {
    console.error('[AskUni Vercel Handler Error]', err);
    res.status(500).json({
      success: false,
      error: {
        code: 'SERVERLESS_INIT_ERROR',
        message: 'Failed to initialize AskUni backend service.',
        detail: err && err.message ? err.message : String(err)
      }
    });
  }
};