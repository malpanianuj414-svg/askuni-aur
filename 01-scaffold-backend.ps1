# 01-scaffold-backend.ps1
# Scaffolds the complete AskUni Node.js + Express + Mongoose backend and installs npm dependencies.
# Compatible with Windows PowerShell 5.1 and PowerShell 7+.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RootDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $fullPath = Join-Path $RootDir $RelativePath
    $parentDir = Split-Path -Path $fullPath -Parent
    if (-not (Test-Path -Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($fullPath, $Content, $utf8NoBom)
    Write-Host "  Wrote $RelativePath" -ForegroundColor DarkGray
}

Write-Step "Scaffolding AskUni Backend ($RootDir\backend)"

# 1. backend/package.json
Write-ProjectFile -RelativePath "backend\package.json" -Content @'
{
  "name": "askuni-backend",
  "version": "1.0.0",
  "description": "AskUni Language-Agnostic AI Chatbot Backend - Amity University Rajasthan (BCS 522)",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "seed": "node src/seed/seedData.js",
    "test": "jest --runInBand --forceExit"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "express-rate-limit": "^7.4.0",
    "helmet": "^7.1.0",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^8.5.2",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "supertest": "^7.0.0"
  }
}
'@

# 2. backend/.env
Write-ProjectFile -RelativePath "backend\.env" -Content @'
# AskUni Environment Configuration (Amity University Rajasthan - BCS 522)
PORT=5000
NODE_ENV=development
CORS_ORIGIN=http://localhost:5173,http://127.0.0.1:5173

# Windows-Friendly Mock Mode (default ON: no external keys or local MongoDB daemon required)
MOCK_MODE=true

# JWT Signing Secret (masked in all API responses and logs)
JWT_SECRET=askuni_aur_bcs522_super_secret_signing_key_2026
JWT_EXPIRES_IN=4h

# Rate Limiting Defaults
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=120

# --- REAL EXTERNAL API SLOTS (Uncomment & set MOCK_MODE=false for production) ---
# MONGODB_URI=mongodb+srv://<user>:<password>@cluster0.example.mongodb.net/askuni
# OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# OPENAI_MODEL=gpt-4o-mini
# OPENAI_EMBEDDING_MODEL=text-embedding-3-small
# PINECONE_API_KEY=pcsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# PINECONE_INDEX=askuni-aur-index
# PINECONE_HOST=https://askuni-aur-index-xxxx.svc.aped-xxxx.pinecone.io
# GOOGLE_TRANSLATE_API_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxxxxx
'@

# 3. backend/jest.config.js
Write-ProjectFile -RelativePath "backend\jest.config.js" -Content @'
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/src/tests/**/*.test.js'],
  verbose: true
};
'@

# 4. backend/src/config/env.js
Write-ProjectFile -RelativePath "backend\src\config\env.js" -Content @'
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
'@

# 5. backend/src/models/schemas.js
Write-ProjectFile -RelativePath "backend\src\models\schemas.js" -Content @'
const mongoose = require('mongoose');

const customIdValidator = {
  validator: function (v) {
    return typeof v === 'string' && v.trim().length > 0 && v.length <= 25;
  },
  message: (props) => `ID '${props.value}' must be a non-empty string of at most 25 characters.`
};

// 1. STUDENT(userId PK, preferredLanguage, isAuthenticated)
const studentSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true, validate: customIdValidator },
  preferredLanguage: { type: String, default: 'en' },
  isAuthenticated: { type: Boolean, default: false },
  name: { type: String, default: 'Visitor' },
  email: { type: String, default: '' },
  enrollmentNo: { type: String, default: '' },
  program: { type: String, default: 'B.Tech CSE' },
  semester: { type: Number, default: 5 },
  role: { type: String, enum: ['anonymous', 'student'], default: 'anonymous' },
  passwordHash: { type: String, default: '' }
}, { _id: false, versionKey: false });

// 2. CHATBOT_WIDGET(widgetId PK, userId FK, isVisible)
const chatbotWidgetSchema = new mongoose.Schema({
  widgetId: { type: String, required: true, unique: true, validate: customIdValidator },
  userId: { type: String, required: true, validate: customIdValidator },
  isVisible: { type: Boolean, default: true }
}, { _id: false, versionKey: false });

// 3. USER_QUERY(queryId PK, userId FK, widgetId FK, queryText, language, timestamp)
const userQuerySchema = new mongoose.Schema({
  queryId: { type: String, required: true, unique: true, validate: customIdValidator },
  userId: { type: String, required: true, validate: customIdValidator },
  widgetId: { type: String, required: true, validate: customIdValidator },
  queryText: { type: String, required: true, trim: true, minLength: 1 },
  language: { type: String, default: 'en' },
  timestamp: { type: String, required: true }
}, { _id: false, versionKey: false });

// 4. BACKEND_QUERY_PROCESSOR(processorId PK, queryId FK, activeSessionId, dbUri, indexName, apiEndpoint)
const backendQueryProcessorSchema = new mongoose.Schema({
  processorId: { type: String, required: true, unique: true, validate: customIdValidator },
  queryId: { type: String, required: true, validate: customIdValidator },
  activeSessionId: { type: String, required: true },
  dbUri: { type: String, required: true },
  indexName: { type: String, required: true },
  apiEndpoint: { type: String, required: true }
}, { _id: false, versionKey: false });

// 5. CHATBOT_RESPONSE(responseId PK, processorId FK, generatedText, translatedText, targetLanguage)
const chatbotResponseSchema = new mongoose.Schema({
  responseId: { type: String, required: true, unique: true, validate: customIdValidator },
  processorId: { type: String, required: true, validate: customIdValidator },
  generatedText: { type: String, required: true },
  translatedText: { type: String, required: true },
  targetLanguage: { type: String, default: 'en' }
}, { _id: false, versionKey: false });

// 6. CHAT_SESSION_HISTORY(historyId PK, widgetId FK, sessionId, messageText, timestamp, role user|assistant)
const chatSessionHistorySchema = new mongoose.Schema({
  historyId: { type: String, required: true, unique: true, validate: customIdValidator },
  widgetId: { type: String, required: true, validate: customIdValidator },
  sessionId: { type: String, required: true },
  messageText: { type: String, required: true },
  timestamp: { type: String, required: true },
  role: { type: String, enum: ['user', 'assistant'], required: true }
}, { _id: false, versionKey: false });

// 7. SESSION_LOG(logId PK, dbUri, sessionId, queryText, responseText, timestamp)
const sessionLogSchema = new mongoose.Schema({
  logId: { type: String, required: true, unique: true, validate: customIdValidator },
  dbUri: { type: String, required: true },
  sessionId: { type: String, required: true },
  userId: { type: String, default: 'anon_guest' },
  queryText: { type: String, required: true },
  responseText: { type: String, required: true },
  language: { type: String, default: 'en' },
  timestamp: { type: String, required: true }
}, { _id: false, versionKey: false });

// 8. SMART_FAQ(faqId PK, dbUri, question, answerText, category, lastUpdated)
const smartFaqSchema = new mongoose.Schema({
  faqId: { type: String, required: true, unique: true, validate: customIdValidator },
  dbUri: { type: String, required: true },
  question: { type: String, required: true, trim: true, minLength: 3 },
  answerText: { type: String, required: true, trim: true, minLength: 3 },
  category: { type: String, required: true, trim: true },
  lastUpdated: { type: String, required: true }
}, { _id: false, versionKey: false });

// 9. ADMIN_STAFF(staffId PK, dbUri, indexName, role)
const adminStaffSchema = new mongoose.Schema({
  staffId: { type: String, required: true, unique: true, validate: customIdValidator },
  dbUri: { type: String, required: true },
  indexName: { type: String, required: true },
  role: { type: String, default: 'admin_staff' },
  username: { type: String, required: true },
  name: { type: String, default: 'Admin Staff' },
  passwordHash: { type: String, required: true }
}, { _id: false, versionKey: false });

// 10. SYSTEM_ADMINISTRATOR(adminId PK, staffId FK, apiEndpoint, role)
const systemAdministratorSchema = new mongoose.Schema({
  adminId: { type: String, required: true, unique: true, validate: customIdValidator },
  staffId: { type: String, required: true, validate: customIdValidator },
  apiEndpoint: { type: String, required: true },
  role: { type: String, default: 'system_admin' },
  username: { type: String, required: true },
  name: { type: String, default: 'System Administrator' },
  passwordHash: { type: String, required: true }
}, { _id: false, versionKey: false });

// 11. SERVICE_CONFIG (JWT_AUTH_SERVICE, MONGODB_REPOSITORY, PINECONE_VECTOR_DB, PINECONE_VECTOR_ADAPTER, AI_TRANSLATION_SERVICE)
const serviceConfigSchema = new mongoose.Schema({
  configId: { type: String, required: true, unique: true, validate: customIdValidator },
  serviceName: { type: String, required: true },
  supportedLanguages: { type: [String], default: ['en', 'hi', 'mr', 'ta', 'bn', 'pa'] },
  rateLimitMax: { type: Number, default: 120 },
  rateLimitWindowMs: { type: Number, default: 60000 },
  apiEndpoint: { type: String, default: '' },
  indexName: { type: String, default: '' },
  dbUri: { type: String, default: '' },
  maskedSecretHint: { type: String, default: '***MASKED***' },
  updatedAt: { type: String, required: true }
}, { _id: false, versionKey: false });

const Models = {
  Student: mongoose.models.Student || mongoose.model('Student', studentSchema),
  ChatbotWidget: mongoose.models.ChatbotWidget || mongoose.model('ChatbotWidget', chatbotWidgetSchema),
  UserQuery: mongoose.models.UserQuery || mongoose.model('UserQuery', userQuerySchema),
  BackendQueryProcessor: mongoose.models.BackendQueryProcessor || mongoose.model('BackendQueryProcessor', backendQueryProcessorSchema),
  ChatbotResponse: mongoose.models.ChatbotResponse || mongoose.model('ChatbotResponse', chatbotResponseSchema),
  ChatSessionHistory: mongoose.models.ChatSessionHistory || mongoose.model('ChatSessionHistory', chatSessionHistorySchema),
  SessionLog: mongoose.models.SessionLog || mongoose.model('SessionLog', sessionLogSchema),
  SmartFAQ: mongoose.models.SmartFAQ || mongoose.model('SmartFAQ', smartFaqSchema),
  AdminStaff: mongoose.models.AdminStaff || mongoose.model('AdminStaff', adminStaffSchema),
  SystemAdministrator: mongoose.models.SystemAdministrator || mongoose.model('SystemAdministrator', systemAdministratorSchema),
  ServiceConfig: mongoose.models.ServiceConfig || mongoose.model('ServiceConfig', serviceConfigSchema)
};

module.exports = { Models, customIdValidator };
'@

# 6. backend/src/config/db.js
Write-ProjectFile -RelativePath "backend\src\config\db.js" -Content @'
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const config = require('./env');

const DATA_DIR = path.resolve(__dirname, '../../data');
const MOCK_DB_FILE = path.join(DATA_DIR, 'mock-db.json');

const EMPTY_STORE = {
  students: [],
  widgets: [],
  userQueries: [],
  processors: [],
  responses: [],
  sessionHistory: [],
  sessionLogs: [],
  smartFaqs: [],
  adminStaff: [],
  systemAdmins: [],
  serviceConfigs: []
};

class DatabaseManager {
  constructor() {
    this.connected = false;
    this.mode = config.mockMode ? 'mock-json-mongoose' : 'mongodb';
    this.store = JSON.parse(JSON.stringify(EMPTY_STORE));
    this.simulateFailure = false;
  }

  ensureDataDir() {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
  }

  loadFromDisk() {
    this.ensureDataDir();
    if (fs.existsSync(MOCK_DB_FILE)) {
      try {
        const raw = fs.readFileSync(MOCK_DB_FILE, 'utf8');
        const parsed = JSON.parse(raw);
        this.store = Object.assign({}, JSON.parse(JSON.stringify(EMPTY_STORE)), parsed);
      } catch (_err) {
        this.store = JSON.parse(JSON.stringify(EMPTY_STORE));
      }
    }
  }

  saveToDisk() {
    if (!config.mockMode) return;
    this.ensureDataDir();
    fs.writeFileSync(MOCK_DB_FILE, JSON.stringify(this.store, null, 2), 'utf8');
  }

  async connect() {
    if (config.mockMode) {
      this.loadFromDisk();
      this.connected = true;
      this.mode = 'mock-json-mongoose';
      return { connected: true, mode: this.mode };
    }

    await mongoose.connect(config.mongodbUri, { serverSelectionTimeoutMS: 5000 });
    this.connected = true;
    this.mode = 'mongodb';
    return { connected: true, mode: this.mode };
  }

  getStatus() {
    if (this.simulateFailure) {
      return { connected: false, mode: this.mode, error: 'Simulated MongoDB connection outage' };
    }
    return {
      connected: this.connected,
      mode: this.mode,
      uri: config.mockMode ? 'mock://local-json-store/askuni_aur' : config.mongodbUri.replace(/\/\/.*@/, '//***:***@')
    };
  }
}

const dbManager = new DatabaseManager();
module.exports = { dbManager, MOCK_DB_FILE, EMPTY_STORE };
'@

# 7. backend/src/adapters/MongoDBRepository.js
Write-ProjectFile -RelativePath "backend\src\adapters\MongoDBRepository.js" -Content @'
const { Models } = require('../models/schemas');
const { dbManager } = require('../config/db');
const config = require('../config/env');

