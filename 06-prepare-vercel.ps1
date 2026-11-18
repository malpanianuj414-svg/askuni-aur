# 06-prepare-vercel.ps1
# Prepares the AskUni unified repository for single-URL deployment on Vercel.
# Compatible with Windows PowerShell 5.1 and PowerShell 7+.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RootDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

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
    [System.IO.File]::WriteAllText($fullPath, $Content, $utf8NoBom)
    Write-Host "  Wrote $RelativePath" -ForegroundColor DarkGray
}

Write-Step "Configuring AskUni for Vercel Serverless + Static Edge Deployment"

# 1. Root package.json so Vercel builds both backend and frontend
Write-ProjectFile -RelativePath "package.json" -Content @'
{
  "name": "askuni-unified",
  "version": "1.0.0",
  "private": true,
  "description": "AskUni Language-Agnostic AI Chatbot - Amity University Rajasthan (BCS 522)",
  "scripts": {
    "vercel-build": "npm --prefix backend install && npm --prefix frontend install && npm --prefix frontend run build && npm --prefix frontend run build:embed",
    "start": "node backend/src/index.js"
  }
}
'@

# 2. Vercel Serverless Function entry point (api/index.js)
Write-ProjectFile -RelativePath "api\index.js" -Content @'
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
    })();
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
        message: 'Failed to initialize AskUni backend service.'
      }
    });
  }
};
'@

# 3. vercel.json routing & build configuration
Write-ProjectFile -RelativePath "vercel.json" -Content @'
{
  "version": 2,
  "buildCommand": "npm run vercel-build",
  "outputDirectory": "frontend/dist",
  "functions": {
    "api/index.js": {
      "includeFiles": "{backend/data/**,frontend/dist/askuni-widget.iife.js}"
    }
  },
  "rewrites": [
    { "source": "/api/(.*)", "destination": "/api/index.js" },
    { "source": "/widget/askuni-widget.js", "destination": "/api/index.js" },
    { "source": "/((?!api|widget|assets|embed-demo\\.html).*)", "destination": "/index.html" }
  ]
}
'@

# 4. Patch backend/src/config/db.js to use /tmp on Vercel serverless
Write-Step "Updating backend/src/config/db.js for Vercel read-only filesystem compatibility"
Write-ProjectFile -RelativePath "backend\src\config\db.js" -Content @'
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
'@

# 5. Patch backend/src/adapters/PineconeVectorAdapter.js for Vercel /tmp compatibility
Write-Step "Updating PineconeVectorAdapter.js for Vercel /tmp storage compatibility"
$pineconePath = Join-Path $RootDir "backend\src\adapters\PineconeVectorAdapter.js"
$pineconeJs = [System.IO.File]::ReadAllText($pineconePath)
$pineconeJs = $pineconeJs.Replace("const path = require('path');", "const os = require('os');`nconst path = require('path');")
$pineconeJs = $pineconeJs.Replace(
    "const KB_FILE = path.resolve(__dirname, '../../data/knowledge-base.json');",
    "const SEED_KB_FILE = path.resolve(__dirname, '../../data/knowledge-base.json');`nconst KB_FILE = process.env.VERCEL ? path.join(os.tmpdir(), 'askuni-knowledge-base.json') : SEED_KB_FILE;"
)
$pineconeJs = $pineconeJs.Replace(
    "if (fs.existsSync(KB_FILE)) {",
    "const sourceFile = fs.existsSync(KB_FILE) ? KB_FILE : SEED_KB_FILE;`n      if (fs.existsSync(sourceFile)) {"
)
$pineconeJs = $pineconeJs.Replace("fs.readFileSync(KB_FILE, 'utf8')", "fs.readFileSync(sourceFile, 'utf8')")
[System.IO.File]::WriteAllText($pineconePath, $pineconeJs, $utf8NoBom)

# 6. Enable trust proxy in backend/src/app.js for Vercel's reverse proxy
Write-Step "Enabling Express trust proxy for Vercel edge network"
$appJsPath = Join-Path $RootDir "backend\src\app.js"
$appJs = [System.IO.File]::ReadAllText($appJsPath)
if (-not $appJs.Contains("trust proxy")) {
    $appJs = $appJs.Replace("const app = express();", "const app = express();`n  app.set('trust proxy', 1);")
    [System.IO.File]::WriteAllText($appJsPath, $appJs, $utf8NoBom)
}

# 7. Write clean .gitignore (keeping backend/data/*.json tracked so Vercel bundles initial seed)
Write-ProjectFile -RelativePath ".gitignore" -Content @'
node_modules/
frontend/dist/
reports/*.json
.vercel/
.env
backend/.env
*.log
'@

Write-Host ""
Write-Ok "AskUni is ready for Vercel deployment!"
exit 0