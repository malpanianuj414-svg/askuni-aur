const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigins: (process.env.CORS_ORIGIN || 'http://localhost:5173,http://127.0.0.1:5173')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean),
  mockMode: String(process.env.MOCK_MODE || 'true').toLowerCase() === 'true',
  jwtSecret: process.env.JWT_SECRET || 'askuni_aur_bcs522_fallback_secret_2026',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '4h',
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX || '120', 10),
  mongodbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/askuni_aur',
  openaiApiKey: process.env.OPENAI_API_KEY || '',
  openaiModel: process.env.OPENAI_MODEL || 'gpt-4o-mini',
  openaiEmbeddingModel: process.env.OPENAI_EMBEDDING_MODEL || 'text-embedding-3-small',
  pineconeApiKey: process.env.PINECONE_API_KEY || '',
  pineconeIndex: process.env.PINECONE_INDEX || 'askuni-aur-index',
  pineconeHost: process.env.PINECONE_HOST || '',
  googleTranslateApiKey: process.env.GOOGLE_TRANSLATE_API_KEY || ''
};

module.exports = config;