class AppError extends Error {
  constructor(message, statusCode = 400, code = 'VALIDATION_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

class MongoDBRepository {
  constructor() {
    this.dbUri = config.mockMode ? 'mock://local-json-store/askuni_aur' : config.mongodbUri;
  }

  assertAvailable() {
    if (dbManager.simulateFailure) {
      throw new AppError('MongoDB repository is currently unreachable.', 503, 'MONGODB_UNAVAILABLE');
    }
    if (!dbManager.connected) {
      dbManager.loadFromDisk();
      dbManager.connected = true;
    }
  }

  validateMongooseDoc(ModelClass, doc) {
    const instance = new ModelClass(doc);
    const err = instance.validateSync();
    if (err) {
      const firstKey = Object.keys(err.errors)[0];
      const msg = firstKey ? err.errors[firstKey].message : err.message;
      throw new AppError(msg, 400, 'SCHEMA_VALIDATION_ERROR');
    }
    return instance.toObject();
  }

  validateIdLength(id, fieldName = 'id') {
    if (typeof id !== 'string' || id.trim().length === 0 || id.length > 25) {
      throw new AppError(
        `${fieldName} '${id}' is invalid: custom IDs must be 1 to 25 characters (received ${typeof id === 'string' ? id.length : 0}).`,
        400,
        'INVALID_ID_LENGTH'
      );
    }
  }

  // Generic insert with PK uniqueness, <=25 char check, and FK integrity
  async insertRecord(collectionKey, pkField, ModelClass, record, foreignChecks = []) {
    this.assertAvailable();
    this.validateIdLength(record[pkField], pkField);
    const cleanDoc = this.validateMongooseDoc(ModelClass, record);

    const list = dbManager.store[collectionKey];
    if (list.some((item) => item[pkField] === cleanDoc[pkField])) {
      throw new AppError(
        `Duplicate primary key '${cleanDoc[pkField]}' for ${pkField} in ${collectionKey}.`,
        409,
        'DUPLICATE_PRIMARY_KEY'
      );
    }

    for (const fk of foreignChecks) {
      const fkVal = cleanDoc[fk.field];
      this.validateIdLength(fkVal, fk.field);
      const targetList = dbManager.store[fk.targetCollection] || [];
      const exists = targetList.some((row) => row[fk.targetField] === fkVal);
      if (!exists) {
        throw new AppError(
          `Foreign key constraint failed: ${fk.field}='${fkVal}' does not exist in ${fk.targetCollection}.${fk.targetField}.`,
          400,
          'FOREIGN_KEY_VIOLATION'
        );
      }
    }

    list.push(cleanDoc);
    dbManager.saveToDisk();
    return cleanDoc;
  }

  // Student & Widget operations
  async ensureStudentAndWidget(userId, preferredLanguage = 'en', isAuthenticated = false, name = 'Visitor') {
    this.assertAvailable();
    this.validateIdLength(userId, 'userId');
    let student = dbManager.store.students.find((s) => s.userId === userId);
    if (!student) {
      student = await this.insertRecord('students', 'userId', Models.Student, {
        userId,
        preferredLanguage,
        isAuthenticated,
        name,
        role: isAuthenticated ? 'student' : 'anonymous'
      });
    } else if (preferredLanguage && student.preferredLanguage !== preferredLanguage) {
      student.preferredLanguage = preferredLanguage;
      dbManager.saveToDisk();
    }

    const widgetId = `w_${userId}`.slice(0, 25);
    let widget = dbManager.store.widgets.find((w) => w.widgetId === widgetId);
    if (!widget) {
      widget = await this.insertRecord(
        'widgets',
        'widgetId',
        Models.ChatbotWidget,
        { widgetId, userId, isVisible: true },
        [{ field: 'userId', targetCollection: 'students', targetField: 'userId' }]
      );
    }
    return { student, widget };
  }

  async findStudentByUsernameOrId(identifier) {
    this.assertAvailable();
    return dbManager.store.students.find(
      (s) => s.userId === identifier || s.email.toLowerCase() === String(identifier).toLowerCase() || s.enrollmentNo.toLowerCase() === String(identifier).toLowerCase()
    ) || null;
  }

  async findAdminStaffByUsername(username) {
    this.assertAvailable();
    return dbManager.store.adminStaff.find((a) => a.username.toLowerCase() === String(username).toLowerCase()) || null;
  }

  async findSystemAdminByUsername(username) {
    this.assertAvailable();
    return dbManager.store.systemAdmins.find((a) => a.username.toLowerCase() === String(username).toLowerCase()) || null;
  }

  // Smart FAQs
  async fetchSmartFAQs(queryText = '', category = '') {
    this.assertAvailable();
    let faqs = [...dbManager.store.smartFaqs];
    if (category && category !== 'all') {
      faqs = faqs.filter((f) => f.category.toLowerCase() === category.toLowerCase());
    }
    if (!queryText || !queryText.trim()) {
      return faqs;
    }

    const tokens = queryText
      .toLowerCase()
      .replace(/[^\w\s\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0B80-\u0BFF]/g, ' ')
      .split(/\s+/)
      .filter((t) => t.length > 1);

    const scored = faqs.map((faq) => {
      const hay = `${faq.question} ${faq.answerText} ${faq.category}`.toLowerCase();
      let score = 0;
      for (const tok of tokens) {
        if (hay.includes(tok)) score += 1;
      }
      return { faq, score };
    });

    return scored
      .filter((item) => item.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5)
      .map((item) => item.faq);
  }

  async createFAQEntry({ faqId, question, answerText, category }) {
    this.assertAvailable();
    const id = faqId || `faq_${Date.now().toString(36)}`.slice(0, 25);
    return this.insertRecord('smartFaqs', 'faqId', Models.SmartFAQ, {
      faqId: id,
      dbUri: this.dbUri,
      question,
      answerText,
      category,
      lastUpdated: new Date().toISOString()
    });
  }

  async updateFAQEntry(faqId, updates) {
    this.assertAvailable();
    this.validateIdLength(faqId, 'faqId');
    const idx = dbManager.store.smartFaqs.findIndex((f) => f.faqId === faqId);
    if (idx === -1) {
      throw new AppError(`Smart FAQ '${faqId}' not found.`, 404, 'FAQ_NOT_FOUND');
    }
    const existing = dbManager.store.smartFaqs[idx];
    const merged = {
      ...existing,
      question: updates.question !== undefined ? updates.question : existing.question,
      answerText: updates.answerText !== undefined ? updates.answerText : existing.answerText,
      category: updates.category !== undefined ? updates.category : existing.category,
      lastUpdated: new Date().toISOString()
    };
    const validated = this.validateMongooseDoc(Models.SmartFAQ, merged);
    dbManager.store.smartFaqs[idx] = validated;
    dbManager.saveToDisk();
    return validated;
  }

  async deleteFAQEntry(faqId) {
    this.assertAvailable();
    this.validateIdLength(faqId, 'faqId');
    const idx = dbManager.store.smartFaqs.findIndex((f) => f.faqId === faqId);
    if (idx === -1) {
      throw new AppError(`Smart FAQ '${faqId}' not found.`, 404, 'FAQ_NOT_FOUND');
    }
    const [removed] = dbManager.store.smartFaqs.splice(idx, 1);
    dbManager.saveToDisk();
    return removed;
  }

  // RAG Execution Chain & Chat Logs
  async recordQueryExecutionChain({
    userQuery,
    processor,
    chatbotResponse,
    widgetId,
    sessionId,
    userId
  }) {
    this.assertAvailable();

    const savedQuery = await this.insertRecord(
      'userQueries',
      'queryId',
      Models.UserQuery,
      userQuery,
      [
        { field: 'userId', targetCollection: 'students', targetField: 'userId' },
        { field: 'widgetId', targetCollection: 'widgets', targetField: 'widgetId' }
      ]
    );

    const savedProcessor = await this.insertRecord(
      'processors',
      'processorId',
      Models.BackendQueryProcessor,
      processor,
      [{ field: 'queryId', targetCollection: 'userQueries', targetField: 'queryId' }]
    );

    const savedResponse = await this.insertRecord(
      'responses',
      'responseId',
      Models.ChatbotResponse,
      chatbotResponse,
      [{ field: 'processorId', targetCollection: 'processors', targetField: 'processorId' }]
    );

    const nowIso = new Date().toISOString();
    const histUser = await this.insertRecord(
      'sessionHistory',
      'historyId',
      Models.ChatSessionHistory,
      {
        historyId: `hu_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25),
        widgetId,
        sessionId,
        messageText: userQuery.queryText,
        timestamp: userQuery.timestamp || nowIso,
        role: 'user'
      },
      [{ field: 'widgetId', targetCollection: 'widgets', targetField: 'widgetId' }]
    );

    const histBot = await this.insertRecord(
      'sessionHistory',
      'historyId',
      Models.ChatSessionHistory,
      {
        historyId: `hb_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25),
        widgetId,
        sessionId,
        messageText: chatbotResponse.translatedText,
        timestamp: nowIso,
        role: 'assistant'
      },
      [{ field: 'widgetId', targetCollection: 'widgets', targetField: 'widgetId' }]
    );

    const logEntry = await this.saveChatLog({
      logId: `lg_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25),
      dbUri: this.dbUri,
      sessionId,
      userId,
      queryText: userQuery.queryText,
      responseText: chatbotResponse.translatedText,
      language: chatbotResponse.targetLanguage,
      timestamp: nowIso
    });

    return { savedQuery, savedProcessor, savedResponse, histUser, histBot, logEntry };
  }

  async saveChatLog(logData) {
    this.assertAvailable();
    return this.insertRecord('sessionLogs', 'logId', Models.SessionLog, logData);
  }

  async queryRecentSessions({ date = '', language = '', keyword = '' } = {}) {
    this.assertAvailable();
    let logs = [...dbManager.store.sessionLogs];

    if (date) {
      logs = logs.filter((l) => l.timestamp.startsWith(date));
    }
    if (language && language !== 'all') {
      logs = logs.filter((l) => l.language.toLowerCase() === language.toLowerCase());
    }
    if (keyword && keyword.trim()) {
      const kw = keyword.toLowerCase();
      logs = logs.filter(
        (l) =>
          l.queryText.toLowerCase().includes(kw) ||
          l.responseText.toLowerCase().includes(kw) ||
          l.sessionId.toLowerCase().includes(kw)
      );
    }

    logs.sort((a, b) => b.timestamp.localeCompare(a.timestamp));

    const sessionMap = new Map();
    for (const log of logs) {
      if (!sessionMap.has(log.sessionId)) {
        sessionMap.set(log.sessionId, {
          sessionId: log.sessionId,
          userId: log.userId,
          language: log.language,
          lastTimestamp: log.timestamp,
          latestQuery: log.queryText,
          latestResponse: log.responseText,
          turnCount: 0
        });
      }
      sessionMap.get(log.sessionId).turnCount += 1;
    }

    return {
      sessions: Array.from(sessionMap.values()),
      logs
    };
  }

  async getSessionDetail(sessionId) {
    this.assertAvailable();
    const logs = dbManager.store.sessionLogs
      .filter((l) => l.sessionId === sessionId)
      .sort((a, b) => a.timestamp.localeCompare(b.timestamp));

    const history = dbManager.store.sessionHistory
      .filter((h) => h.sessionId === sessionId)
      .sort((a, b) => a.timestamp.localeCompare(b.timestamp));

    return { sessionId, logs, history };
  }

  async getTrendingQuestions() {
    this.assertAvailable();
    const counts = new Map();
    for (const log of dbManager.store.sessionLogs) {
      const normalized = log.queryText.trim();
      if (!normalized) continue;
      const key = normalized.toLowerCase();
      if (!counts.has(key)) {
        counts.set(key, {
          question: normalized,
          count: 0,
          lastAsked: log.timestamp,
          sampleResponse: log.responseText
        });
      }
      const entry = counts.get(key);
      entry.count += 1;
      if (log.timestamp > entry.lastAsked) {
        entry.lastAsked = log.timestamp;
        entry.sampleResponse = log.responseText;
      }
    }
    return Array.from(counts.values()).sort((a, b) => b.count - a.count).slice(0, 10);
  }

  async getServiceConfigs() {
    this.assertAvailable();
    return dbManager.store.serviceConfigs;
  }

  async updateServiceConfig(configId, patch) {
    this.assertAvailable();
    const idx = dbManager.store.serviceConfigs.findIndex((c) => c.configId === configId);
    if (idx === -1) {
      throw new AppError(`ServiceConfig '${configId}' not found.`, 404, 'CONFIG_NOT_FOUND');
    }
    const updated = {
      ...dbManager.store.serviceConfigs[idx],
      ...patch,
      updatedAt: new Date().toISOString()
    };
    const validated = this.validateMongooseDoc(Models.ServiceConfig, updated);
    dbManager.store.serviceConfigs[idx] = validated;
    dbManager.saveToDisk();
    return validated;
  }
}

module.exports = { MongoDBRepository, AppError };
'@

# 8. backend/src/adapters/PineconeVectorAdapter.js
Write-ProjectFile -RelativePath "backend\src\adapters\PineconeVectorAdapter.js" -Content @'
const fs = require('fs');
const path = require('path');
const config = require('../config/env');

const KB_FILE = path.resolve(__dirname, '../../data/knowledge-base.json');

class PineconeVectorAdapter {
  constructor() {
    this.indexName = config.pineconeIndex;
    this.simulateFailure = false;
    this.documents = [];
    this.loadDocuments();
  }

  loadDocuments() {
    try {
      if (fs.existsSync(KB_FILE)) {
        this.documents = JSON.parse(fs.readFileSync(KB_FILE, 'utf8'));
      }
    } catch (_err) {
      this.documents = [];
    }
  }

  saveDocuments() {
    const dir = path.dirname(KB_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(KB_FILE, JSON.stringify(this.documents, null, 2), 'utf8');
  }

  // Deterministic lightweight bag-of-words embedding vector (16 dims) for mock mode
  async retrieveEmbeddings(text) {
    if (this.simulateFailure) {
      throw new Error('Pinecone embedding service unavailable');
    }
    if (!config.mockMode && config.openaiApiKey) {
      const resp = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.openaiApiKey}`
        },
        body: JSON.stringify({
          model: config.openaiEmbeddingModel,
          input: text
        })
      });
      if (!resp.ok) throw new Error(`OpenAI Embeddings HTTP ${resp.status}`);
      const data = await resp.json();
      return data.data[0].embedding;
    }

