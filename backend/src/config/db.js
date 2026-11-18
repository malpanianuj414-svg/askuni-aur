const fs = require('fs');
const os = require('os');
const path = require('path');
const mongoose = require('mongoose');
const config = require('./env');

const SEED_DATA_DIR = path.resolve(__dirname, '../../data');
const SEED_DB_FILE = path.join(SEED_DATA_DIR, 'mock-db.json');
const RUNTIME_DB_FILE = process.env.VERCEL
  ? path.join(os.tmpdir(), 'askuni-mock-db.json')
  : SEED_DB_FILE;

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
    const dir = path.dirname(RUNTIME_DB_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }

  loadFromDisk() {
    this.ensureDataDir();
    const targetFile = fs.existsSync(RUNTIME_DB_FILE) ? RUNTIME_DB_FILE : SEED_DB_FILE;
    if (fs.existsSync(targetFile)) {
      try {
        const raw = fs.readFileSync(targetFile, 'utf8');
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
    fs.writeFileSync(RUNTIME_DB_FILE, JSON.stringify(this.store, null, 2), 'utf8');
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
module.exports = { dbManager, MOCK_DB_FILE: RUNTIME_DB_FILE, EMPTY_STORE };