    const vec = new Array(16).fill(0);
    const clean = String(text || '').toLowerCase();
    for (let i = 0; i < clean.length; i += 1) {
      vec[i % 16] += clean.charCodeAt(i) / 1000;
    }
    const norm = Math.sqrt(vec.reduce((s, v) => s + v * v, 0)) || 1;
    return vec.map((v) => Number((v / norm).toFixed(4)));
  }

  async searchVectorContext(queryText, topK = 4) {
    if (this.simulateFailure) {
      throw new Error('Pinecone Vector DB connection timed out');
    }

    if (!config.mockMode && config.pineconeApiKey && config.pineconeHost) {
      const vector = await this.retrieveEmbeddings(queryText);
      const resp = await fetch(`${config.pineconeHost}/query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': config.pineconeApiKey
        },
        body: JSON.stringify({ vector, topK, includeMetadata: true })
      });
      if (!resp.ok) throw new Error(`Pinecone query HTTP ${resp.status}`);
      const json = await resp.json();
      return (json.matches || []).map((m) => ({
        docId: m.id,
        title: m.metadata?.title || 'Institutional Document',
        category: m.metadata?.category || 'Circular',
        content: m.metadata?.content || '',
        score: m.score || 0
      }));
    }

    // Mock TF-IDF / keyword overlap retrieval over local knowledge-base.json
    if (this.documents.length === 0) {
      this.loadDocuments();
    }

    const tokens = String(queryText || '')
      .toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter((t) => t.length > 1);

    if (tokens.length === 0) return [];

    const scored = this.documents.map((doc) => {
      const hay = `${doc.title} ${doc.category} ${doc.content}`.toLowerCase();
      let matches = 0;
      for (const tok of tokens) {
        if (hay.includes(tok)) {
          matches += doc.title.toLowerCase().includes(tok) ? 2 : 1;
        }
      }
      const score = Number((matches / (tokens.length + 2)).toFixed(3));
      return { ...doc, score };
    });

    return scored
      .filter((d) => d.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, topK);
  }

  async upsertDocument({ title, category, content }) {
    if (this.simulateFailure) {
      throw new Error('Pinecone Vector DB unavailable for upsert');
    }
    const cleanText = String(content || '').trim();
    const chunkSize = 500;
    const chunks = [];
    for (let i = 0; i < cleanText.length; i += chunkSize) {
      chunks.push(cleanText.slice(i, i + chunkSize));
    }
    if (chunks.length === 0) chunks.push('');

    const created = [];
    for (let idx = 0; idx < chunks.length; idx += 1) {
      const docId = `kb_${Date.now().toString(36)}_${idx}`.slice(0, 25);
      const embedding = await this.retrieveEmbeddings(chunks[idx]);
      const record = {
        docId,
        title: chunks.length > 1 ? `${title} (Part ${idx + 1})` : title,
        category: category || 'Circular',
        content: chunks[idx],
        embeddingPreview: embedding.slice(0, 4),
        updatedAt: new Date().toISOString()
      };
      this.documents.push(record);
      created.push(record);
    }
    this.saveDocuments();
    return created;
  }

  getAllDocuments() {
    if (this.documents.length === 0) {
      this.loadDocuments();
    }
    return this.documents;
  }

  isHealthy() {
    return !this.simulateFailure;
  }
}

module.exports = { PineconeVectorAdapter, KB_FILE };
'@

# 9. backend/src/adapters/AIServiceAdapter.js
Write-ProjectFile -RelativePath "backend\src\adapters\AIServiceAdapter.js" -Content @'
const config = require('../config/env');

class AIServiceAdapter {
  constructor() {
    this.simulateFailure = false;
  }

  async generateGroundedAnswer({ queryText, mergedContext, userContext }) {
    if (this.simulateFailure) {
      throw new Error('AI LLM service failed to generate a response.');
    }

    const hasContext = Array.isArray(mergedContext) && mergedContext.length > 0;

    if (!config.mockMode && config.openaiApiKey) {
      const systemPrompt = [
        'You are AskUni, the official AI assistant for Amity University Rajasthan (Jaipur).',
        'Answer strictly using ONLY the provided institutional context.',
        'If the provided context does not contain the answer, clearly state that the information is unavailable in official records and suggest contacting the Amity University Rajasthan Academic / Admissions Office (+91-1426-405555 or admissions@jpr.amity.edu).',
        'Never fabricate dates, fees, or policies.'
      ].join(' ');

      const contextBlock = hasContext
        ? mergedContext.map((c, i) => `[${i + 1}] (${c.source} - ${c.title}): ${c.text}`).join('\n')
        : 'NO MATCHING CONTEXT FOUND.';

      const resp = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.openaiApiKey}`
        },
        body: JSON.stringify({
          model: config.openaiModel,
          temperature: 0.1,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: `Context:\n${contextBlock}\n\nStudent Question: ${queryText}` }
          ]
        })
      });

      if (!resp.ok) {
        throw new Error(`OpenAI Chat API returned HTTP ${resp.status}`);
      }
      const data = await resp.json();
      return {
        text: data.choices[0].message.content.trim(),
        grounded: hasContext,
        sourceCount: mergedContext.length
      };
    }

    // Deterministic grounded mock synthesis
    if (!hasContext) {
      return {
        text: 'I could not find verified information about that in Amity University Rajasthan\'s current circulars, FAQs, or handbooks. Please contact the Amity University Rajasthan Administrative / Academic Office at +91-1426-405555 or visit Block-A Student Facilitation Desk for official assistance.',
        grounded: false,
        sourceCount: 0
      };
    }

    const topItems = mergedContext.slice(0, 2);
    const primary = topItems[0];
    const greeting = userContext && userContext.isAuthenticated && userContext.name
      ? `Hello ${userContext.name}, based on official Amity University Rajasthan records: `
      : 'Based on official Amity University Rajasthan records: ';

    let synthesized = `${greeting}${primary.text}`;
    if (topItems.length > 1 && topItems[1].text !== primary.text) {
      synthesized += ` Additionally (${topItems[1].title}): ${topItems[1].text}`;
    }

    return {
      text: synthesized,
      grounded: true,
      sourceCount: topItems.length
    };
  }

  isHealthy() {
    return !this.simulateFailure;
  }
}

module.exports = { AIServiceAdapter };
'@

# 10. backend/src/adapters/TranslationServiceAdapter.js
Write-ProjectFile -RelativePath "backend\src\adapters\TranslationServiceAdapter.js" -Content @'
const config = require('../config/env');

const SUPPORTED_LANGUAGES = ['en', 'hi', 'mr', 'ta', 'bn', 'pa'];

const LANGUAGE_LABELS = {
  en: 'English',
  hi: 'Hindi (हिन्दी)',
  mr: 'Marathi (मराठी)',
  ta: 'Tamil (தமிழ்)',
  bn: 'Bengali (বাংলা)',
  pa: 'Punjabi (ਪੰਜਾਬੀ)'
};

// Phrase & vocabulary dictionary for realistic offline/mock regional translation
const PHRASE_DICTIONARY = {
  hi: {
    prefix: '[हिन्दी अनुवाद] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'एमिटी विश्वविद्यालय राजस्थान के आधिकारिक रिकॉर्ड के अनुसार:'],
      [/I could not find verified information about that/gi, 'मुझे इसके बारे में सत्यापित जानकारी नहीं मिली'],
      [/Please contact the Amity University Rajasthan Administrative \/ Academic Office/gi, 'कृपया एमिटी विश्वविद्यालय राजस्थान के प्रशासनिक / शैक्षणिक कार्यालय से संपर्क करें'],
      [/End-Semester Theory Examinations/gi, 'सेमेस्टर अंत सिद्धांत परीक्षाएं'],
      [/B\.Tech CSE/gi, 'बी.टेक सीएसई'],
      [/tuition fee/gi, 'शिक्षण शुल्क'],
      [/hostel/gi, 'छात्रावास'],
      [/scholarship/gi, 'छात्रवृत्ति'],
      [/attendance/gi, 'उपस्थिति'],
      [/timetable/gi, 'समय-सारणी'],
      [/library/gi, 'पुस्तकालय']
    ]
  },
  mr: {
    prefix: '[मराठी भाषांतर] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'अॅमिटी विद्यापीठ राजस्थानच्या अधिकृत नोंदीनुसार:'],
      [/I could not find verified information about that/gi, 'मला याबद्दल अधिकृत माहिती सापडली नाही'],
      [/tuition fee/gi, 'शिक्षण शुल्क'],
      [/hostel/gi, 'वसतिगृह'],
      [/scholarship/gi, 'शिष्यवृत्ती'],
      [/attendance/gi, 'उपस्थिती']
    ]
  },
  ta: {
    prefix: '[தமிழ் மொழிபெயர்ப்பு] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'அமிட்டி பல்கலைக்கழகம் ராஜஸ்தான் அதிகாரப்பூர்வ பதிவுகளின்படி:'],
      [/I could not find verified information about that/gi, 'இது குறித்த சரிபார்க்கப்பட்ட தகவல் கிடைக்கவில்லை'],
      [/tuition fee/gi, 'கல்விக் கட்டணம்'],
      [/hostel/gi, 'விடுதி'],
      [/scholarship/gi, 'உதவித்தொகை']
    ]
  },
  bn: {
    prefix: '[বাংলা অনুবাদ] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'অ্যামিটি বিশ্ববিদ্যালয় রাজস্থানের অফিসিয়াল রেকর্ড অনুযায়ী:'],
      [/I could not find verified information about that/gi, 'আমি এই বিষয়ে যাচাইকৃত তথ্য খুঁজে পাইনি'],
      [/tuition fee/gi, 'টিউশন ফি'],
      [/hostel/gi, 'হোস্টেল'],
      [/scholarship/gi, 'বৃত্তি']
    ]
  },
  pa: {
    prefix: '[ਪੰਜਾਬੀ ਅਨੁਵਾਦ] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'ਐਮਿਟੀ ਯੂਨੀਵਰਸਿਟੀ ਰਾਜਸਥਾਨ ਦੇ ਅਧਿਕਾਰਤ ਰਿਕਾਰਡ ਅਨੁਸਾਰ:'],
      [/I could not find verified information about that/gi, 'ਮੈਨੂੰ ਇਸ ਬਾਰੇ ਪ੍ਰਮਾਣਿਤ ਜਾਣਕਾਰੀ ਨਹੀਂ ਮਿਲੀ'],
      [/tuition fee/gi, 'ਟਿਊਸ਼ਨ ਫੀਸ'],
      [/hostel/gi, 'ਹੋਸਟਲ'],
      [/scholarship/gi, 'ਵਜ਼ੀਫ਼ਾ']
    ]
  }
};

class TranslationServiceAdapter {
  constructor() {
    this.simulateFailure = false;
  }

  detectLanguage(text) {
    const s = String(text || '');
    if (/[\u0900-\u097F]/.test(s)) {
      // Distinguish Marathi markers vs Hindi Devanagari
      if (/(आहे|काय|किती|कधी|माहिती)/.test(s)) return 'mr';
      return 'hi';
    }
    if (/[\u0B80-\u0BFF]/.test(s)) return 'ta';
    if (/[\u0980-\u09FF]/.test(s)) return 'bn';
    if (/[\u0A00-\u0A7F]/.test(s)) return 'pa';
    return 'en';
  }

  normalizeQueryToEnglish(text) {
    const s = String(text || '');
    const map = [
      [/परीक्षा|एग्जाम|इम्तिहान|परिक्षा|தேர்வு|পরীক্ষা|ਪ੍ਰੀਖਿਆ/gi, 'exam schedule dates'],
      [/फीस|शुल्क|கட்டணம்|ফি|ਫੀਸ/gi, 'fee structure tuition'],
      [/हॉस्टल|छात्रावास|वसतिगृह|விடுதி|হোস্টেল|ਹੋਸਟਲ/gi, 'hostel accommodation'],
      [/छात्रवृत्ति|स्कॉलरशिप|शिष्यवृत्ती|உதவித்தொகை|বৃত্তি|ਵਜ਼ੀਫ਼ਾ/gi, 'scholarship merit'],
      [/टाइमटेबल|समय सारणी|समय-सारणी|கால அட்டவணை|সময়সূচী|ਸਮਾਂ ਸਾਰਣੀ/gi, 'timetable schedule classes'],
      [/प्रवेश|एडमिशन|சேர்க்கை|ভর্তি|ਦਾਖਲਾ/gi, 'admission eligibility'],
      [/उपस्थिति|अटेंडेंस|வருகை|উপস্থিতি|ਹਾਜ਼ਰੀ/gi, 'attendance rule']
    ];
    let enriched = s;
    for (const [pattern, englishHint] of map) {
      if (pattern.test(s)) {
        enriched += ` ${englishHint}`;
      }
    }
    return enriched;
  }

  async translateText(text, targetLanguage = 'en', supportedLanguages = SUPPORTED_LANGUAGES) {
    const lang = String(targetLanguage || 'en').toLowerCase().trim();

    if (!supportedLanguages.includes(lang)) {
      return {
        translatedText: `${text}\n\n[Notice: Requested language '${targetLanguage}' is not currently supported. Showing response in English.]`,
        effectiveLanguage: 'en',
        unsupportedLanguage: true,
        translationFailed: false
      };
    }

    if (lang === 'en') {
      return {
        translatedText: text,
        effectiveLanguage: 'en',
        unsupportedLanguage: false,
        translationFailed: false
      };
    }

    if (this.simulateFailure) {
      return {
        translatedText: text,
        effectiveLanguage: 'en',
        unsupportedLanguage: false,
        translationFailed: true,
        failureReason: 'Translation service temporarily unavailable; original English response preserved.'
      };
    }

    if (!config.mockMode && config.googleTranslateApiKey) {
      try {
        const url = `https://translation.googleapis.com/language/translate/v2?key=${encodeURIComponent(config.googleTranslateApiKey)}`;
        const resp = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ q: text, target: lang, format: 'text' })
        });
        if (!resp.ok) {
          throw new Error(`Google Translate HTTP ${resp.status}`);
        }
        const data = await resp.json();
        return {
          translatedText: data.data.translations[0].translatedText,
          effectiveLanguage: lang,
          unsupportedLanguage: false,
          translationFailed: false
        };
      } catch (err) {
        return {
          translatedText: text,
          effectiveLanguage: 'en',
          unsupportedLanguage: false,
          translationFailed: true,
          failureReason: err.message
        };
      }
    }

    const pack = PHRASE_DICTIONARY[lang];
    let out = text;
    if (pack) {
      for (const [regex, replacement] of pack.replacements) {
        out = out.replace(regex, replacement);
      }
      out = `${pack.prefix}${out}`;
    }

    return {
      translatedText: out,
      effectiveLanguage: lang,
      unsupportedLanguage: false,
      translationFailed: false
    };
  }

  isHealthy() {
    return !this.simulateFailure;
  }
}

module.exports = { TranslationServiceAdapter, SUPPORTED_LANGUAGES, LANGUAGE_LABELS };
'@

# 11. backend/src/services/JWTAuthService.js
Write-ProjectFile -RelativePath "backend\src\services\JWTAuthService.js" -Content @'
const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { AppError } = require('../adapters/MongoDBRepository');

class JWTAuthService {
  constructor() {
    this.activeSecret = config.jwtSecret;
    this.rotationCount = 0;
    this.lastRotatedAt = new Date().toISOString();
  }

  issueToken(payload, expiresIn = config.jwtExpiresIn) {
    return jwt.sign(payload, this.activeSecret, { expiresIn });
  }

  validateToken(token) {
    try {
      return jwt.verify(token, this.activeSecret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        throw new AppError('Authentication token has expired.', 401, 'TOKEN_EXPIRED');
      }
      throw new AppError('Invalid authentication token.', 401, 'INVALID_TOKEN');
    }
  }

  verifyUserStatus(authHeader) {
    if (!authHeader) {
      return {
        isAuthenticated: false,
        role: 'anonymous',
        userId: null,
        name: 'Anonymous Visitor'
      };
    }

    const parts = String(authHeader).split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
      throw new AppError('Malformed Authorization header. Expected Bearer <token>.', 401, 'INVALID_AUTH_HEADER');
    }

    const decoded = this.validateToken(parts[1]);
    return {
      isAuthenticated: decoded.role !== 'anonymous',
      role: decoded.role || 'student',
      userId: decoded.userId,
      staffId: decoded.staffId || null,
      adminId: decoded.adminId || null,
      name: decoded.name || 'Authenticated User',
      preferredLanguage: decoded.preferredLanguage || 'en'
    };
  }

  rotateSecret() {
    const entropy = `${Date.now()}_${Math.random().toString(36).slice(2)}_${Math.random().toString(36).slice(2)}`;
    this.activeSecret = `askuni_rotated_${entropy}`;
    this.rotationCount += 1;
    this.lastRotatedAt = new Date().toISOString();
    // Never return or log this.activeSecret
    return {
      rotated: true,
      rotationCount: this.rotationCount,
      lastRotatedAt: this.lastRotatedAt,
      maskedSecret: '***MASKED***'
    };
  }

  getMaskedMetadata() {
    return {
      algorithm: 'HS256',
      expiresIn: config.jwtExpiresIn,
      rotationCount: this.rotationCount,
      lastRotatedAt: this.lastRotatedAt,
      tokenSecret: '***MASKED***'
    };
  }
}

module.exports = { JWTAuthService };
'@

# 12. backend/src/services/BackendQueryProcessor.js
Write-ProjectFile -RelativePath "backend\src\services\BackendQueryProcessor.js" -Content @'
const { AppError } = require('../adapters/MongoDBRepository');
const config = require('../config/env');

class BackendQueryProcessor {
  constructor({ mongoRepo, pineconeAdapter, aiAdapter, translationAdapter, authService }) {
    this.mongoRepo = mongoRepo;
    this.pineconeAdapter = pineconeAdapter;
    this.aiAdapter = aiAdapter;
    this.translationAdapter = translationAdapter;
    this.authService = authService;
  }

  receiveQuery(rawBody) {
    if (!rawBody || typeof rawBody.queryText !== 'string' || rawBody.queryText.trim().length === 0) {
      throw new AppError('Query text cannot be empty or whitespace only.', 400, 'EMPTY_QUERY');
    }
    const cleanText = rawBody.queryText.trim();
    const detectedLang = this.translationAdapter.detectLanguage(cleanText);
    const requestedLang = rawBody.language && rawBody.language !== 'auto'
      ? String(rawBody.language).trim().toLowerCase()
      : detectedLang;

    const queryId = rawBody.queryId || `q_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.slice(0, 25);
    const sessionId = rawBody.sessionId || `sess_${Date.now().toString(36)}`;

    return {
      queryId,
      sessionId,
      queryText: cleanText,
      language: requestedLang,
      detectedLanguage: detectedLang,
      timestamp: new Date().toISOString()
    };
  }

  authenticateRequest(authHeader) {
    return this.authService.verifyUserStatus(authHeader);
  }

  async retrieveAndMergeContext(queryText) {
    const searchQuery = this.translationAdapter.normalizeQueryToEnglish(queryText);

    const [mongoResult, pineconeResult] = await Promise.allSettled([
      this.mongoRepo.fetchSmartFAQs(searchQuery),
      this.pineconeAdapter.searchVectorContext(searchQuery, 4)
    ]);

    const flags = {
      mongoFailed: mongoResult.status === 'rejected',
      pineconeFailed: pineconeResult.status === 'rejected',
      partialContext: false
    };

    const faqs = mongoResult.status === 'fulfilled' ? mongoResult.value : [];
    const docs = pineconeResult.status === 'fulfilled' ? pineconeResult.value : [];

    if (flags.pineconeFailed && !flags.mongoFailed) {
      flags.partialContext = true;
    }

    // Merge and deduplicate context items
    const merged = [];
    const seen = new Set();

    for (const faq of faqs) {
      const key = faq.question.toLowerCase().trim();
      if (!seen.has(key)) {
        seen.add(key);
        merged.push({
          source: 'SmartFAQ',
          id: faq.faqId,
          title: faq.question,
          category: faq.category,
          text: faq.answerText
        });
      }
    }

    for (const doc of docs) {
      const key = doc.title.toLowerCase().trim();
      if (!seen.has(key)) {
        seen.add(key);
        merged.push({
          source: 'PineconeVectorDB',
          id: doc.docId,
          title: doc.title,
          category: doc.category,
          text: doc.content
        });
      }
    }

    return { mergedContext: merged, flags };
  }

  async orchestrateAIResponse(rawBody, authHeader) {
    const normalized = this.receiveQuery(rawBody);
    const authUser = this.authenticateRequest(authHeader);

    const effectiveUserId = authUser.userId || rawBody.userId || `anon_${normalized.sessionId.slice(-8)}`.slice(0, 25);

    let studentAndWidget = null;
    try {
      studentAndWidget = await this.mongoRepo.ensureStudentAndWidget(
        effectiveUserId,
        normalized.language,
        authUser.isAuthenticated,
        authUser.name
      );
    } catch (_dbErr) {
      // Allow graceful continuation if DB write is temporarily unavailable
      studentAndWidget = {
        student: { userId: effectiveUserId, preferredLanguage: normalized.language, isAuthenticated: authUser.isAuthenticated },
        widget: { widgetId: `w_${effectiveUserId}`.slice(0, 25), userId: effectiveUserId, isVisible: true }
      };
    }

    const { mergedContext, flags } = await this.retrieveAndMergeContext(normalized.queryText);

    // Fetch supportedLanguages from service config if available
    let supportedLanguages = ['en', 'hi', 'mr', 'ta', 'bn', 'pa'];
    try {
      const configs = await this.mongoRepo.getServiceConfigs();
      const transCfg = configs.find((c) => c.configId === 'AI_TRANSLATION_SERVICE');
      if (transCfg && Array.isArray(transCfg.supportedLanguages) && transCfg.supportedLanguages.length > 0) {
        supportedLanguages = transCfg.supportedLanguages;
      }
    } catch (_err) {
      // Use default supported languages
    }

    let aiOutput;
    let aiFailed = false;
    try {
      aiOutput = await this.aiAdapter.generateGroundedAnswer({
        queryText: normalized.queryText,
        mergedContext,
        userContext: authUser
      });
    } catch (err) {
      aiFailed = true;
      aiOutput = {
        text: 'We encountered a temporary issue generating an AI response. Please try again shortly or contact the Amity University Rajasthan Helpdesk.',
        grounded: false,
        sourceCount: 0,
        error: err.message
      };
    }

    const translationOutput = await this.translationAdapter.translateText(
      aiOutput.text,
      normalized.language,
      supportedLanguages
    );

    const processorId = `pr_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.slice(0, 25);
    const responseId = `rs_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.slice(0, 25);

    const userQueryRecord = {
      queryId: normalized.queryId,
      userId: studentAndWidget.student.userId,
      widgetId: studentAndWidget.widget.widgetId,
      queryText: normalized.queryText,
      language: normalized.language,
      timestamp: normalized.timestamp
    };

    const processorRecord = {
      processorId,
      queryId: normalized.queryId,
      activeSessionId: normalized.sessionId,
      dbUri: this.mongoRepo.dbUri,
      indexName: this.pineconeAdapter.indexName || config.pineconeIndex,
      apiEndpoint: '/api/chat/query'
    };

    const responseRecord = {
      responseId,
      processorId,
      generatedText: aiOutput.text,
      translatedText: translationOutput.translatedText,
      targetLanguage: translationOutput.effectiveLanguage
    };

    let persisted = true;
    try {
      await this.mongoRepo.recordQueryExecutionChain({
        userQuery: userQueryRecord,
        processor: processorRecord,
        chatbotResponse: responseRecord,
        widgetId: studentAndWidget.widget.widgetId,
        sessionId: normalized.sessionId,
        userId: studentAndWidget.student.userId
      });
    } catch (_persistErr) {
      persisted = false;
    }

    return {
      responseId,
      processorId,
      queryId: normalized.queryId,
      sessionId: normalized.sessionId,
      userId: studentAndWidget.student.userId,
      widgetId: studentAndWidget.widget.widgetId,
      isAuthenticated: authUser.isAuthenticated,
      role: authUser.role,
      generatedText: aiOutput.text,
      translatedText: translationOutput.translatedText,
      targetLanguage: translationOutput.effectiveLanguage,
      requestedLanguage: normalized.language,
      grounded: aiOutput.grounded,
      sources: mergedContext.map((c) => ({ source: c.source, title: c.title, category: c.category })),
      flags: {
        mongoFailed: flags.mongoFailed,
        pineconeFailed: flags.pineconeFailed,
        partialContext: flags.partialContext,
        aiFailed,
        unsupportedLanguage: translationOutput.unsupportedLanguage,
        translationFailed: translationOutput.translationFailed,
        persisted
      },
      notice: translationOutput.failureReason || (flags.pineconeFailed ? 'Vector knowledge base unavailable; answered using Smart FAQs.' : null),
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = { BackendQueryProcessor };
'@

# 13. backend/src/services/AdminStaffService.js
Write-ProjectFile -RelativePath "backend\src\services\AdminStaffService.js" -Content @'
class AdminStaffService {
  constructor({ mongoRepo, pineconeAdapter }) {
    this.mongoRepo = mongoRepo;
    this.pineconeAdapter = pineconeAdapter;
  }

  async reviewChatLogs(filters) {
    return this.mongoRepo.queryRecentSessions(filters);
  }

  async getSessionDetail(sessionId) {
    return this.mongoRepo.getSessionDetail(sessionId);
  }

  async getTrendingQuestions() {
    return this.mongoRepo.getTrendingQuestions();
  }

  async listSmartFAQs(category = '') {
    return this.mongoRepo.fetchSmartFAQs('', category);
  }

  async updateSmartFAQs(action, payload) {
    if (action === 'create') {
      return this.mongoRepo.createFAQEntry(payload);
    }
    if (action === 'update') {
      return this.mongoRepo.updateFAQEntry(payload.faqId, payload);
    }
    if (action === 'delete') {
      return this.mongoRepo.deleteFAQEntry(payload.faqId);
    }
    throw new Error(`Unsupported Smart FAQ action: ${action}`);
  }

  async uploadKnowledgeDocument({ title, category, content }) {
    const chunks = await this.pineconeAdapter.upsertDocument({ title, category, content });
    return {
      uploaded: true,
      chunksCreated: chunks.length,
      chunks
    };
  }
}

module.exports = { AdminStaffService };
'@

# 14. backend/src/services/InfrastructureAdminService.js
Write-ProjectFile -RelativePath "backend\src\services\InfrastructureAdminService.js" -Content @'
const { dbManager } = require('../config/db');
const { AppError } = require('../adapters/MongoDBRepository');
const { SUPPORTED_LANGUAGES } = require('../adapters/TranslationServiceAdapter');
const config = require('../config/env');

class InfrastructureAdminService {
  constructor({ mongoRepo, pineconeAdapter, aiAdapter, translationAdapter, authService }) {
    this.mongoRepo = mongoRepo;
    this.pineconeAdapter = pineconeAdapter;
    this.aiAdapter = aiAdapter;
    this.translationAdapter = translationAdapter;
    this.authService = authService;
    this.incidentState = 'Healthy';
    this.incidentHistory = [
      { state: 'Healthy', timestamp: new Date().toISOString(), note: 'System initialized cleanly.' }
    ];
    this.rateLimitState = {
      windowMs: config.rateLimitWindowMs,
      maxRequests: config.rateLimitMax,
      totalRequestsObserved: 0,
      blocked429Count: 0
    };
  }

  recordRequest(blocked = false) {
    this.rateLimitState.totalRequestsObserved += 1;
    if (blocked) {
      this.rateLimitState.blocked429Count += 1;
    }
  }

  transitionIncidentState(nextState, note = '') {
    this.incidentState = nextState;
    this.incidentHistory.push({
      state: nextState,
      timestamp: new Date().toISOString(),
      note
    });
  }

  monitorServerHealth() {
    const mem = process.memoryUsage();
    const dbStatus = dbManager.getStatus();
    const pineconeOk = this.pineconeAdapter.isHealthy();
    const aiOk = this.aiAdapter.isHealthy();
    const transOk = this.translationAdapter.isHealthy();

    return {
      status: dbStatus.connected && pineconeOk && aiOk && transOk ? 'healthy' : 'degraded',
      mockMode: config.mockMode,
      uptimeSeconds: Math.round(process.uptime()),
      memory: {
        rssMb: Math.round(mem.rss / 1024 / 1024),
        heapUsedMb: Math.round(mem.heapUsed / 1024 / 1024),
        heapTotalMb: Math.round(mem.heapTotal / 1024 / 1024)
      },
      database: dbStatus,
      externalServices: {
        openai: { available: aiOk, model: config.openaiModel, mode: config.mockMode ? 'mock' : 'live' },
        pinecone: { available: pineconeOk, index: config.pineconeIndex, mode: config.mockMode ? 'mock' : 'live' },
        googleTranslate: { available: transOk, mode: config.mockMode ? 'mock' : 'live' }
      },
      rateLimits: this.rateLimitState,
      incidentState: this.incidentState,
      incidentHistory: this.incidentHistory.slice(-10),
      security: this.authService.getMaskedMetadata(),
      timestamp: new Date().toISOString()
    };
  }

  async getServiceConfigurations() {
    const configs = await this.mongoRepo.getServiceConfigs();
    // Ensure no raw secret ever leaks
    return configs.map((c) => {
      const copy = { ...c };
      delete copy.tokenSecret;
      copy.maskedSecretHint = '***MASKED***';
      return copy;
    });
  }

  async renewCredentials() {
    this.transitionIncidentState('Credential Renewal', 'JWT secret rotation initiated by system_admin.');
    const rotation = this.authService.rotateSecret();

    try {
      await this.mongoRepo.updateServiceConfig('JWT_AUTH_SERVICE', {
        maskedSecretHint: '***MASKED***'
      });
    } catch (_err) {
      // Ignore if seed config hasn't been initialized yet
    }

    this.transitionIncidentState('Rate-Limit Management', 'Verifying active rate-limit guardrails post-rotation.');
    this.transitionIncidentState('Healthy', 'Credential rotation completed; tokens re-anchored.');

    return {
      message: 'JWT signing secret rotated successfully.',
      rotation,
      incidentState: this.incidentState,
      incidentHistory: this.incidentHistory.slice(-5)
    };
  }

  async manageRateLimitsAndConfig({ rateLimitMax, rateLimitWindowMs, supportedLanguages, adminId }) {
    if (adminId !== undefined) {
      this.mongoRepo.validateIdLength(adminId, 'adminId');
    }

    if (rateLimitMax !== undefined) {
      const parsedMax = Number(rateLimitMax);
      if (!Number.isInteger(parsedMax) || parsedMax < 1 || parsedMax > 10000) {
        throw new AppError('rateLimitMax must be an integer between 1 and 10000.', 400, 'INVALID_RATE_LIMIT');
      }
      this.rateLimitState.maxRequests = parsedMax;
    }

    if (rateLimitWindowMs !== undefined) {
      const parsedWin = Number(rateLimitWindowMs);
      if (!Number.isInteger(parsedWin) || parsedWin < 1000 || parsedWin > 3600000) {
        throw new AppError('rateLimitWindowMs must be between 1000 and 3600000 ms.', 400, 'INVALID_RATE_WINDOW');
      }
      this.rateLimitState.windowMs = parsedWin;
    }

    if (supportedLanguages !== undefined) {
      if (!Array.isArray(supportedLanguages) || supportedLanguages.length === 0) {
        throw new AppError('supportedLanguages must be a non-empty array of language codes.', 400, 'INVALID_LANGUAGES');
      }
      const validCodes = supportedLanguages.every((code) => SUPPORTED_LANGUAGES.includes(String(code).toLowerCase()));
      if (!validCodes) {
        throw new AppError(
          `Unsupported language code in list. Allowed codes: ${SUPPORTED_LANGUAGES.join(', ')}`,
          400,
          'UNSUPPORTED_LANGUAGE_CONFIG'
        );
      }
      await this.mongoRepo.updateServiceConfig('AI_TRANSLATION_SERVICE', {
        supportedLanguages: supportedLanguages.map((c) => String(c).toLowerCase())
      });
    }

    try {
      await this.mongoRepo.updateServiceConfig('JWT_AUTH_SERVICE', {
        rateLimitMax: this.rateLimitState.maxRequests,
        rateLimitWindowMs: this.rateLimitState.windowMs,
        maskedSecretHint: '***MASKED***'
      });
    } catch (_err) {
      // Ignore if not seeded
    }

    return {
      updated: true,
      rateLimits: this.rateLimitState,
      services: await this.getServiceConfigurations()
    };
  }
}

module.exports = { InfrastructureAdminService };
'@

# 15. backend/src/middleware/authMiddleware.js
Write-ProjectFile -RelativePath "backend\src\middleware\authMiddleware.js" -Content @'
const { AppError } = require('../adapters/MongoDBRepository');

function createAuthMiddleware(authService) {
  function requireRoles(...allowedRoles) {
    return (req, _res, next) => {
      try {
        const authHeader = req.headers.authorization;
        if (!authHeader) {
          throw new AppError('Authentication required.', 401, 'AUTH_REQUIRED');
        }
        const user = authService.verifyUserStatus(authHeader);
        if (!user.isAuthenticated) {
          throw new AppError('Authenticated role required.', 401, 'AUTH_REQUIRED');
        }
        if (allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
          throw new AppError(
            `Access denied. Role '${user.role}' is not permitted for this resource.`,
            403,
            'FORBIDDEN_ROLE'
          );
        }
        req.user = user;
        next();
      } catch (err) {
        next(err);
      }
    };
  }

  return { requireRoles };
}

module.exports = { createAuthMiddleware };
'@

# 16. backend/src/middleware/validateMiddleware.js
Write-ProjectFile -RelativePath "backend\src\middleware\validateMiddleware.js" -Content @'
const { z } = require('zod');
const { AppError } = require('../adapters/MongoDBRepository');

const schemas = {
  anonymousAuth: z.object({
    preferredLanguage: z.string().min(2).max(10).optional().default('en')
  }),
  loginAuth: z.object({
    username: z.string().min(1, 'Username or enrollment ID is required'),
    password: z.string().min(1, 'Password is required'),
    role: z.enum(['student', 'admin_staff', 'system_admin']).optional()
  }),
  chatQuery: z.object({
    queryId: z.string().max(25).optional(),
    userId: z.string().max(25).optional(),
    sessionId: z.string().max(64).optional(),
    queryText: z.string().refine((val) => val.trim().length > 0, {
      message: 'Query text cannot be empty or whitespace only.'
    }),
    language: z.string().min(2).max(15).optional().default('auto')
  }),
  createFaq: z.object({
    faqId: z.string().min(1).max(25, 'faqId must be at most 25 characters').optional(),
    question: z.string().trim().min(3, 'Question is required (min 3 characters)'),
    answerText: z.string().trim().min(3, 'Answer text is required (min 3 characters)'),
    category: z.string().trim().min(2, 'Category is required')
  }),
  updateFaq: z.object({
    question: z.string().trim().min(3).optional(),
    answerText: z.string().trim().min(3).optional(),
    category: z.string().trim().min(2).optional()
  }),
  uploadKnowledge: z.object({
    title: z.string().trim().min(2, 'Document title is required'),
    category: z.string().trim().min(2, 'Category is required'),
    content: z.string().trim().min(10, 'Document content must be at least 10 characters')
  }),
  updateSysConfig: z.object({
    adminId: z.string().max(25, 'adminId must be at most 25 characters').optional(),
    rateLimitMax: z.number().int().min(1).max(10000).optional(),
    rateLimitWindowMs: z.number().int().min(1000).max(3600000).optional(),
    supportedLanguages: z.array(z.string().min(2).max(10)).min(1).optional()
  })
};

function validateBody(schema) {
  return (req, _res, next) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      const msg = parsed.error.issues.map((i) => i.message).join('; ');
      return next(new AppError(msg, 400, 'VALIDATION_ERROR'));
    }
    req.body = parsed.data;
    return next();
  };
}

module.exports = { schemas, validateBody };
'@

# 17. backend/src/middleware/errorHandler.js
Write-ProjectFile -RelativePath "backend\src\middleware\errorHandler.js" -Content @'
function errorHandler(err, _req, res, _next) {
  const statusCode = err.statusCode || 500;
  const code = err.code || 'INTERNAL_SERVER_ERROR';
  const message = err.message || 'An unexpected server error occurred.';

  // Never log secrets
  const safeMessage = String(message).replace(/askuni_[^\s'"]+/gi, '***MASKED***');

  res.status(statusCode).json({
    success: false,
    error: {
      code,
      message: safeMessage
    }
  });
}

module.exports = { errorHandler };
'@

# 18. backend/src/controllers/apiControllers.js
Write-ProjectFile -RelativePath "backend\src\controllers\apiControllers.js" -Content @'
const bcrypt = require('bcryptjs');
const { AppError } = require('../adapters/MongoDBRepository');

function createControllers({
  mongoRepo,
  authService,
  queryProcessor,
  adminService,
  infraService
}) {
  return {
    // GET /api/health
    health: (_req, res) => {
      const health = infraService.monitorServerHealth();
      res.status(200).json({
        success: true,
        service: 'AskUni API (Amity University Rajasthan - BCS 522)',
        status: health.status,
        mockMode: health.mockMode,
        uptimeSeconds: health.uptimeSeconds,
        database: health.database,
        timestamp: health.timestamp
      });
    },

    // POST /api/auth/anonymous
    anonymousSession: async (req, res, next) => {
      try {
        const preferredLanguage = req.body.preferredLanguage || 'en';
        const userId = `anon_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25);
        const sessionId = `sess_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
        const { student, widget } = await mongoRepo.ensureStudentAndWidget(
          userId,
          preferredLanguage,
          false,
          'Anonymous Visitor'
        );
        const token = authService.issueToken({
          userId: student.userId,
          role: 'anonymous',
          name: 'Anonymous Visitor',
          preferredLanguage
        });

        res.status(200).json({
          success: true,
          token,
          sessionId,
          user: {
            userId: student.userId,
            widgetId: widget.widgetId,
            role: 'anonymous',
            isAuthenticated: false,
            preferredLanguage
          }
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/auth/login
    login: async (req, res, next) => {
      try {
        const { username, password, role } = req.body;

        if (role === 'system_admin' || String(username).toLowerCase().startsWith('sysadmin')) {
          const sysAdmin = await mongoRepo.findSystemAdminByUsername(username);
          if (!sysAdmin || !bcrypt.compareSync(password, sysAdmin.passwordHash)) {
            throw new AppError('Invalid system administrator credentials.', 401, 'INVALID_CREDENTIALS');
          }
          const token = authService.issueToken({
            userId: sysAdmin.adminId,
            adminId: sysAdmin.adminId,
            staffId: sysAdmin.staffId,
            role: 'system_admin',
            name: sysAdmin.name
          });
          return res.status(200).json({
            success: true,
            token,
            user: {
              adminId: sysAdmin.adminId,
              staffId: sysAdmin.staffId,
              username: sysAdmin.username,
              name: sysAdmin.name,
              role: 'system_admin',
              isAuthenticated: true
            }
          });
        }

        if (role === 'admin_staff' || String(username).toLowerCase().startsWith('admin')) {
          const staff = await mongoRepo.findAdminStaffByUsername(username);
          if (!staff || !bcrypt.compareSync(password, staff.passwordHash)) {
            throw new AppError('Invalid admin staff credentials.', 401, 'INVALID_CREDENTIALS');
          }
          const token = authService.issueToken({
            userId: staff.staffId,
            staffId: staff.staffId,
            role: 'admin_staff',
            name: staff.name
          });
          return res.status(200).json({
            success: true,
            token,
            user: {
              staffId: staff.staffId,
              username: staff.username,
              name: staff.name,
              role: 'admin_staff',
              isAuthenticated: true
            }
          });
        }

        const student = await mongoRepo.findStudentByUsernameOrId(username);
        if (!student || !student.passwordHash || !bcrypt.compareSync(password, student.passwordHash)) {
          throw new AppError('Invalid student credentials.', 401, 'INVALID_CREDENTIALS');
        }

        const { widget } = await mongoRepo.ensureStudentAndWidget(
          student.userId,
          student.preferredLanguage,
          true,
          student.name
        );

        const sessionId = `sess_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
        const token = authService.issueToken({
          userId: student.userId,
          role: 'student',
          name: student.name,
          preferredLanguage: student.preferredLanguage
        });

        return res.status(200).json({
          success: true,
          token,
          sessionId,
          user: {
            userId: student.userId,
            widgetId: widget.widgetId,
            name: student.name,
            email: student.email,
            enrollmentNo: student.enrollmentNo,
            program: student.program,
            semester: student.semester,
            role: 'student',
            isAuthenticated: true,
            preferredLanguage: student.preferredLanguage
          }
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/chat/query
    chatQuery: async (req, res, next) => {
      try {
        const result = await queryProcessor.orchestrateAIResponse(req.body, req.headers.authorization);
        res.status(200).json({
          success: true,
          data: result
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/faqs
    getPublicFaqs: async (req, res, next) => {
      try {
        const category = req.query.category || '';
        const q = req.query.q || '';
        const faqs = await mongoRepo.fetchSmartFAQs(q, category);
        res.status(200).json({
          success: true,
          count: faqs.length,
          faqs
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/admin/faqs
    createFaq: async (req, res, next) => {
      try {
        const created = await adminService.updateSmartFAQs('create', req.body);
        res.status(201).json({
          success: true,
          faq: created
        });
      } catch (err) {
        next(err);
      }
    },

    // PUT /api/admin/faqs/:faqId
    updateFaq: async (req, res, next) => {
      try {
        const updated = await adminService.updateSmartFAQs('update', {
          faqId: req.params.faqId,
          ...req.body
        });
        res.status(200).json({
          success: true,
          faq: updated
        });
      } catch (err) {
        next(err);
      }
    },

    // DELETE /api/admin/faqs/:faqId
    deleteFaq: async (req, res, next) => {
      try {
        const deleted = await adminService.updateSmartFAQs('delete', {
          faqId: req.params.faqId
        });
        res.status(200).json({
          success: true,
          deleted
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/admin/logs
    getAdminLogs: async (req, res, next) => {
      try {
        const { date, language, keyword } = req.query;
        const result = await adminService.reviewChatLogs({ date, language, keyword });
        res.status(200).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/admin/logs/:sessionId
    getAdminSessionDetail: async (req, res, next) => {
      try {
        const detail = await adminService.getSessionDetail(req.params.sessionId);
        res.status(200).json({
          success: true,
          ...detail
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/admin/trending
    getAdminTrending: async (_req, res, next) => {
      try {
        const trending = await adminService.getTrendingQuestions();
        res.status(200).json({
          success: true,
          trending
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/admin/knowledge/upload
    uploadKnowledge: async (req, res, next) => {
      try {
        const result = await adminService.uploadKnowledgeDocument(req.body);
        res.status(201).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/sysadmin/health
    getSysAdminHealth: (_req, res) => {
      const health = infraService.monitorServerHealth();
      res.status(200).json({
        success: true,
        health
      });
    },

    // GET /api/sysadmin/services
    getSysAdminServices: async (_req, res, next) => {
      try {
        const services = await infraService.getServiceConfigurations();
        res.status(200).json({
          success: true,
          services,
          security: authService.getMaskedMetadata()
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/sysadmin/credentials/renew
    renewCredentials: async (_req, res, next) => {
      try {
        const result = await infraService.renewCredentials();
        res.status(200).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    },

    // PUT /api/sysadmin/config
    updateSysConfig: async (req, res, next) => {
      try {
        const result = await infraService.manageRateLimitsAndConfig(req.body);
        res.status(200).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    }
  };
}

module.exports = { createControllers };
'@

# 19. backend/src/routes/apiRoutes.js
Write-ProjectFile -RelativePath "backend\src\routes\apiRoutes.js" -Content @'
const express = require('express');
const { schemas, validateBody } = require('../middleware/validateMiddleware');

function createApiRouter(controllers, authMiddleware) {
  const router = express.Router();
  const { requireRoles } = authMiddleware;

  // Health
  router.get('/health', controllers.health);

  // Auth
  router.post('/auth/anonymous', validateBody(schemas.anonymousAuth), controllers.anonymousSession);
  router.post('/auth/login', validateBody(schemas.loginAuth), controllers.login);

  // Public FAQ & Chat RAG
  router.get('/faqs', controllers.getPublicFaqs);
  router.post('/chat/query', validateBody(schemas.chatQuery), controllers.chatQuery);

  // Admin Staff Routes (/api/admin/*)
  router.get('/admin/logs', requireRoles('admin_staff', 'system_admin'), controllers.getAdminLogs);
  router.get('/admin/logs/:sessionId', requireRoles('admin_staff', 'system_admin'), controllers.getAdminSessionDetail);
  router.get('/admin/trending', requireRoles('admin_staff', 'system_admin'), controllers.getAdminTrending);
  router.post('/admin/faqs', requireRoles('admin_staff', 'system_admin'), validateBody(schemas.createFaq), controllers.createFaq);
  router.put('/admin/faqs/:faqId', requireRoles('admin_staff', 'system_admin'), validateBody(schemas.updateFaq), controllers.updateFaq);
  router.delete('/admin/faqs/:faqId', requireRoles('admin_staff', 'system_admin'), controllers.deleteFaq);
  router.post('/admin/knowledge/upload', requireRoles('admin_staff', 'system_admin'), validateBody(schemas.uploadKnowledge), controllers.uploadKnowledge);

  // System Administrator Routes (/api/sysadmin/*)
  router.get('/sysadmin/health', requireRoles('system_admin'), controllers.getSysAdminHealth);
  router.get('/sysadmin/services', requireRoles('system_admin'), controllers.getSysAdminServices);
  router.post('/sysadmin/credentials/renew', requireRoles('system_admin'), controllers.renewCredentials);
  router.put('/sysadmin/config', requireRoles('system_admin'), validateBody(schemas.updateSysConfig), controllers.updateSysConfig);

  return router;
}

module.exports = { createApiRouter };
'@

# 20. backend/src/app.js
Write-ProjectFile -RelativePath "backend\src\app.js" -Content @'
const path = require('path');
const fs = require('fs');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const config = require('./config/env');
const { MongoDBRepository } = require('./adapters/MongoDBRepository');
const { PineconeVectorAdapter } = require('./adapters/PineconeVectorAdapter');
const { AIServiceAdapter } = require('./adapters/AIServiceAdapter');
const { TranslationServiceAdapter } = require('./adapters/TranslationServiceAdapter');
const { JWTAuthService } = require('./services/JWTAuthService');
const { BackendQueryProcessor } = require('./services/BackendQueryProcessor');
const { AdminStaffService } = require('./services/AdminStaffService');
const { InfrastructureAdminService } = require('./services/InfrastructureAdminService');
const { createAuthMiddleware } = require('./middleware/authMiddleware');
const { createControllers } = require('./controllers/apiControllers');
const { createApiRouter } = require('./routes/apiRoutes');
const { errorHandler } = require('./middleware/errorHandler');

function createApp(customDeps = {}) {
  const app = express();

  const mongoRepo = customDeps.mongoRepo || new MongoDBRepository();
  const pineconeAdapter = customDeps.pineconeAdapter || new PineconeVectorAdapter();
  const aiAdapter = customDeps.aiAdapter || new AIServiceAdapter();
  const translationAdapter = customDeps.translationAdapter || new TranslationServiceAdapter();
  const authService = customDeps.authService || new JWTAuthService();

  const queryProcessor = new BackendQueryProcessor({
    mongoRepo,
    pineconeAdapter,
    aiAdapter,
    translationAdapter,
    authService
  });

  const adminService = new AdminStaffService({ mongoRepo, pineconeAdapter });
  const infraService = new InfrastructureAdminService({
    mongoRepo,
    pineconeAdapter,
    aiAdapter,
    translationAdapter,
    authService
  });

  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(
    cors({
      origin: (origin, callback) => {
        if (!origin || config.corsOrigins.includes(origin) || origin.startsWith('http://localhost:')) {
          callback(null, true);
        } else {
          callback(null, true); // Allow embed widget on partner campus portals
        }
      },
      credentials: true
    })
  );
  app.use(express.json({ limit: '1mb' }));

  // Dynamic rate limiter backed by InfrastructureAdminService settings
  const limiter = rateLimit({
    windowMs: config.rateLimitWindowMs,
    limit: () => infraService.rateLimitState.maxRequests,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      infraService.recordRequest(true);
      const retrySec = Math.ceil(infraService.rateLimitState.windowMs / 1000);
      res.status(429).json({
        success: false,
        error: {
          code: 'RATE_LIMIT_EXCEEDED',
          message: `Too many requests. Please retry after ${retrySec} seconds.`,
          retryAfterSeconds: retrySec
        }
      });
    }
  });

  app.use('/api', (req, _res, next) => {
    infraService.recordRequest(false);
    next();
  }, limiter);

  const authMiddleware = createAuthMiddleware(authService);
  const controllers = createControllers({
    mongoRepo,
    authService,
    queryProcessor,
    adminService,
    infraService
  });

  app.use('/api', createApiRouter(controllers, authMiddleware));

  // Single <script> tag embeddable widget loader endpoint
  app.get('/widget/askuni-widget.js', (req, res) => {
    res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
    const builtEmbed = path.resolve(__dirname, '../../frontend/dist/askuni-widget.iife.js');
    if (fs.existsSync(builtEmbed)) {
      return res.sendFile(builtEmbed);
    }
    const apiBase = `${req.protocol}://${req.get('host')}/api`;
    const fallbackLoader = `(function(){
  if (window.__ASKUNI_LOADED__) return;
  window.__ASKUNI_LOADED__ = true;
  var API_BASE = window.ASKUNI_API_BASE || '${apiBase}';
  var host = document.createElement('div');
  host.id = 'askuni-embed-root';
  document.body.appendChild(host);
  var btn = document.createElement('button');
  btn.textContent = 'AskUni Chat (AUR)';
  btn.setAttribute('aria-label', 'Open AskUni Assistant');
  btn.style.cssText = 'position:fixed;bottom:20px;right:20px;z-index:99999;background:#003366;color:#fff;border:none;border-radius:999px;padding:12px 20px;font-family:sans-serif;font-weight:600;cursor:pointer;box-shadow:0 8px 24px rgba(0,0,0,0.2);';
  var box = document.createElement('div');
  box.style.cssText = 'display:none;position:fixed;bottom:76px;right:20px;width:360px;max-width:92vw;height:460px;background:#fff;border:1px solid #cbd5e1;border-radius:16px;z-index:99999;flex-direction:column;overflow:hidden;font-family:sans-serif;box-shadow:0 16px 40px rgba(0,0,0,0.22);';
  box.innerHTML = '<div style="background:#003366;color:#fff;padding:12px 16px;display:flex;justify-content:space-between;align-items:center;"><strong>AskUni — Amity Rajasthan</strong><button id="au-close" style="background:none;border:none;color:#fff;font-size:18px;cursor:pointer;">&times;</button></div><div id="au-msgs" style="flex:1;padding:12px;overflow-y:auto;font-size:13px;background:#f8fafc;"><div style="background:#e2e8f0;padding:8px 12px;border-radius:10px;margin-bottom:8px;">Namaste! Ask me about AUR exams, fees, timetables, hostel, or scholarships.</div></div><form id="au-form" style="display:flex;border-top:1px solid #e2e8f0;padding:8px;gap:6px;"><input id="au-in" placeholder="Type your question..." style="flex:1;padding:8px;border:1px solid #cbd5e1;border-radius:8px;"/><button type="submit" style="background:#f59e0b;color:#0f172a;border:none;border-radius:8px;padding:8px 14px;font-weight:700;cursor:pointer;">Send</button></form>';
  host.appendChild(btn);
  host.appendChild(box);
  btn.onclick = function(){ box.style.display = box.style.display === 'none' ? 'flex' : 'none'; };
  box.querySelector('#au-close').onclick = function(){ box.style.display = 'none'; };
  box.querySelector('#au-form').onsubmit = function(e){
    e.preventDefault();
    var inp = box.querySelector('#au-in');
    var q = inp.value.trim();
    if (!q) return;
    var msgs = box.querySelector('#au-msgs');
    msgs.innerHTML += '<div style="text-align:right;margin-bottom:8px;"><span style="display:inline-block;background:#003366;color:#fff;padding:8px 12px;border-radius:10px;">' + q + '</span></div>';
    inp.value = '';
    fetch(API_BASE + '/chat/query', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ queryText: q, language: 'auto' })
    }).then(function(r){ return r.json(); }).then(function(d){
      var ans = (d && d.data && d.data.translatedText) || 'Unable to fetch answer.';
      msgs.innerHTML += '<div style="margin-bottom:8px;"><span style="display:inline-block;background:#e2e8f0;color:#0f172a;padding:8px 12px;border-radius:10px;">' + ans + '</span></div>';
      msgs.scrollTop = msgs.scrollHeight;
    });
  };
})();`;
    return res.send(fallbackLoader);
  });

  app.use(errorHandler);

  app.locals.services = {
    mongoRepo,
    pineconeAdapter,
    aiAdapter,
    translationAdapter,
    authService,
    queryProcessor,
    adminService,
    infraService
  };

  return app;
}

module.exports = { createApp };
'@

# 21. backend/src/index.js
Write-ProjectFile -RelativePath "backend\src\index.js" -Content @'
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
'@

# 22. backend/src/seed/seedData.js
Write-ProjectFile -RelativePath "backend\src\seed\seedData.js" -Content @'
const fs = require('fs');
const bcrypt = require('bcryptjs');
const { dbManager, EMPTY_STORE } = require('../config/db');
const { MongoDBRepository } = require('../adapters/MongoDBRepository');
const { PineconeVectorAdapter, KB_FILE } = require('../adapters/PineconeVectorAdapter');
const { Models } = require('../models/schemas');

const SEED_FAQS = [
  {
    faqId: 'faq_exam_01',
    category: 'Examinations',
    question: 'When do Odd Semester End-Term Examinations begin at Amity University Rajasthan?',
    answerText: 'Odd Semester End-Term Theory Examinations for B.Tech CSE begin on December 4, 2026, following Practical & Lab Viva-Voce assessments (including BCS 522 Software Engineering Lab) from November 23 to November 30, 2026.'
  },
  {
    faqId: 'faq_exam_02',
    category: 'Examinations',
    question: 'What is the minimum attendance required to appear in End-Semester Exams?',
    answerText: 'Students must maintain a minimum of 75% attendance in each course (Theory and Lab separately) to be eligible for End-Semester Examinations. Medical condonation up to 5% requires Chief Proctor and Dean approval.'
  },
  {
    faqId: 'faq_exam_03',
    category: 'Examinations',
    question: 'How can I download my Admit Card for semester examinations?',
    answerText: 'Admit Cards are released on the Amizone Student Portal 7 days prior to the first exam after clearance of semester fees and no-dues verification.'
  },
  {
    faqId: 'faq_fee_01',
    category: 'Fees & Finance',
    question: 'What is the annual tuition fee for B.Tech Computer Science & Engineering (CSE)?',
    answerText: 'The non-sponsored academic tuition fee for B.Tech CSE at Amity University Rajasthan (Jaipur) is INR 1,86,000 per semester (INR 3,72,000 per academic year), payable via Amizone online portal or Demand Draft.'
  },
  {
    faqId: 'faq_fee_02',
    category: 'Fees & Finance',
    question: 'What is the deadline and late fee policy for semester fee payment?',
    answerText: 'Semester fees must be deposited within 15 days of semester commencement. A late fee of INR 500 per week applies thereafter up to 4 weeks.'
  },
  {
    faqId: 'faq_hostel_01',
    category: 'Hostel & Campus',
    question: 'What are the hostel fees and room options at Amity University Rajasthan?',
    answerText: 'On-campus AC Triple-Sharing Hostel fee is INR 1,10,000 per year and Non-AC Triple-Sharing is INR 75,000 per year (excluding mess charges of INR 48,000/year). Wi-Fi, 24x7 security, and infirmary are included.'
  },
  {
    faqId: 'faq_hostel_02',
    category: 'Hostel & Campus',
    question: 'What are the campus transport bus routes from Jaipur city?',
    answerText: 'University AC buses operate daily from Vaishali Nagar, Mansarovar, Raja Park, Malviya Nagar, and Vidhyadhar Nagar to the Kant Kalwar (NH-11C) campus. Annual transport fee is INR 34,000.'
  },
  {
    faqId: 'faq_adm_01',
    category: 'Admissions',
    question: 'What is the eligibility criteria for admission to B.Tech CSE?',
    answerText: 'Candidates require a minimum of 60% aggregate in Class XII with Physics, Mathematics, and Chemistry/Computer Science, along with a valid JEE Main / Amity JEE score and personal interview.'
  },
  {
    faqId: 'faq_adm_02',
    category: 'Admissions',
    question: 'How do I apply for admissions at Amity University Rajasthan?',
    answerText: 'Applications are submitted online at amity.edu/jaipur with an application fee of INR 1,500, followed by online document upload and Selection Process interview slot booking.'
  },
  {
    faqId: 'faq_schol_01',
    category: 'Scholarships',
    question: 'What merit scholarships are offered to B.Tech students?',
    answerText: 'Amity offers 100% tuition scholarship for 93%+ aggregate in Class XII (CBSE/ISC), 50% scholarship for 88%-92.99%, and 25% scholarship for 80%-87.99% or JEE Main 90+ percentile.'
  },
  {
    faqId: 'faq_schol_02',
    category: 'Scholarships',
    question: 'How is merit scholarship renewed in subsequent years?',
    answerText: 'Continuation of 100% scholarship requires ranking in the top 5% of the merit list (minimum 8.5 CGPA), and 50% scholarship requires top 10% (minimum 8.0 CGPA) without any backlogs.'
  },
  {
    faqId: 'faq_tt_01',
    category: 'Timetable & Labs',
    question: 'What are the regular class timings and Software Engineering Lab (BCS 522) schedule?',
    answerText: 'Regular academic classes run Monday to Friday from 9:15 AM to 5:05 PM (each lecture 55 minutes). B.Tech CSE 5th Semester Software Engineering Lab (BCS 522) is held in ASET Block-B Lab-204 on Tuesdays and Thursdays.'
  },
  {
    faqId: 'faq_tt_02',
    category: 'Timetable & Labs',
    question: 'Where can I view my updated section-wise weekly timetable?',
    answerText: 'Section-wise weekly timetables, faculty room allocations, and elective slots are published under the "My Timetable" tab on Amizone and on the ASET Department Notice Board.'
  },
  {
    faqId: 'faq_lib_01',
    category: 'Library & IT',
    question: 'What are the Central Library operating hours and digital journal access rules?',
    answerText: 'The AUR Central Library is open from 8:30 AM to 9:00 PM on weekdays and 9:00 AM to 5:00 PM on Saturdays. IEEE Xplore, ACM Digital Library, and SpringerLink are accessible on campus Wi-Fi and via remote VPN.'
  },
  {
    faqId: 'faq_lib_02',
    category: 'Library & IT',
    question: 'How do students reset their Amizone or campus Wi-Fi password?',
    answerText: 'Use the "Forgot Password" OTP link on amizone.net using your registered mobile number, or visit the IT Helpdesk on the Ground Floor of Block-A with your university ID card.'
  },
  {
    faqId: 'faq_place_01',
    category: 'Placements',
    question: 'When do campus placement drives start for B.Tech CSE students?',
    answerText: 'Pre-placement training by Amity Technical Placement Centre (ATPC) starts in Semester 6, and core campus recruitment drives commence from July of Semester 7.'
  },
  {
    faqId: 'faq_place_02',
    category: 'Placements',
    question: 'What is the minimum CGPA required to sit for ATPC placement drives?',
    answerText: 'Students with a cumulative CGPA of 6.5 and above with zero active backlogs are eligible for Tier-1 and core IT placement drives coordinated by ATPC.'
  },
  {
    faqId: 'faq_doc_01',
    category: 'Student Services',
    question: 'How do I apply for a Bonafide Certificate or Official Transcript?',
    answerText: 'Submit an online request under "Student Services -> Certificates" on Amizone. Bonafide certificates are issued within 2 working days and official transcripts within 5 working days.'
  },
  {
    faqId: 'faq_anti_01',
    category: 'Campus Policies',
    question: 'Who do I contact for anti-ragging or campus grievance redressal?',
    answerText: 'Amity University Rajasthan enforces a zero-tolerance anti-ragging policy. Students can reach the 24x7 Anti-Ragging Helpline at 1800-180-5522 or email proctor@jpr.amity.edu.'
  },
  {
    faqId: 'faq_event_01',
    category: 'Events & Clubs',
    question: 'When is Odyssey, the annual techno-cultural fest of Amity University Rajasthan?',
    answerText: 'Odyssey, the flagship annual techno-cultural fest of AUR, is scheduled for February 18-20, 2027, featuring hackathons, robotics challenges, and cultural nights.'
  }
];

const SEED_DOCUMENTS = [
  {
    docId: 'doc_cir_exams_2026',
    title: 'Circular AUR/COE/2026/114 - Odd Semester Examination Guidelines',
    category: 'Circular',
    content: 'Controller of Examinations Notice: Practical exams including BCS 522 Software Engineering Lab will be conducted from Nov 23 to Nov 30, 2026. Theory exams start Dec 4, 2026 in Morning (9:30 AM - 12:30 PM) and Afternoon (2:00 PM - 5:00 PM) shifts. Scientific calculators are permitted only where specified on the question paper.'
  },
  {
    docId: 'doc_fee_struct_2026',
    title: 'AUR Fee Structure Notification 2026-27 (ASET B.Tech Programs)',
    category: 'Fee Structure',
    content: 'Amity School of Engineering & Technology (ASET) Jaipur Fee Schedule: B.Tech CSE semester fee is INR 1,86,000. One-time refundable academic security deposit is INR 20,000 at admission. International students fee is USD 3,100 per semester.'
  },
  {
    docId: 'doc_bcs522_syllabus',
    title: 'BCS 522 Software Engineering Lab Manual & Evaluation Rubric',
    category: 'Timetable & Labs',
    content: 'Course BCS 522 Software Engineering Lab (Credits: 2) covers SRS documentation (IEEE 830), UML Class/Sequence/Use-Case modeling, layered architecture implementation, automated unit/integration testing, and traceability matrix verification. Continuous evaluation carries 60 marks and End-Term Lab Viva carries 40 marks.'
  },
  {
    docId: 'doc_hostel_rules_26',
    title: 'Residential Hostel & Mess Rules Handbook 2026',
    category: 'Hostel & Campus',
    content: 'All hostellers must mark biometric attendance by 9:30 PM daily. Out-pass requests for weekend home visits require parent SMS confirmation through the Amizone Hostel Portal at least 24 hours in advance.'
  },
  {
    docId: 'doc_schol_policy_26',
    title: 'Amity Merit & Sports Scholarship Policy 2026-27',
    category: 'Scholarships',
    content: 'Fast-track direct admission without entrance test is granted to students securing 80%+ in Class XII CBSE/ISC. Merit scholarships (100%, 50%, 25%) are awarded automatically on first-year tuition fees upon document verification.'
  }
];

async function runSeed({ forceReset = true } = {}) {
  if (!dbManager.connected) {
    await dbManager.connect();
  }

  if (forceReset) {
    dbManager.store = JSON.parse(JSON.stringify(EMPTY_STORE));
  }

  const repo = new MongoDBRepository();
  const dbUri = repo.dbUri;
  const now = new Date().toISOString();

  // 1. Seed Admin Staff & System Administrator
  const adminHash = bcrypt.hashSync('Admin@123', 10);
  const sysAdminHash = bcrypt.hashSync('SysAdmin@123', 10);
  const studentHash = bcrypt.hashSync('Student@123', 10);

  await repo.insertRecord('adminStaff', 'staffId', Models.AdminStaff, {
    staffId: 'staff_aur_01',
    dbUri,
    indexName: 'askuni-aur-index',
    role: 'admin_staff',
    username: 'admin_aur',
    name: 'Dr. Kavita Sharma (ASET Coordinator)',
    passwordHash: adminHash
  });

  await repo.insertRecord(
    'systemAdmins',
    'adminId',
    Models.SystemAdministrator,
    {
      adminId: 'sysadmin_aur_01',
      staffId: 'staff_aur_01',
      apiEndpoint: '/api/sysadmin',
      role: 'system_admin',
      username: 'sysadmin_aur',
      name: 'Rajesh Rathore (IT Infrastructure Lead)',
      passwordHash: sysAdminHash
    },
    [{ field: 'staffId', targetCollection: 'adminStaff', targetField: 'staffId' }]
  );

  // 2. Seed Demo Students
  await repo.insertRecord('students', 'userId', Models.Student, {
    userId: 'stu_a50105224001',
    preferredLanguage: 'en',
    isAuthenticated: true,
    name: 'Aarav Verma',
    email: 'aarav.verma@s.amity.edu',
    enrollmentNo: 'A50105224001',
    program: 'B.Tech CSE (Sem 5 - BCS 522)',
    semester: 5,
    role: 'student',
    passwordHash: studentHash
  });

  await repo.insertRecord('students', 'userId', Models.Student, {
    userId: 'stu_a50105224002',
    preferredLanguage: 'hi',
    isAuthenticated: true,
    name: 'Priya Meena',
    email: 'priya.meena@s.amity.edu',
    enrollmentNo: 'A50105224002',
    program: 'B.Tech CSE (Sem 5 - BCS 522)',
    semester: 5,
    role: 'student',
    passwordHash: studentHash
  });

  await repo.ensureStudentAndWidget('stu_a50105224001', 'en', true, 'Aarav Verma');
  await repo.ensureStudentAndWidget('stu_a50105224002', 'hi', true, 'Priya Meena');

  // 3. Seed ~20 Smart FAQs
  for (const faq of SEED_FAQS) {
    await repo.insertRecord('smartFaqs', 'faqId', Models.SmartFAQ, {
      faqId: faq.faqId,
      dbUri,
      question: faq.question,
      answerText: faq.answerText,
      category: faq.category,
      lastUpdated: now
    });
  }

  // 4. Seed Service Configurations
  const serviceConfigs = [
    {
      configId: 'JWT_AUTH_SERVICE',
      serviceName: 'JWT_AUTH_SERVICE',
      supportedLanguages: ['en', 'hi', 'mr', 'ta', 'bn', 'pa'],
      rateLimitMax: 120,
      rateLimitWindowMs: 60000,
      apiEndpoint: '/api/auth',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'MONGODB_REPOSITORY',
      serviceName: 'MONGODB_REPOSITORY',
      dbUri,
      apiEndpoint: 'internal://mongodb-repository',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'PINECONE_VECTOR_DB',
      serviceName: 'PINECONE_VECTOR_DB',
      indexName: 'askuni-aur-index',
      apiEndpoint: 'https://api.pinecone.io',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'PINECONE_VECTOR_ADAPTER',
      serviceName: 'PINECONE_VECTOR_ADAPTER',
      indexName: 'askuni-aur-index',
      apiEndpoint: 'internal://pinecone-vector-adapter',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    },
    {
      configId: 'AI_TRANSLATION_SERVICE',
      serviceName: 'AI_TRANSLATION_SERVICE',
      supportedLanguages: ['en', 'hi', 'mr', 'ta', 'bn', 'pa'],
      apiEndpoint: 'https://translation.googleapis.com/language/translate/v2',
      maskedSecretHint: '***MASKED***',
      updatedAt: now
    }
  ];

  for (const cfg of serviceConfigs) {
    await repo.insertRecord('serviceConfigs', 'configId', Models.ServiceConfig, cfg);
  }

  // 5. Seed Initial Sample Session Logs for Admin Dashboard
  const sampleLogs = [
    {
      logId: 'lg_seed_01',
      dbUri,
      sessionId: 'sess_demo_aur_01',
      userId: 'stu_a50105224001',
      queryText: 'When do Odd Semester End-Term Examinations begin at Amity University Rajasthan?',
      responseText: 'Based on official Amity University Rajasthan records: Odd Semester End-Term Theory Examinations for B.Tech CSE begin on December 4, 2026, following Practical & Lab Viva-Voce assessments (including BCS 522 Software Engineering Lab) from November 23 to November 30, 2026.',
      language: 'en',
      timestamp: new Date(Date.now() - 3600000).toISOString()
    },
    {
      logId: 'lg_seed_02',
      dbUri,
      sessionId: 'sess_demo_aur_02',
      userId: 'stu_a50105224002',
      queryText: 'बी.टेक सीएसई की फीस कितनी है?',
      responseText: '[हिन्दी अनुवाद] एमिटी विश्वविद्यालय राजस्थान के आधिकारिक रिकॉर्ड के अनुसार: The non-sponsored academic tuition fee for B.Tech CSE at Amity University Rajasthan (Jaipur) is INR 1,86,000 per semester (INR 3,72,000 per academic year).',
      language: 'hi',
      timestamp: new Date(Date.now() - 1800000).toISOString()
    }
  ];

  for (const lg of sampleLogs) {
    await repo.saveChatLog(lg);
  }

  // 6. Seed Pinecone Mock Vector Knowledge Base Documents
  const pinecone = new PineconeVectorAdapter();
  pinecone.documents = SEED_DOCUMENTS.map((d) => ({
    ...d,
    updatedAt: now
  }));
  pinecone.saveDocuments();

  dbManager.saveToDisk();
  return {
    faqsCount: dbManager.store.smartFaqs.length,
    docsCount: pinecone.documents.length,
    studentsCount: dbManager.store.students.length
  };
}

async function seedDatabaseIfEmpty() {
  if (!dbManager.connected) {
    await dbManager.connect();
  }
  if (dbManager.store.smartFaqs.length === 0) {
    return runSeed({ forceReset: true });
  }
  return {
    faqsCount: dbManager.store.smartFaqs.length,
    docsCount: fs.existsSync(KB_FILE) ? JSON.parse(fs.readFileSync(KB_FILE, 'utf8')).length : 0,
    studentsCount: dbManager.store.students.length
  };
}

if (require.main === module) {
  runSeed({ forceReset: true })
    .then((summary) => {
      console.log('[AskUni Seed] Completed successfully:', JSON.stringify(summary));
      process.exit(0);
    })
    .catch((err) => {
      console.error('[AskUni Seed] Failed:', err);
      process.exit(1);
    });
}

module.exports = { runSeed, seedDatabaseIfEmpty, SEED_FAQS, SEED_DOCUMENTS };
'@

# 23. backend/src/tests/backend.test.js (41 automated test cases: TC-13 through TC-53)
Write-ProjectFile -RelativePath "backend\src\tests\backend.test.js" -Content @'
const request = require('supertest');
const jwt = require('jsonwebtoken');
const { createApp } = require('../app');
const { runSeed } = require('../seed/seedData');
const { dbManager } = require('../config/db');
const { Models } = require('../models/schemas');

let app;
let studentToken;
let adminToken;
let sysAdminToken;

beforeAll(async () => {
  await runSeed({ forceReset: true });
  app = createApp();

  const stuLogin = await request(app)
    .post('/api/auth/login')
    .send({ username: 'A50105224001', password: 'Student@123', role: 'student' });
  studentToken = stuLogin.body.token;

  const admLogin = await request(app)
    .post('/api/auth/login')
    .send({ username: 'admin_aur', password: 'Admin@123', role: 'admin_staff' });
  adminToken = admLogin.body.token;

  const sysLogin = await request(app)
    .post('/api/auth/login')
    .send({ username: 'sysadmin_aur', password: 'SysAdmin@123', role: 'system_admin' });
  sysAdminToken = sysLogin.body.token;
});

afterEach(() => {
  // Reset any simulated outages between tests
  dbManager.simulateFailure = false;
  app.locals.services.pineconeAdapter.simulateFailure = false;
  app.locals.services.aiAdapter.simulateFailure = false;
  app.locals.services.translationAdapter.simulateFailure = false;
});

describe('Module 2: Backend RAG Pipeline & Data Integrity (TC-13 to TC-32)', () => {
  test('TC-13 receives valid UserQuery payload and returns 200 with structured ChatbotResponse', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.responseId).toBeDefined();
    expect(res.body.data.translatedText).toContain('1,86,000');
  });

  test('TC-14 processes authenticated student query with student context and isAuthenticated=true', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ queryText: 'When do Odd Semester End-Term Examinations begin?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.isAuthenticated).toBe(true);
    expect(res.body.data.userId).toBe('stu_a50105224001');
    expect(res.body.data.translatedText).toContain('Aarav Verma');
  });

  test('TC-15 processes anonymous visitor query without Bearer token and assigns anonymous session', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the hostel fee at Amity University Rajasthan?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.isAuthenticated).toBe(false);
    expect(res.body.data.role).toBe('anonymous');
    expect(res.body.data.sessionId).toMatch(/^sess_/);
  });

  test('TC-16 rejects invalid or malformed JWT token with 401 Unauthorized', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .set('Authorization', 'Bearer invalid.jwt.token.here')
      .send({ queryText: 'Exam dates?', language: 'en' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  test('TC-17 rejects expired JWT token with 401 Unauthorized', async () => {
    const expiredToken = jwt.sign(
      { userId: 'stu_a50105224001', role: 'student' },
      app.locals.services.authService.activeSecret,
      { expiresIn: -10 }
    );

    const res = await request(app)
      .post('/api/chat/query')
      .set('Authorization', `Bearer ${expiredToken}`)
      .send({ queryText: 'Exam dates?', language: 'en' });

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('TOKEN_EXPIRED');
  });

  test('TC-18 retrieves relevant FAQ records from MongoDB repository', async () => {
    const faqs = await app.locals.services.mongoRepo.fetchSmartFAQs('merit scholarship');
    expect(Array.isArray(faqs)).toBe(true);
    expect(faqs.length).toBeGreaterThan(0);
    expect(faqs[0].category).toBe('Scholarships');
  });

  test('TC-19 retrieves relevant institutional document chunks from Pinecone vector adapter', async () => {
    const docs = await app.locals.services.pineconeAdapter.searchVectorContext('BCS 522 Software Engineering Lab', 3);
    expect(Array.isArray(docs)).toBe(true);
    expect(docs.length).toBeGreaterThan(0);
    expect(docs[0].title).toContain('BCS 522');
  });

  test('TC-20 retrieves and merges context from both MongoDB and Pinecone in parallel', async () => {
    const { mergedContext, flags } = await app.locals.services.queryProcessor.retrieveAndMergeContext(
      'Odd Semester Examination Guidelines BCS 522'
    );
    const sources = new Set(mergedContext.map((m) => m.source));
    expect(sources.has('SmartFAQ')).toBe(true);
    expect(sources.has('PineconeVectorDB')).toBe(true);
    expect(flags.mongoFailed).toBe(false);
    expect(flags.pineconeFailed).toBe(false);
  });

  test('TC-21 handles missing context gracefully without hallucinating and suggests contacting college office', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'Quantum teleportation mars colony cafeteria menu 2099', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.grounded).toBe(false);
    expect(res.body.data.translatedText).toMatch(/Administrative \/ Academic Office|\+91-1426-405555/i);
  });

  test('TC-22 merges Smart FAQ context and vector document context cleanly without duplication', async () => {
    const { mergedContext } = await app.locals.services.queryProcessor.retrieveAndMergeContext('hostel fee rules');
    const titles = mergedContext.map((c) => c.title.toLowerCase());
    const uniqueTitles = new Set(titles);
    expect(titles.length).toBe(uniqueTitles.size);
  });

  test('TC-23 generates grounded AI response referencing retrieved institutional facts', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the minimum attendance required for exams?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.grounded).toBe(true);
    expect(res.body.data.generatedText).toContain('75%');
  });

  test('TC-24 translates response accurately into requested supported language (Hindi)', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'hi' });

    expect(res.status).toBe(200);
    expect(res.body.data.targetLanguage).toBe('hi');
    expect(res.body.data.translatedText).toContain('हिन्दी');
    expect(res.body.data.flags.translationFailed).toBe(false);
  });

  test('TC-25 falls back to English with clear notice when unsupported language is requested', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'fr' });

    expect(res.status).toBe(200);
    expect(res.body.data.targetLanguage).toBe('en');
    expect(res.body.data.flags.unsupportedLanguage).toBe(true);
    expect(res.body.data.translatedText).toContain('not currently supported');
  });

  test('TC-26 handles AI service failure gracefully with safe error response and status flag', async () => {
    app.locals.services.aiAdapter.simulateFailure = true;

    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'When are exams?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.flags.aiFailed).toBe(true);
    expect(res.body.data.translatedText).toContain('temporary issue');
  });

  test('TC-27 handles translation service failure by returning original English text and flagging translationFailed', async () => {
    app.locals.services.translationAdapter.simulateFailure = true;

    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'hi' });

    expect(res.status).toBe(200);
    expect(res.body.data.flags.translationFailed).toBe(true);
    expect(res.body.data.targetLanguage).toBe('en');
    expect(res.body.data.translatedText).toContain('1,86,000');
  });

  test('TC-28 returns formatted ChatbotResponse linked to processorId and persists SessionLog', async () => {
    const sessionId = 'sess_tc28_verify';
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'Library operating hours?', sessionId, language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.processorId).toMatch(/^pr_/);
    expect(res.body.data.responseId).toMatch(/^rs_/);

    const savedLog = dbManager.store.sessionLogs.find((l) => l.sessionId === sessionId);
    expect(savedLog).toBeDefined();
    expect(savedLog.queryText).toBe('Library operating hours?');
  });

  test('TC-29 accepts custom primary key IDs of exactly 25 characters', async () => {
    const exact25Id = 'faq_exact_twentyfive_1234'; // 25 chars
    expect(exact25Id.length).toBe(25);

    const created = await app.locals.services.mongoRepo.createFAQEntry({
      faqId: exact25Id,
      question: 'Exact 25 char ID test question?',
      answerText: 'Exact 25 char ID test answer.',
      category: 'Testing'
    });

    expect(created.faqId).toBe(exact25Id);
  });

  test('TC-30 rejects custom primary key IDs of 26 or more characters', async () => {
    const id26 = 'faq_twentysix_characters_1'; // 26 chars
    expect(id26.length).toBe(26);

    await expect(
      app.locals.services.mongoRepo.createFAQEntry({
        faqId: id26,
        question: 'Too long ID question?',
        answerText: 'Too long ID answer.',
        category: 'Testing'
      })
    ).rejects.toThrow(/25 characters/);
  });

  test('TC-31 rejects duplicate primary key insertion with conflict error', async () => {
    await expect(
      app.locals.services.mongoRepo.createFAQEntry({
        faqId: 'faq_exam_01',
        question: 'Duplicate PK question?',
        answerText: 'Duplicate PK answer.',
        category: 'Testing'
      })
    ).rejects.toThrow(/Duplicate primary key/);
  });

  test('TC-32 enforces foreign-key integrity and links UserQuery -> BackendQueryProcessor -> ChatbotResponse', async () => {
    await expect(
      app.locals.services.mongoRepo.insertRecord(
        'processors',
        'processorId',
        Models.BackendQueryProcessor,
        {
          processorId: 'pr_orphan_fk_01',
          queryId: 'non_existent_query_id',
          activeSessionId: 'sess_fk',
          dbUri: 'mock://db',
          indexName: 'askuni-aur-index',
          apiEndpoint: '/api/chat/query'
        },
        [{ field: 'queryId', targetCollection: 'userQueries', targetField: 'queryId' }]
      )
    ).rejects.toThrow(/Foreign key constraint failed/);

    const latestResp = dbManager.store.responses[dbManager.store.responses.length - 1];
    const linkedProc = dbManager.store.processors.find((p) => p.processorId === latestResp.processorId);
    const linkedQuery = dbManager.store.userQueries.find((q) => q.queryId === linkedProc.queryId);
    expect(linkedProc).toBeDefined();
    expect(linkedQuery).toBeDefined();
  });
});

describe('Module 3: Admin Staff Dashboard & Smart FAQ Management (TC-33 to TC-43)', () => {
  test('TC-33 allows authenticated admin_staff user to access /api/admin/logs and /api/admin/trending', async () => {
    const logsRes = await request(app)
      .get('/api/admin/logs')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(logsRes.status).toBe(200);
    expect(Array.isArray(logsRes.body.sessions)).toBe(true);

    const trendRes = await request(app)
      .get('/api/admin/trending')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(trendRes.status).toBe(200);
    expect(Array.isArray(trendRes.body.trending)).toBe(true);
  });

  test('TC-34 rejects unauthenticated or student-role requests to admin endpoints with 401/403', async () => {
    const unauthRes = await request(app).get('/api/admin/logs');
    expect(unauthRes.status).toBe(401);

    const studentRes = await request(app)
      .get('/api/admin/logs')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(studentRes.status).toBe(403);
  });

  test('TC-35 lists recent chat sessions with filtering by language and keyword', async () => {
    const res = await request(app)
      .get('/api/admin/logs?language=hi&keyword=फीस')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.logs.length).toBeGreaterThan(0);
    expect(res.body.logs[0].language).toBe('hi');
  });

  test('TC-36 opens specific session log detail showing query, response, and timestamp', async () => {
    const res = await request(app)
      .get('/api/admin/logs/sess_demo_aur_01')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.sessionId).toBe('sess_demo_aur_01');
    expect(res.body.logs[0].queryText).toBeDefined();
    expect(res.body.logs[0].responseText).toBeDefined();
    expect(res.body.logs[0].timestamp).toBeDefined();
  });

  test('TC-37 creates a new Smart FAQ entry with valid fields and <=25-char faqId', async () => {
    const res = await request(app)
      .post('/api/admin/faqs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        faqId: 'faq_admin_new_01',
        question: 'Where is the ASET Robotics Lab located?',
        answerText: 'ASET Robotics & IoT Innovation Lab is located in Block-B, Room 108.',
        category: 'Labs & Facilities'
      });

    expect(res.status).toBe(201);
    expect(res.body.faq.faqId).toBe('faq_admin_new_01');
  });

  test('TC-38 updates an existing Smart FAQ entry in place without creating duplicates', async () => {
    const beforeCount = dbManager.store.smartFaqs.length;

    const res = await request(app)
      .put('/api/admin/faqs/faq_admin_new_01')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        answerText: 'ASET Robotics & IoT Innovation Lab is located in Block-B, Ground Floor Room 108.'
      });

    expect(res.status).toBe(200);
    expect(res.body.faq.answerText).toContain('Ground Floor Room 108');
    expect(dbManager.store.smartFaqs.length).toBe(beforeCount);
  });

  test('TC-39 rejects Smart FAQ creation/update when required fields are missing', async () => {
    const res = await request(app)
      .post('/api/admin/faqs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ question: 'Incomplete FAQ without answer or category' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('TC-40 persists newly added Smart FAQ so subsequent public GET /api/faqs and chat queries retrieve it', async () => {
    const publicRes = await request(app).get('/api/faqs');
    expect(publicRes.status).toBe(200);
    const found = publicRes.body.faqs.find((f) => f.faqId === 'faq_admin_new_01');
    expect(found).toBeDefined();

    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'Where is the ASET Robotics Lab located?', language: 'en' });
    expect(chatRes.body.data.translatedText).toContain('Ground Floor Room 108');
  });

  test('TC-41 automatically updates lastUpdated ISO timestamp whenever Smart FAQ is modified', async () => {
    const existing = dbManager.store.smartFaqs.find((f) => f.faqId === 'faq_admin_new_01');
    const prevTimestamp = existing.lastUpdated;

    await new Promise((r) => setTimeout(r, 15));

    const res = await request(app)
      .put('/api/admin/faqs/faq_admin_new_01')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ category: 'Robotics & Labs' });

    expect(res.status).toBe(200);
    expect(res.body.faq.lastUpdated).not.toBe(prevTimestamp);
  });

  test('TC-42 rejects Smart FAQ with faqId exceeding 25 characters', async () => {
    const res = await request(app)
      .post('/api/admin/faqs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        faqId: 'faq_id_that_is_way_longer_than_25_chars',
        question: 'Valid question text here?',
        answerText: 'Valid answer text here.',
        category: 'General'
      });

    expect(res.status).toBe(400);
  });

  test('TC-43 maintains association between ChatSessionHistory messages, widgetId, and sessionId', async () => {
    const sessionId = 'sess_history_assoc_43';
    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'How do I get a Bonafide Certificate?', sessionId, language: 'en' });

    const { widgetId } = chatRes.body.data;
    const detailRes = await request(app)
      .get(`/api/admin/logs/${sessionId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(detailRes.status).toBe(200);
    expect(detailRes.body.history.length).toBeGreaterThanOrEqual(2);
    expect(detailRes.body.history[0].widgetId).toBe(widgetId);
    expect(detailRes.body.history[0].sessionId).toBe(sessionId);
  });
});

describe('Module 4: System Administrator & Infrastructure Resilience (TC-44 to TC-53)', () => {
  test('TC-44 returns server health metrics (uptime, memory, DB status) for system_admin', async () => {
    const res = await request(app)
      .get('/api/sysadmin/health')
      .set('Authorization', `Bearer ${sysAdminToken}`);

    expect(res.status).toBe(200);
    expect(typeof res.body.health.uptimeSeconds).toBe('number');
    expect(res.body.health.memory.rssMb).toBeGreaterThan(0);
    expect(res.body.health.database.connected).toBe(true);
  });

  test('TC-45 reports availability status of external API services (OpenAI, Pinecone, Google Translate)', async () => {
    const res = await request(app)
      .get('/api/sysadmin/health')
      .set('Authorization', `Bearer ${sysAdminToken}`);

    expect(res.status).toBe(200);
    const ext = res.body.health.externalServices;
    expect(ext.openai.available).toBe(true);
    expect(ext.pinecone.available).toBe(true);
    expect(ext.googleTranslate.available).toBe(true);
  });

  test('TC-46 rejects expired system_admin credentials with 401 Unauthorized', async () => {
    const expiredSysToken = jwt.sign(
      { userId: 'sysadmin_aur_01', adminId: 'sysadmin_aur_01', role: 'system_admin' },
      app.locals.services.authService.activeSecret,
      { expiresIn: -5 }
    );

    const res = await request(app)
      .get('/api/sysadmin/health')
      .set('Authorization', `Bearer ${expiredSysToken}`);

    expect(res.status).toBe(401);
  });

  test('TC-47 enforces API rate limits and returns HTTP 429 with retry hint when exceeded', async () => {
    // Temporarily lower rate limit to 2 requests for verification
    app.locals.services.infraService.rateLimitState.maxRequests = 2;

    await request(app).get('/api/health');
    await request(app).get('/api/health');
    const blockedRes = await request(app).get('/api/health');

    expect(blockedRes.status).toBe(429);
    expect(blockedRes.body.error.code).toBe('RATE_LIMIT_EXCEEDED');
    expect(blockedRes.body.error.retryAfterSeconds).toBeGreaterThan(0);

    // Restore normal rate limit
    app.locals.services.infraService.rateLimitState.maxRequests = 120;
  });

  test('TC-48 updates system configuration (supportedLanguages and rateLimitMax) for authorized system_admin', async () => {
    const res = await request(app)
      .put('/api/sysadmin/config')
      .set('Authorization', `Bearer ${sysAdminToken}`)
      .send({
        adminId: 'sysadmin_aur_01',
        rateLimitMax: 150,
        supportedLanguages: ['en', 'hi', 'mr', 'ta', 'bn', 'pa']
      });

    expect(res.status).toBe(200);
    expect(res.body.updated).toBe(true);
    expect(res.body.rateLimits.maxRequests).toBe(150);
  });

  test('TC-49 blocks non-system_admin roles (student, admin_staff) from modifying sysadmin config or rotating keys', async () => {
    const staffRes = await request(app)
      .post('/api/sysadmin/credentials/renew')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(staffRes.status).toBe(403);

    const stuRes = await request(app)
      .put('/api/sysadmin/config')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ rateLimitMax: 500 });
    expect(stuRes.status).toBe(403);
  });

  test('TC-50 masks tokenSecret in all API responses, config views, and logs (never exposes raw secret)', async () => {
    const servicesRes = await request(app)
      .get('/api/sysadmin/services')
      .set('Authorization', `Bearer ${sysAdminToken}`);
    expect(servicesRes.status).toBe(200);
    expect(JSON.stringify(servicesRes.body)).not.toContain(app.locals.services.authService.activeSecret);
    expect(servicesRes.body.security.tokenSecret).toBe('***MASKED***');

    const renewRes = await request(app)
      .post('/api/sysadmin/credentials/renew')
      .set('Authorization', `Bearer ${sysAdminToken}`);
    expect(renewRes.status).toBe(200);
    expect(JSON.stringify(renewRes.body)).not.toContain(app.locals.services.authService.activeSecret);
    expect(renewRes.body.rotation.maskedSecret).toBe('***MASKED***');

    // Re-issue tokens with new rotated secret for remaining tests
    const reLogin = await request(app)
      .post('/api/auth/login')
      .send({ username: 'sysadmin_aur', password: 'SysAdmin@123', role: 'system_admin' });
    sysAdminToken = reLogin.body.token;
  });

  test('TC-51 handles MongoDB repository failure gracefully without crashing the server', async () => {
    dbManager.simulateFailure = true;

    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'BCS 522 Software Engineering Lab evaluation rubric', language: 'en' });

    expect(chatRes.status).toBe(200);
    expect(chatRes.body.data.flags.mongoFailed).toBe(true);
    expect(chatRes.body.data.translatedText).toContain('BCS 522');
  });

  test('TC-52 handles Pinecone vector outage gracefully by falling back to MongoDB-only context with flag', async () => {
    app.locals.services.pineconeAdapter.simulateFailure = true;

    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the annual tuition fee for B.Tech CSE?', language: 'en' });

    expect(chatRes.status).toBe(200);
    expect(chatRes.body.data.flags.pineconeFailed).toBe(true);
    expect(chatRes.body.data.flags.partialContext).toBe(true);
    expect(chatRes.body.data.translatedText).toContain('1,86,000');
  });

  test('TC-53 validates adminId primary key length (<=25 chars) and staffId foreign key integrity', async () => {
    const badIdRes = await request(app)
      .put('/api/sysadmin/config')
      .set('Authorization', `Bearer ${sysAdminToken}`)
      .send({ adminId: 'sysadmin_id_exceeding_twenty_five_characters' });
    expect(badIdRes.status).toBe(400);

    await expect(
      app.locals.services.mongoRepo.insertRecord(
        'systemAdmins',
        'adminId',
        Models.SystemAdministrator,
        {
          adminId: 'sysadmin_bad_fk_01',
          staffId: 'non_existent_staff_id',
          apiEndpoint: '/api/sysadmin',
          role: 'system_admin',
          username: 'bad_sys',
          passwordHash: 'hash'
        },
        [{ field: 'staffId', targetCollection: 'adminStaff', targetField: 'staffId' }]
      )
    ).rejects.toThrow(/Foreign key constraint failed/);
  });
});
'@

# Install backend dependencies
Write-Step "Installing backend npm dependencies"
$backendDir = Join-Path $RootDir "backend"
Push-Location $backendDir
try {
    & npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed in $backendDir with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Ok "Backend scaffolded and dependencies installed successfully! Proceed to 02-scaffold-widget.ps1."
exit 0