# 02-scaffold-widget.ps1
# Scaffolds the React + Vite + Tailwind AskUni Widget, Amity University Rajasthan Demo Page,
# /admin Dashboard, /sysadmin Panel, embeddable script bundle, and Vitest test suite (TC-01..TC-12).
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

Write-Step "Scaffolding AskUni Frontend Widget & Dashboards ($RootDir\frontend)"

# 1. frontend/package.json
Write-ProjectFile -RelativePath "frontend\package.json" -Content @'
{
  "name": "askuni-frontend",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite --port 5173",
    "build": "vite build",
    "build:embed": "vite build --config vite.embed.config.js",
    "preview": "vite preview --port 5173",
    "test": "vitest run"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.5.0",
    "@testing-library/react": "^16.0.1",
    "@testing-library/user-event": "^14.5.2",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.20",
    "jsdom": "^25.0.0",
    "postcss": "^8.4.41",
    "tailwindcss": "^3.4.10",
    "vite": "^5.4.2",
    "vitest": "^2.0.5"
  }
}
'@

# 2. frontend/vite.config.js
Write-ProjectFile -RelativePath "frontend\vite.config.js" -Content @'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true
      },
      '/widget': {
        target: 'http://localhost:5000',
        changeOrigin: true
      }
    }
  }
});
'@

# 3. frontend/vite.embed.config.js (Builds standalone single-<script> embeddable bundle)
Write-ProjectFile -RelativePath "frontend\vite.embed.config.js" -Content @'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  define: {
    'process.env.NODE_ENV': '"production"'
  },
  build: {
    emptyOutDir: false,
    lib: {
      entry: resolve(__dirname, 'src/embed.jsx'),
      name: 'AskUniWidget',
      formats: ['iife'],
      fileName: () => 'askuni-widget.iife.js'
    }
  }
});
'@

# 4. frontend/vitest.config.js
Write-ProjectFile -RelativePath "frontend\vitest.config.js" -Content @'
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/tests/setup.js'],
    include: ['src/tests/**/*.test.{js,jsx}']
  }
});
'@

# 5. frontend/tailwind.config.js
Write-ProjectFile -RelativePath "frontend\tailwind.config.js" -Content @'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        amityBlue: '#003366',
        amityGold: '#F59E0B',
        amityDark: '#001F3F'
      }
    }
  },
  plugins: []
};
'@

# 6. frontend/postcss.config.js
Write-ProjectFile -RelativePath "frontend\postcss.config.js" -Content @'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
};
'@

# 7. frontend/index.html
Write-ProjectFile -RelativePath "frontend\index.html" -Content @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AskUni — Amity University Rajasthan AI Assistant (BCS 522)</title>
  </head>
  <body class="bg-slate-50 text-slate-900 antialiased">
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
'@

# 8. frontend/public/embed-demo.html (External partner site single-<script> integration demo)
Write-ProjectFile -RelativePath "frontend\public\embed-demo.html" -Content @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>External Campus Portal — Single &lt;script&gt; Embed Demo</title>
    <style>
      body { font-family: system-ui, -apple-system, sans-serif; margin: 0; background: #f1f5f9; color: #0f172a; }
      header { background: #003366; color: #fff; padding: 24px 32px; }
      main { max-width: 820px; margin: 32px auto; background: #fff; padding: 28px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.06); }
      pre { background: #0f172a; color: #f8fafc; padding: 14px; border-radius: 8px; overflow-x: auto; font-size: 13px; }
    </style>
  </head>
  <body>
    <header>
      <h1 style="margin:0;">Amity School of Engineering &amp; Technology — Student Notice Portal</h1>
      <p style="margin:6px 0 0; opacity:0.85;">Demonstrating single &lt;script&gt; tag embedding of AskUni Widget</p>
    </header>
    <main>
      <h2>How Any University Web Page Embeds AskUni</h2>
      <p>Add the following script snippet before the closing <code>&lt;/body&gt;</code> tag:</p>
      <pre>&lt;script&gt;window.ASKUNI_API_BASE = "http://localhost:5000/api";&lt;/script&gt;
&lt;script src="http://localhost:5000/widget/askuni-widget.js" async&gt;&lt;/script&gt;</pre>
      <p>Click the floating <strong>AskUni Chat</strong> button in the bottom-right corner to test live multilingual queries.</p>
    </main>
    <script>window.ASKUNI_API_BASE = "http://localhost:5000/api";</script>
    <script src="http://localhost:5000/widget/askuni-widget.js" async></script>
  </body>
</html>
'@

# 9. frontend/src/index.css
Write-ProjectFile -RelativePath "frontend\src\index.css" -Content @'
@tailwind base;
@tailwind components;
@tailwind utilities;
'@

# 10. frontend/src/models/ChatbotWidget.js (UML Mirror Classes: ChatbotWidget, UserQuery, ChatbotResponse)
Write-ProjectFile -RelativePath "frontend\src\models\ChatbotWidget.js" -Content @'
export const WIDGET_STATES = {
  HIDDEN: 'hidden',
  INITIALIZED: 'initialized',
  ACTIVE: 'active',
  AWAITING_INPUT: 'awaiting input',
  QUERY_SUBMITTED: 'query submitted',
  PROCESSING: 'processing',
  RESPONSE_DISPLAYED: 'response displayed'
};

export class UserQuery {
  constructor({ queryId, userId, widgetId, queryText, language = 'auto', sessionId = '' }) {
    this.queryId = queryId || `q_${Date.now().toString(36)}`.slice(0, 25);
    this.userId = userId || 'anon_visitor';
    this.widgetId = widgetId || 'w_default';
    this.queryText = typeof queryText === 'string' ? queryText : '';
    this.language = language || 'auto';
    this.sessionId = sessionId;
    this.timestamp = new Date().toISOString();
  }

  validatePayload() {
    if (typeof this.queryText !== 'string' || this.queryText.trim().length === 0) {
      return {
        valid: false,
        error: 'Please enter a valid question (empty or whitespace-only queries are not allowed).'
      };
    }
    if (this.queryText.trim().length > 1000) {
      return {
        valid: false,
        error: 'Question exceeds maximum length of 1000 characters.'
      };
    }
    return { valid: true, error: null };
  }

  toJSON() {
    return {
      queryId: this.queryId,
      userId: this.userId,
      widgetId: this.widgetId,
      queryText: this.queryText.trim(),
      language: this.language,
      sessionId: this.sessionId,
      timestamp: this.timestamp
    };
  }
}

export class ChatbotResponse {
  constructor(apiData = {}) {
    this.responseId = apiData.responseId || `rs_${Date.now().toString(36)}`;
    this.processorId = apiData.processorId || '';
    this.generatedText = apiData.generatedText || '';
    this.translatedText = apiData.translatedText || apiData.generatedText || '';
    this.targetLanguage = apiData.targetLanguage || 'en';
    this.grounded = Boolean(apiData.grounded);
    this.sources = Array.isArray(apiData.sources) ? apiData.sources : [];
    this.flags = apiData.flags || {};
    this.notice = apiData.notice || null;
    this.timestamp = apiData.timestamp || new Date().toISOString();
  }

  formatForDisplay() {
    return {
      id: this.responseId,
      role: 'assistant',
      text: this.translatedText,
      originalText: this.generatedText,
      language: this.targetLanguage,
      grounded: this.grounded,
      sources: this.sources,
      flags: this.flags,
      notice: this.notice,
      formattedTime: new Date(this.timestamp).toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit'
      }),
      timestamp: this.timestamp
    };
  }
}

export class ChatbotWidget {
  constructor({ widgetId = 'w_aur_main', userId = 'anon_visitor', preferredLanguage = 'auto' } = {}) {
    this.widgetId = widgetId;
    this.userId = userId;
    this.preferredLanguage = preferredLanguage;
    this.isVisible = false;
    this.isMinimized = false;
    this.state = WIDGET_STATES.HIDDEN;
    this.sessionId = `sess_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    this.history = [];
  }

  initialize(sessionData = {}) {
    if (sessionData.sessionId) this.sessionId = sessionData.sessionId;
    if (sessionData.userId) this.userId = sessionData.userId;
    if (sessionData.widgetId) this.widgetId = sessionData.widgetId;
    this.isVisible = true;
    this.isMinimized = false;
    this.state = WIDGET_STATES.INITIALIZED;
    return this.getSnapshot();
  }

  renderInterface() {
    this.isVisible = true;
    this.isMinimized = false;
    this.state = WIDGET_STATES.AWAITING_INPUT;
    return this.getSnapshot();
  }

  captureInput(rawText, language = this.preferredLanguage) {
    const query = new UserQuery({
      userId: this.userId,
      widgetId: this.widgetId,
      queryText: rawText,
      language,
      sessionId: this.sessionId
    });
    const validation = query.validatePayload();
    if (!validation.valid) {
      return { ok: false, error: validation.error, query: null };
    }
    this.state = WIDGET_STATES.QUERY_SUBMITTED;
    this.history.push({
      historyId: `hu_${Date.now().toString(36)}`,
      widgetId: this.widgetId,
      sessionId: this.sessionId,
      role: 'user',
      text: query.queryText.trim(),
      language,
      formattedTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      timestamp: query.timestamp
    });
    this.state = WIDGET_STATES.PROCESSING;
    return { ok: true, error: null, query };
  }

  displayResponse(rawApiData) {
    if (rawApiData && rawApiData.sessionId) {
      this.sessionId = rawApiData.sessionId;
    }
    const dto = new ChatbotResponse(rawApiData);
    const formatted = dto.formatForDisplay();
    this.history.push({
      historyId: formatted.id,
      widgetId: this.widgetId,
      sessionId: this.sessionId,
      ...formatted
    });
    this.state = WIDGET_STATES.RESPONSE_DISPLAYED;
    return formatted;
  }

  minimize() {
    this.isMinimized = true;
    this.state = WIDGET_STATES.ACTIVE;
    return this.getSnapshot();
  }

  close() {
    this.isVisible = false;
    this.isMinimized = false;
    this.state = WIDGET_STATES.HIDDEN;
    return this.getSnapshot();
  }

  getSnapshot() {
    return {
      widgetId: this.widgetId,
      userId: this.userId,
      preferredLanguage: this.preferredLanguage,
      isVisible: this.isVisible,
      isMinimized: this.isMinimized,
      state: this.state,
      sessionId: this.sessionId,
      history: [...this.history]
    };
  }
}
'@

# 11. frontend/src/services/api.js
Write-ProjectFile -RelativePath "frontend\src\services\api.js" -Content @'
const getApiBase = () => {
  if (typeof window !== 'undefined' && window.ASKUNI_API_BASE) {
    return window.ASKUNI_API_BASE;
  }
  return 'http://localhost:5000/api';
};

async function apiRequest(path, { method = 'GET', body = null, token = '' } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  const resp = await fetch(`${getApiBase()}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
  });
  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const errMsg = data?.error?.message || `Request failed with status ${resp.status}`;
    const err = new Error(errMsg);
    err.status = resp.status;
    err.code = data?.error?.code || 'API_ERROR';
    throw err;
  }
  return data;
}

export const askUniApi = {
  createAnonymousSession: (preferredLanguage = 'en') =>
    apiRequest('/auth/anonymous', { method: 'POST', body: { preferredLanguage } }),

  login: (username, password, role) =>
    apiRequest('/auth/login', { method: 'POST', body: { username, password, role } }),

  fetchFaqs: (category = '') =>
    apiRequest(`/faqs${category ? `?category=${encodeURIComponent(category)}` : ''}`),

  sendQuery: (payload, token = '') =>
    apiRequest('/chat/query', { method: 'POST', body: payload, token }),

  // Admin Staff
  getAdminLogs: (token, filters = {}) => {
    const params = new URLSearchParams();
    if (filters.date) params.set('date', filters.date);
    if (filters.language && filters.language !== 'all') params.set('language', filters.language);
    if (filters.keyword) params.set('keyword', filters.keyword);
    const qs = params.toString();
    return apiRequest(`/admin/logs${qs ? `?${qs}` : ''}`, { token });
  },

  getAdminSessionDetail: (token, sessionId) =>
    apiRequest(`/admin/logs/${encodeURIComponent(sessionId)}`, { token }),

  getAdminTrending: (token) =>
    apiRequest('/admin/trending', { token }),

  createFaq: (token, payload) =>
    apiRequest('/admin/faqs', { method: 'POST', body: payload, token }),

  updateFaq: (token, faqId, payload) =>
    apiRequest(`/admin/faqs/${encodeURIComponent(faqId)}`, { method: 'PUT', body: payload, token }),

  deleteFaq: (token, faqId) =>
    apiRequest(`/admin/faqs/${encodeURIComponent(faqId)}`, { method: 'DELETE', token }),

  uploadKnowledge: (token, payload) =>
    apiRequest('/admin/knowledge/upload', { method: 'POST', body: payload, token }),

  // System Admin
  getSysAdminHealth: (token) =>
    apiRequest('/sysadmin/health', { token }),

  getSysAdminServices: (token) =>
    apiRequest('/sysadmin/services', { token }),

  renewCredentials: (token) =>
    apiRequest('/sysadmin/credentials/renew', { method: 'POST', token }),

  updateSysConfig: (token, payload) =>
    apiRequest('/sysadmin/config', { method: 'PUT', body: payload, token })
};
'@

# 12. frontend/src/components/WidgetContainer.jsx
Write-ProjectFile -RelativePath "frontend\src\components\WidgetContainer.jsx" -Content @'
import React, { useEffect, useRef, useState } from 'react';
import { ChatbotWidget, WIDGET_STATES } from '../models/ChatbotWidget';
import { askUniApi } from '../services/api';

const LANGUAGE_OPTIONS = [
  { code: 'auto', label: 'Auto-Detect' },
  { code: 'en', label: 'English' },
  { code: 'hi', label: 'हिन्दी (Hindi)' },
  { code: 'mr', label: 'मराठी (Marathi)' },
  { code: 'ta', label: 'தமிழ் (Tamil)' },
  { code: 'bn', label: 'বাংলা (Bengali)' },
  { code: 'pa', label: 'ਪੰਜਾਬੀ (Punjabi)' }
];

export default function WidgetContainer() {
  const widgetRef = useRef(new ChatbotWidget());
  const messagesEndRef = useRef(null);

  const [snapshot, setSnapshot] = useState(() => widgetRef.current.getSnapshot());
  const [preferredLanguage, setPreferredLanguage] = useState('auto');
  const [inputText, setInputText] = useState('');
  const [validationError, setValidationError] = useState('');
  const [apiError, setApiError] = useState('');
  const [faqs, setFaqs] = useState([]);
  const [selectedFaq, setSelectedFaq] = useState('');
  const [token, setToken] = useState('');
  const [authUser, setAuthUser] = useState(null);
  const [showLoginBox, setShowLoginBox] = useState(false);
  const [loginUser, setLoginUser] = useState('A50105224001');
  const [loginPass, setLoginPass] = useState('Student@123');
  const [loginError, setLoginError] = useState('');

  useEffect(() => {
    let active = true;
    askUniApi
      .fetchFaqs()
      .then((res) => {
        if (active && Array.isArray(res.faqs)) {
          setFaqs(res.faqs);
        }
      })
      .catch(() => {});
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (messagesEndRef.current && typeof messagesEndRef.current.scrollIntoView === 'function') {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [snapshot.history.length, snapshot.state]);

  const handleOpenWidget = async () => {
    setApiError('');
    setValidationError('');
    const initSnap = widgetRef.current.initialize();
    setSnapshot(initSnap);

    if (!token) {
      try {
        const anon = await askUniApi.createAnonymousSession(
          preferredLanguage === 'auto' ? 'en' : preferredLanguage
        );
        if (anon && anon.token) {
          setToken(anon.token);
          widgetRef.current.initialize({
            sessionId: anon.sessionId,
            userId: anon.user?.userId,
            widgetId: anon.user?.widgetId
          });
        }
      } catch (_err) {
        // Widget still operates offline/gracefully if session endpoint is delayed
      }
    }

    setSnapshot(widgetRef.current.renderInterface());
  };

  const handleMinimize = () => {
    setSnapshot(widgetRef.current.minimize());
  };

  const handleClose = () => {
    setSnapshot(widgetRef.current.close());
  };

  const handleLanguageChange = (e) => {
    const lang = e.target.value;
    setPreferredLanguage(lang);
    widgetRef.current.preferredLanguage = lang;
    setSnapshot(widgetRef.current.getSnapshot());
  };

  const submitQuestion = async (rawQuestionText, explicitLang = null) => {
    setValidationError('');
    setApiError('');

    const langToUse = explicitLang || preferredLanguage;
    const captured = widgetRef.current.captureInput(rawQuestionText, langToUse);
    if (!captured.ok) {
      setValidationError(captured.error);
      return;
    }

    setInputText('');
    setSnapshot(widgetRef.current.getSnapshot());

    try {
      const res = await askUniApi.sendQuery(captured.query.toJSON(), token);
      if (res && res.data) {
        widgetRef.current.displayResponse(res.data);
        setSnapshot(widgetRef.current.getSnapshot());
      }
    } catch (err) {
      widgetRef.current.state = WIDGET_STATES.AWAITING_INPUT;
      setSnapshot(widgetRef.current.getSnapshot());
      setApiError(err.message || 'Unable to reach AskUni assistant.');
    }
  };

  const handleFormSubmit = (e) => {
    e.preventDefault();
    submitQuestion(inputText);
  };

  const handleFaqSelect = (e) => {
    const val = e.target.value;
    setSelectedFaq(val);
    if (val) {
      submitQuestion(val);
      setSelectedFaq('');
    }
  };

  const handleStudentLogin = async (e) => {
    e.preventDefault();
    setLoginError('');
    try {
      const res = await askUniApi.login(loginUser, loginPass, 'student');
      setToken(res.token);
      setAuthUser(res.user);
      widgetRef.current.initialize({
        sessionId: res.sessionId,
        userId: res.user.userId,
        widgetId: res.user.widgetId
      });
      setSnapshot(widgetRef.current.renderInterface());
      setShowLoginBox(false);
    } catch (err) {
      setLoginError(err.message || 'Student login failed.');
    }
  };

  const handleStudentLogout = async () => {
    setAuthUser(null);
    setToken('');
    widgetRef.current = new ChatbotWidget();
    await handleOpenWidget();
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Escape') {
      handleMinimize();
    }
  };

  return (
    <div className="fixed bottom-5 right-5 z-50 font-sans">
      {/* Floating Launcher Button */}
      {(!snapshot.isVisible || snapshot.isMinimized) && (
        <button
          type="button"
          onClick={handleOpenWidget}
          aria-label="Open AskUni Assistant"
          data-testid="askuni-launcher"
          className="flex items-center gap-2.5 rounded-full bg-amityBlue px-5 py-3.5 text-sm font-semibold text-white shadow-xl ring-2 ring-amityGold/70 transition hover:bg-amityDark focus:outline-none focus:ring-4 focus:ring-amityGold"
        >
          <span className="inline-flex h-2.5 w-2.5 rounded-full bg-emerald-400" />
          <span>{snapshot.isMinimized ? 'Resume AskUni' : 'AskUni Chat'}</span>
        </button>
      )}

      {/* Active Chat Window */}
      {snapshot.isVisible && !snapshot.isMinimized && (
        <section
          role="dialog"
          aria-label="AskUni Institutional Assistant"
          data-testid="askuni-dialog"
          onKeyDown={handleKeyDown}
          className="flex h-[560px] w-[390px] max-w-[94vw] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl"
        >
          {/* Header */}
          <div className="bg-amityBlue px-4 py-3 text-white">
            <div className="flex items-center justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-sm font-bold tracking-wide">AskUni — Amity Rajasthan</h2>
                  <span
                    data-testid="widget-state-badge"
                    className="rounded bg-white/15 px-1.5 py-0.5 text-[10px] uppercase tracking-wider text-amber-200"
                  >
                    {snapshot.state}
                  </span>
                </div>
                <p className="text-[11px] text-slate-200">
                  {authUser ? `Signed in: ${authUser.name} (${authUser.enrollmentNo})` : 'Anonymous Visitor Mode'}
                </p>
              </div>
              <div className="flex items-center gap-1">
                <button
                  type="button"
                  onClick={() => setShowLoginBox((v) => !v)}
                  className="rounded bg-white/10 px-2 py-1 text-[11px] font-medium hover:bg-white/20"
                  title="Toggle Student Login"
                >
                  {authUser ? 'Profile' : 'Student Login'}
                </button>
                <button
                  type="button"
                  onClick={handleMinimize}
                  aria-label="Minimize AskUni"
                  data-testid="askuni-minimize"
                  className="rounded px-2 py-1 text-sm font-bold hover:bg-white/20"
                >
                  _
                </button>
                <button
                  type="button"
                  onClick={handleClose}
                  aria-label="Close AskUni"
                  data-testid="askuni-close"
                  className="rounded px-2 py-1 text-sm font-bold hover:bg-white/20"
                >
                  ✕
                </button>
              </div>
            </div>

            {/* Language Selector + Smart FAQ Dropdown */}
            <div className="mt-2.5 grid grid-cols-2 gap-2">
              <div>
                <label htmlFor="askuni-lang" className="sr-only">Preferred Language</label>
                <select
                  id="askuni-lang"
                  aria-label="Preferred Language"
                  data-testid="language-selector"
                  value={preferredLanguage}
                  onChange={handleLanguageChange}
                  className="w-full rounded-lg border border-white/20 bg-amityDark px-2 py-1.5 text-xs text-white focus:border-amityGold focus:outline-none"
                >
                  {LANGUAGE_OPTIONS.map((opt) => (
                    <option key={opt.code} value={opt.code}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label htmlFor="askuni-faq" className="sr-only">Smart FAQs</label>
                <select
                  id="askuni-faq"
                  aria-label="Smart FAQs"
                  data-testid="smart-faq-dropdown"
                  value={selectedFaq}
                  onChange={handleFaqSelect}
                  className="w-full rounded-lg border border-white/20 bg-amityDark px-2 py-1.5 text-xs text-white focus:border-amityGold focus:outline-none"
                >
                  <option value="">Smart FAQs ({faqs.length})...</option>
                  {faqs.map((faq) => (
                    <option key={faq.faqId} value={faq.question}>
                      [{faq.category}] {faq.question}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          {/* Optional Student Authentication Drawer */}
          {showLoginBox && (
            <div className="border-b border-slate-200 bg-amber-50/70 p-3 text-xs">
              {authUser ? (
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold text-slate-800">{authUser.name} ({authUser.program})</p>
                    <p className="text-slate-600">Session ID: {snapshot.sessionId}</p>
                  </div>
                  <button
                    type="button"
                    onClick={handleStudentLogout}
                    className="rounded bg-slate-800 px-2.5 py-1 font-medium text-white hover:bg-slate-700"
                  >
                    Sign Out
                  </button>
                </div>
              ) : (
                <form onSubmit={handleStudentLogin} className="space-y-2">
                  <p className="font-semibold text-slate-800">Amizone Student Login (Optional)</p>
                  <div className="grid grid-cols-2 gap-1.5">
                    <input
                      type="text"
                      value={loginUser}
                      onChange={(e) => setLoginUser(e.target.value)}
                      placeholder="Enrollment No"
                      aria-label="Student Enrollment Number"
                      className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
                    />
                    <input
                      type="password"
                      value={loginPass}
                      onChange={(e) => setLoginPass(e.target.value)}
                      placeholder="Password"
                      aria-label="Student Password"
                      className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
                    />
                  </div>
                  {loginError && <p className="text-[11px] font-medium text-red-600">{loginError}</p>}
                  <button
                    type="submit"
                    className="w-full rounded bg-amityBlue py-1 font-semibold text-white hover:bg-amityDark"
                  >
                    Authenticate Student Session
                  </button>
                </form>
              )}
            </div>
          )}

          {/* Conversation History Area */}
          <div
            role="log"
            aria-live="polite"
            data-testid="chat-messages"
            className="flex-1 space-y-3 overflow-y-auto bg-slate-50 p-3.5 text-sm"
          >
            <div className="rounded-xl border border-slate-200 bg-white p-3 text-xs text-slate-700 shadow-sm">
              <p className="font-semibold text-amityBlue">Namaste! Welcome to Amity University Rajasthan.</p>
              <p className="mt-1">
                Ask about B.Tech CSE exams, BCS 522 lab schedules, fees, scholarships, or hostel facilities in English, Hindi, Marathi, Tamil, Bengali, or Punjabi.
              </p>
              <p className="mt-1 text-[10px] text-slate-400">Session: {snapshot.sessionId}</p>
            </div>

            {snapshot.history.map((msg, idx) => (
              <div
                key={msg.historyId || idx}
                data-testid={`chat-bubble-${msg.role}`}
                className={`flex flex-col ${msg.role === 'user' ? 'items-end' : 'items-start'}`}
              >
                <div
                  className={`max-w-[85%] rounded-2xl px-3.5 py-2.5 text-xs leading-relaxed shadow-sm ${
                    msg.role === 'user'
                      ? 'rounded-br-sm bg-amityBlue text-white'
                      : 'rounded-bl-sm border border-slate-200 bg-white text-slate-800'
                  }`}
                >
                  <p className="whitespace-pre-line">{msg.text}</p>
                  {msg.notice && (
                    <p className="mt-1.5 rounded bg-amber-50 px-2 py-1 text-[11px] text-amber-800">
                      {msg.notice}
                    </p>
                  )}
                  {Array.isArray(msg.sources) && msg.sources.length > 0 && (
                    <div className="mt-1.5 flex flex-wrap gap-1">
                      {msg.sources.map((s, sIdx) => (
                        <span
                          key={sIdx}
                          className="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-medium text-slate-600"
                        >
                          {s.source}: {s.category}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
                <span className="mt-0.5 px-1 text-[10px] text-slate-400">
                  {msg.role === 'user' ? 'You' : `AskUni (${msg.language || 'en'})`} • {msg.formattedTime}
                </span>
              </div>
            ))}

            {snapshot.state === WIDGET_STATES.PROCESSING && (
              <div
                data-testid="chat-loading"
                className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs text-slate-600 shadow-sm"
              >
                <span className="h-2 w-2 animate-ping rounded-full bg-amityGold" />
                <span>Retrieving institutional records...</span>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Validation & Error Banners */}
          {validationError && (
            <div
              role="alert"
              data-testid="validation-error"
              className="border-t border-red-200 bg-red-50 px-3 py-1.5 text-xs font-medium text-red-700"
            >
              {validationError}
            </div>
          )}

          {apiError && (
            <div
              role="alert"
              data-testid="api-error"
              className="border-t border-amber-200 bg-amber-50 px-3 py-1.5 text-xs font-medium text-amber-800"
            >
              {apiError}
            </div>
          )}

          {/* Query Input Form */}
          <form onSubmit={handleFormSubmit} className="flex items-center gap-2 border-t border-slate-200 bg-white p-2.5">
            <input
              type="text"
              value={inputText}
              onChange={(e) => {
                setInputText(e.target.value);
                if (validationError) setValidationError('');
              }}
              placeholder="Ask about exams, fees, timetable..."
              aria-label="AskUni Question Input"
              data-testid="chat-input"
              className="flex-1 rounded-xl border border-slate-300 px-3 py-2 text-xs text-slate-900 placeholder-slate-400 focus:border-amityBlue focus:outline-none focus:ring-2 focus:ring-amityBlue/20"
            />
            <button
              type="submit"
              disabled={snapshot.state === WIDGET_STATES.PROCESSING}
              data-testid="chat-send-btn"
              className="rounded-xl bg-amityGold px-4 py-2 text-xs font-bold text-slate-950 transition hover:bg-amber-400 disabled:opacity-50"
            >
              Send
            </button>
          </form>
        </section>
      )}
    </div>
  );
}
'@

# 13. frontend/src/components/CollegeLandingPage.jsx
Write-ProjectFile -RelativePath "frontend\src\components\CollegeLandingPage.jsx" -Content @'
import React from 'react';

export default function CollegeLandingPage({ onNavigate }) {
  return (
    <div className="min-h-screen bg-slate-50">
      {/* Top Institution Bar */}
      <header className="bg-amityBlue text-white shadow-md">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-6 py-4">
          <div>
            <span className="rounded bg-amityGold px-2 py-0.5 text-[11px] font-bold uppercase tracking-wider text-slate-950">
              Amity University Rajasthan • Jaipur
            </span>
            <h1 className="mt-1 text-xl font-bold tracking-tight sm:text-2xl">
              Amity School of Engineering &amp; Technology (ASET)
            </h1>
            <p className="text-xs text-slate-200">
              B.Tech Computer Science &amp; Engineering • Software Engineering Lab (BCS 522)
            </p>
          </div>

          <nav className="flex flex-wrap items-center gap-2 text-xs font-semibold">
            <button
              type="button"
              onClick={() => onNavigate('/')}
              className="rounded-lg bg-white/15 px-3 py-2 text-white hover:bg-white/25"
            >
              Student Portal
            </button>
            <button
              type="button"
              onClick={() => onNavigate('/admin')}
              className="rounded-lg bg-amityGold px-3 py-2 text-slate-950 hover:bg-amber-400"
            >
              Admin Staff (/admin)
            </button>
            <button
              type="button"
              onClick={() => onNavigate('/sysadmin')}
              className="rounded-lg border border-white/30 px-3 py-2 text-white hover:bg-white/10"
            >
              System Admin (/sysadmin)
            </button>
          </nav>
        </div>
      </header>

      {/* Hero Banner */}
      <section className="border-b border-slate-200 bg-gradient-to-br from-amityDark via-amityBlue to-slate-900 py-14 text-white">
        <div className="mx-auto max-w-6xl px-6">
          <div className="max-w-3xl">
            <h2 className="text-3xl font-extrabold leading-tight sm:text-4xl">
              AskUni: Language-Agnostic Institutional AI Assistant
            </h2>
            <p className="mt-4 text-sm leading-relaxed text-slate-200 sm:text-base">
              Instant, grounded answers for prospective applicants, parents, and enrolled students regarding semester examinations, B.Tech CSE timetables, fee structures, hostel regulations, and merit scholarships across English, Hindi, Marathi, Tamil, Bengali, and Punjabi.
            </p>
            <div className="mt-6 flex flex-wrap gap-3 text-xs">
              <span className="rounded-full bg-white/10 px-3.5 py-1.5 font-medium text-amber-300">
                Parallel RAG: MongoDB Smart FAQs + Pinecone Vector Circulars
              </span>
              <span className="rounded-full bg-white/10 px-3.5 py-1.5 font-medium text-emerald-300">
                Zero-Hallucination Grounded Responses
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* Campus Quick Information Cards */}
      <main className="mx-auto max-w-6xl px-6 py-10">
        <div className="grid gap-6 md:grid-cols-3">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <span className="text-xs font-bold uppercase tracking-wider text-amityBlue">Examinations</span>
            <h3 className="mt-1 text-lg font-bold text-slate-900">Odd Semester Schedule 2026</h3>
            <p className="mt-2 text-sm text-slate-600">
              Practical &amp; Lab Viva-Voce (including BCS 522) run Nov 23–30, 2026. Theory End-Term Examinations commence December 4, 2026.
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <span className="text-xs font-bold uppercase tracking-wider text-amityBlue">Academics &amp; Fees</span>
            <h3 className="mt-1 text-lg font-bold text-slate-900">B.Tech CSE (2024–2028)</h3>
            <p className="mt-2 text-sm text-slate-600">
              Semester tuition fee is INR 1,86,000. Merit scholarships up to 100% are available based on Class XII aggregate and JEE Main percentile.
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <span className="text-xs font-bold uppercase tracking-wider text-amityBlue">Multilingual Support</span>
            <h3 className="mt-1 text-lg font-bold text-slate-900">6 Regional Languages</h3>
            <p className="mt-2 text-sm text-slate-600">
              Click the floating <strong>AskUni Chat</strong> button at the bottom-right corner to ask questions in your preferred language or select from Smart FAQs.
            </p>
          </div>
        </div>

        {/* Single <script> Embed Instructions */}
        <div className="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div>
              <h3 className="text-base font-bold text-slate-900">Single &lt;script&gt; Tag Website Integration</h3>
              <p className="text-xs text-slate-600">
                Embed AskUni on any departmental notice board or external college portal using one script tag.
              </p>
            </div>
            <a
              href="/embed-demo.html"
              target="_blank"
              rel="noreferrer"
              className="rounded-lg bg-slate-900 px-3 py-1.5 text-xs font-semibold text-white hover:bg-slate-800"
            >
              Open Standalone Embed Demo
            </a>
          </div>
          <pre className="mt-3 overflow-x-auto rounded-xl bg-slate-900 p-4 text-xs text-amber-300">
{`<script src="http://localhost:5000/widget/askuni-widget.js" async></script>`}
          </pre>
        </div>
      </main>
    </div>
  );
}
'@

# 14. frontend/src/pages/AdminDashboard.jsx (/admin)
Write-ProjectFile -RelativePath "frontend\src\pages\AdminDashboard.jsx" -Content @'
import React, { useEffect, useState } from 'react';
import { askUniApi } from '../services/api';

export default function AdminDashboard({ onNavigate }) {
  const [token, setToken] = useState(() => sessionStorage.getItem('askuni_admin_token') || '');
  const [username, setUsername] = useState('admin_aur');
  const [password, setPassword] = useState('Admin@123');
  const [authError, setAuthError] = useState('');

  const [tab, setTab] = useState('logs');
  const [sessions, setSessions] = useState([]);
  const [logs, setLogs] = useState([]);
  const [selectedSession, setSelectedSession] = useState(null);
  const [trending, setTrending] = useState([]);
  const [faqs, setFaqs] = useState([]);

  // Filters
  const [filterDate, setFilterDate] = useState('');
  const [filterLang, setFilterLang] = useState('all');
  const [filterKeyword, setFilterKeyword] = useState('');

  // FAQ Form
  const [editingFaqId, setEditingFaqId] = useState('');
  const [faqIdInput, setFaqIdInput] = useState('');
  const [questionInput, setQuestionInput] = useState('');
  const [answerInput, setAnswerInput] = useState('');
  const [categoryInput, setCategoryInput] = useState('Examinations');
  const [faqNotice, setFaqNotice] = useState('');
  const [faqError, setFaqError] = useState('');

  // Knowledge Upload Form
  const [docTitle, setDocTitle] = useState('');
  const [docCategory, setDocCategory] = useState('Circular');
  const [docContent, setDocContent] = useState('');
  const [docNotice, setDocNotice] = useState('');

  const loadAllAdminData = async (activeToken) => {
    try {
      const [logsRes, trendRes, faqRes] = await Promise.all([
        askUniApi.getAdminLogs(activeToken, {
          date: filterDate,
          language: filterLang,
          keyword: filterKeyword
        }),
        askUniApi.getAdminTrending(activeToken),
        askUniApi.fetchFaqs()
      ]);
      setSessions(logsRes.sessions || []);
      setLogs(logsRes.logs || []);
      setTrending(trendRes.trending || []);
      setFaqs(faqRes.faqs || []);
    } catch (err) {
      if (err.status === 401 || err.status === 403) {
        sessionStorage.removeItem('askuni_admin_token');
        setToken('');
        setAuthError(err.message);
      }
    }
  };

  useEffect(() => {
    if (token) {
      loadAllAdminData(token);
    }
  }, [token]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setAuthError('');
    try {
      const res = await askUniApi.login(username, password, 'admin_staff');
      sessionStorage.setItem('askuni_admin_token', res.token);
      setToken(res.token);
    } catch (err) {
      setAuthError(err.message || 'Unauthorized admin login');
    }
  };

  const handleLogout = () => {
    sessionStorage.removeItem('askuni_admin_token');
    setToken('');
    setSelectedSession(null);
  };

  const handleInspectSession = async (sessionId) => {
    try {
      const detail = await askUniApi.getAdminSessionDetail(token, sessionId);
      setSelectedSession(detail);
    } catch (err) {
      setFaqError(err.message);
    }
  };

  const handlePromoteLogToFaq = (logItem) => {
    setTab('faqs');
    setEditingFaqId('');
    setFaqIdInput(`faq_${Date.now().toString(36)}`.slice(0, 25));
    setQuestionInput(logItem.queryText);
    setAnswerInput(logItem.responseText.replace(/^\[.*?\]\s*/, ''));
    setCategoryInput('General');
    setFaqNotice('Pre-filled from chat log! Review and click Save Smart FAQ.');
  };

  const handleSaveFaq = async (e) => {
    e.preventDefault();
    setFaqError('');
    setFaqNotice('');

    if (!questionInput.trim() || !answerInput.trim() || !categoryInput.trim()) {
      setFaqError('Question, answer text, and category are all required.');
      return;
    }
    if (!editingFaqId && faqIdInput.trim().length > 25) {
      setFaqError('faqId must be at most 25 characters.');
      return;
    }

    try {
      if (editingFaqId) {
        await askUniApi.updateFaq(token, editingFaqId, {
          question: questionInput.trim(),
          answerText: answerInput.trim(),
          category: categoryInput.trim()
        });
        setFaqNotice(`Updated Smart FAQ '${editingFaqId}' successfully.`);
      } else {
        await askUniApi.createFaq(token, {
          faqId: faqIdInput.trim() || undefined,
          question: questionInput.trim(),
          answerText: answerInput.trim(),
          category: categoryInput.trim()
        });
        setFaqNotice('Created new Smart FAQ entry.');
      }
      setEditingFaqId('');
      setFaqIdInput('');
      setQuestionInput('');
      setAnswerInput('');
      await loadAllAdminData(token);
    } catch (err) {
      setFaqError(err.message);
    }
  };

  const handleStartEditFaq = (faq) => {
    setEditingFaqId(faq.faqId);
    setFaqIdInput(faq.faqId);
    setQuestionInput(faq.question);
    setAnswerInput(faq.answerText);
    setCategoryInput(faq.category);
    setFaqError('');
    setFaqNotice('');
  };

  const handleDeleteFaq = async (faqId) => {
    try {
      await askUniApi.deleteFaq(token, faqId);
      setFaqNotice(`Deleted Smart FAQ '${faqId}'.`);
      await loadAllAdminData(token);
    } catch (err) {
      setFaqError(err.message);
    }
  };

  const handleKnowledgeUpload = async (e) => {
    e.preventDefault();
    setDocNotice('');
    try {
      const res = await askUniApi.uploadKnowledge(token, {
        title: docTitle,
        category: docCategory,
        content: docContent
      });
      setDocNotice(`Indexed '${docTitle}' into Pinecone Vector Store (${res.chunksCreated} chunk(s)).`);
      setDocTitle('');
      setDocContent('');
    } catch (err) {
      setFaqError(err.message);
    }
  };

  if (!token) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-100 p-4">
        <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-lg">
          <div className="flex items-center justify-between">
            <span className="rounded bg-amityBlue px-2.5 py-1 text-xs font-bold text-white">ADMIN STAFF PORTAL</span>
            <button type="button" onClick={() => onNavigate('/')} className="text-xs font-semibold text-amityBlue hover:underline">
              &larr; Back to Portal
            </button>
          </div>
          <h1 className="mt-4 text-2xl font-bold text-slate-900">AskUni Admin Login</h1>
          <p className="mt-1 text-xs text-slate-500">Amity University Rajasthan — Knowledge Base &amp; Chat Log Review</p>

          <form onSubmit={handleLogin} className="mt-6 space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700">Staff Username</label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="mt-1 w-full rounded-xl border border-slate-300 px-3 py-2 text-sm"
                required
              />
            </div>
            {authError && <p className="rounded-lg bg-red-50 p-2.5 text-xs font-medium text-red-700">{authError}</p>}
            <button
              type="submit"
              className="w-full rounded-xl bg-amityBlue py-2.5 text-sm font-bold text-white hover:bg-amityDark"
            >
              Sign In as Admin Staff
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-amityBlue px-6 py-4 text-white shadow">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-lg font-bold">AskUni Admin Staff Dashboard</h1>
            <p className="text-xs text-slate-200">Chat Log Analytics, Smart FAQ CRUD &amp; Vector Knowledge Base</p>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <button type="button" onClick={() => onNavigate('/')} className="rounded-lg bg-white/15 px-3 py-1.5 font-semibold hover:bg-white/25">
              College Portal
            </button>
            <button type="button" onClick={handleLogout} className="rounded-lg bg-red-600 px-3 py-1.5 font-semibold hover:bg-red-500">
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-6 py-6">
        {/* Navigation Tabs */}
        <div className="mb-6 flex flex-wrap gap-2 border-b border-slate-200 pb-3 text-xs font-semibold">
          <button
            type="button"
            onClick={() => setTab('logs')}
            className={`rounded-lg px-4 py-2 ${tab === 'logs' ? 'bg-amityBlue text-white' : 'bg-white text-slate-700 border border-slate-200'}`}
          >
            Chat Logs ({logs.length})
          </button>
          <button
            type="button"
            onClick={() => setTab('trending')}
            className={`rounded-lg px-4 py-2 ${tab === 'trending' ? 'bg-amityBlue text-white' : 'bg-white text-slate-700 border border-slate-200'}`}
          >
            Trending Questions ({trending.length})
          </button>
          <button
            type="button"
            onClick={() => setTab('faqs')}
            className={`rounded-lg px-4 py-2 ${tab === 'faqs' ? 'bg-amityBlue text-white' : 'bg-white text-slate-700 border border-slate-200'}`}
          >
            Smart FAQs ({faqs.length})
          </button>
          <button
            type="button"
            onClick={() => setTab('knowledge')}
            className={`rounded-lg px-4 py-2 ${tab === 'knowledge' ? 'bg-amityBlue text-white' : 'bg-white text-slate-700 border border-slate-200'}`}
          >
            Upload Circular / Document
          </button>
        </div>

        {/* TAB 1: CHAT LOGS */}
        {tab === 'logs' && (
          <div className="space-y-4">
            <div className="grid gap-3 rounded-xl border border-slate-200 bg-white p-4 sm:grid-cols-4">
              <input
                type="date"
                value={filterDate}
                onChange={(e) => setFilterDate(e.target.value)}
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs"
              />
              <select
                value={filterLang}
                onChange={(e) => setFilterLang(e.target.value)}
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs"
              >
                <option value="all">All Languages</option>
                <option value="en">English (en)</option>
                <option value="hi">Hindi (hi)</option>
                <option value="mr">Marathi (mr)</option>
                <option value="ta">Tamil (ta)</option>
                <option value="bn">Bengali (bn)</option>
                <option value="pa">Punjabi (pa)</option>
              </select>
              <input
                type="text"
                placeholder="Filter by keyword..."
                value={filterKeyword}
                onChange={(e) => setFilterKeyword(e.target.value)}
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs"
              />
              <button
                type="button"
                onClick={() => loadAllAdminData(token)}
                className="rounded-lg bg-amityBlue px-4 py-1.5 text-xs font-bold text-white hover:bg-amityDark"
              >
                Apply Filters
              </button>
            </div>

            <div className="grid gap-6 lg:grid-cols-2">
              <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
                <h2 className="text-sm font-bold text-slate-900">Recent Sessions ({sessions.length})</h2>
                <div className="mt-3 divide-y divide-slate-100">
                  {sessions.map((s) => (
                    <div key={s.sessionId} className="py-3">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-mono font-semibold text-amityBlue">{s.sessionId}</span>
                        <span className="rounded bg-slate-100 px-2 py-0.5 text-[11px]">{s.language} • {s.turnCount} turn(s)</span>
                      </div>
                      <p className="mt-1 truncate text-xs text-slate-700">{s.latestQuery}</p>
                      <div className="mt-2 flex items-center justify-between">
                        <span className="text-[11px] text-slate-400">{new Date(s.lastTimestamp).toLocaleString()}</span>
                        <button
                          type="button"
                          onClick={() => handleInspectSession(s.sessionId)}
                          className="text-xs font-semibold text-amityBlue hover:underline"
                        >
                          Inspect Session &rarr;
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
                <h2 className="text-sm font-bold text-slate-900">Session Transcript &amp; FAQ Promotion</h2>
                {selectedSession ? (
                  <div className="mt-3 space-y-3">
                    <p className="font-mono text-xs text-slate-500">Session: {selectedSession.sessionId}</p>
                    {(selectedSession.logs || []).map((entry) => (
                      <div key={entry.logId} className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-xs">
                        <p className="font-semibold text-slate-900">Q: {entry.queryText}</p>
                        <p className="mt-1 text-slate-700">A: {entry.responseText}</p>
                        <div className="mt-2 flex items-center justify-between">
                          <span className="text-[11px] text-slate-400">{new Date(entry.timestamp).toLocaleString()}</span>
                          <button
                            type="button"
                            onClick={() => handlePromoteLogToFaq(entry)}
                            className="rounded bg-amityGold px-2.5 py-1 text-[11px] font-bold text-slate-950 hover:bg-amber-400"
                          >
                            + Add to FAQ
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="mt-4 text-xs text-slate-500">Select a session on the left to inspect queries, responses, timestamps, or promote an entry to Smart FAQs.</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: TRENDING QUESTIONS */}
        {tab === 'trending' && (
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="text-base font-bold text-slate-900">Recurring &amp; Trending Student Questions</h2>
            <div className="mt-4 divide-y divide-slate-100">
              {trending.map((item, idx) => (
                <div key={idx} className="flex flex-wrap items-center justify-between gap-4 py-3 text-xs">
                  <div>
                    <p className="font-semibold text-slate-900">{item.question}</p>
                    <p className="mt-0.5 text-slate-500">Last asked: {new Date(item.lastAsked).toLocaleString()}</p>
                  </div>
                  <span className="rounded-full bg-amityBlue px-3 py-1 font-bold text-white">
                    {item.count}x asked
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 3: SMART FAQ CRUD */}
        {tab === 'faqs' && (
          <div className="grid gap-6 lg:grid-cols-3">
            <form onSubmit={handleSaveFaq} className="space-y-3 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <h2 className="text-sm font-bold text-slate-900">
                {editingFaqId ? `Edit Smart FAQ (${editingFaqId})` : 'Add New Smart FAQ'}
              </h2>
              <div>
                <label className="block text-xs font-semibold text-slate-700">FAQ ID (max 25 chars)</label>
                <input
                  type="text"
                  maxLength={25}
                  disabled={Boolean(editingFaqId)}
                  value={faqIdInput}
                  onChange={(e) => setFaqIdInput(e.target.value)}
                  placeholder="auto-generated if blank"
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs disabled:bg-slate-100"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700">Category *</label>
                <input
                  type="text"
                  value={categoryInput}
                  onChange={(e) => setCategoryInput(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs"
                  required
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700">Question *</label>
                <input
                  type="text"
                  value={questionInput}
                  onChange={(e) => setQuestionInput(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs"
                  required
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700">Official Answer *</label>
                <textarea
                  rows={4}
                  value={answerInput}
                  onChange={(e) => setAnswerInput(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs"
                  required
                />
              </div>
              {faqError && <p className="text-xs font-medium text-red-600">{faqError}</p>}
              {faqNotice && <p className="text-xs font-medium text-emerald-700">{faqNotice}</p>}
              <div className="flex gap-2">
                <button type="submit" className="flex-1 rounded-lg bg-amityBlue py-2 text-xs font-bold text-white hover:bg-amityDark">
                  {editingFaqId ? 'Update FAQ' : 'Save Smart FAQ'}
                </button>
                {editingFaqId && (
                  <button
                    type="button"
                    onClick={() => {
                      setEditingFaqId('');
                      setFaqIdInput('');
                      setQuestionInput('');
                      setAnswerInput('');
                    }}
                    className="rounded-lg border border-slate-300 px-3 py-2 text-xs font-semibold"
                  >
                    Cancel
                  </button>
                )}
              </div>
            </form>

            <div className="space-y-3 lg:col-span-2">
              {faqs.map((faq) => (
                <div key={faq.faqId} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <span className="rounded bg-amber-100 px-2 py-0.5 text-[11px] font-bold text-amber-900">
                      {faq.category} • {faq.faqId}
                    </span>
                    <div className="flex gap-2 text-xs">
                      <button type="button" onClick={() => handleStartEditFaq(faq)} className="font-semibold text-amityBlue hover:underline">
                        Edit
                      </button>
                      <button type="button" onClick={() => handleDeleteFaq(faq.faqId)} className="font-semibold text-red-600 hover:underline">
                        Delete
                      </button>
                    </div>
                  </div>
                  <h3 className="mt-1.5 text-sm font-bold text-slate-900">{faq.question}</h3>
                  <p className="mt-1 text-xs text-slate-600">{faq.answerText}</p>
                  <p className="mt-2 text-[10px] text-slate-400">Last updated: {new Date(faq.lastUpdated).toLocaleString()}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 4: KNOWLEDGE BASE UPLOAD */}
        {tab === 'knowledge' && (
          <form onSubmit={handleKnowledgeUpload} className="max-w-2xl space-y-4 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="text-base font-bold text-slate-900">Ingest Institutional Circular / Notice into Vector DB</h2>
            <div>
              <label className="block text-xs font-semibold text-slate-700">Document Title *</label>
              <input
                type="text"
                value={docTitle}
                onChange={(e) => setDocTitle(e.target.value)}
                placeholder="e.g., Circular AUR/2026/199 - Winter Internship Guidelines"
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-xs"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700">Category *</label>
              <input
                type="text"
                value={docCategory}
                onChange={(e) => setDocCategory(e.target.value)}
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-xs"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700">Extracted Text / Notice Body *</label>
              <textarea
                rows={6}
                value={docContent}
                onChange={(e) => setDocContent(e.target.value)}
                placeholder="Paste circular, timetable, or fee notification text here to chunk, embed, and index..."
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-xs"
                required
              />
            </div>
            {docNotice && <p className="rounded-lg bg-emerald-50 p-3 text-xs font-semibold text-emerald-800">{docNotice}</p>}
            <button type="submit" className="rounded-xl bg-amityBlue px-5 py-2.5 text-xs font-bold text-white hover:bg-amityDark">
              Chunk, Embed &amp; Upsert Document
            </button>
          </form>
        )}
      </main>
    </div>
  );
}
'@

# 15. frontend/src/pages/SysAdminPanel.jsx (/sysadmin)
Write-ProjectFile -RelativePath "frontend\src\pages\SysAdminPanel.jsx" -Content @'
import React, { useEffect, useState } from 'react';
import { askUniApi } from '../services/api';

export default function SysAdminPanel({ onNavigate }) {
  const [token, setToken] = useState(() => sessionStorage.getItem('askuni_sysadmin_token') || '');
  const [username, setUsername] = useState('sysadmin_aur');
  const [password, setPassword] = useState('SysAdmin@123');
  const [authError, setAuthError] = useState('');

  const [health, setHealth] = useState(null);
  const [services, setServices] = useState([]);
  const [securityMeta, setSecurityMeta] = useState(null);
  const [rateLimitMax, setRateLimitMax] = useState(120);
  const [languagesText, setLanguagesText] = useState('en, hi, mr, ta, bn, pa');
  const [statusMessage, setStatusMessage] = useState('');
  const [configError, setConfigError] = useState('');

  const refreshTelemetry = async (activeToken) => {
    try {
      const [hRes, sRes] = await Promise.all([
        askUniApi.getSysAdminHealth(activeToken),
        askUniApi.getSysAdminServices(activeToken)
      ]);
      setHealth(hRes.health);
      setServices(sRes.services || []);
      setSecurityMeta(sRes.security || null);
      if (hRes.health?.rateLimits?.maxRequests) {
        setRateLimitMax(hRes.health.rateLimits.maxRequests);
      }
      const transCfg = (sRes.services || []).find((s) => s.configId === 'AI_TRANSLATION_SERVICE');
      if (transCfg && Array.isArray(transCfg.supportedLanguages)) {
        setLanguagesText(transCfg.supportedLanguages.join(', '));
      }
    } catch (err) {
      if (err.status === 401 || err.status === 403) {
        sessionStorage.removeItem('askuni_sysadmin_token');
        setToken('');
        setAuthError(err.message);
      }
    }
  };

  useEffect(() => {
    if (token) {
      refreshTelemetry(token);
    }
  }, [token]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setAuthError('');
    try {
      const res = await askUniApi.login(username, password, 'system_admin');
      sessionStorage.setItem('askuni_sysadmin_token', res.token);
      setToken(res.token);
    } catch (err) {
      setAuthError(err.message || 'System Administrator login failed');
    }
  };

  const handleRenewSecret = async () => {
    setStatusMessage('');
    setConfigError('');
    try {
      const res = await askUniApi.renewCredentials(token);
      setStatusMessage(`${res.message} Incident state machine cycled back to: ${res.incidentState}. Please sign in again if token invalidates.`);
      await refreshTelemetry(token);
    } catch (err) {
      setConfigError(err.message);
    }
  };

  const handleSaveConfig = async (e) => {
    e.preventDefault();
    setStatusMessage('');
    setConfigError('');
    try {
      const langs = languagesText
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .filter(Boolean);

      await askUniApi.updateSysConfig(token, {
        adminId: 'sysadmin_aur_01',
        rateLimitMax: Number(rateLimitMax),
        supportedLanguages: langs
      });
      setStatusMessage('System configuration & rate limits saved.');
      await refreshTelemetry(token);
    } catch (err) {
      setConfigError(err.message);
    }
  };

  if (!token) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-900 p-4">
        <div className="w-full max-w-md rounded-2xl border border-slate-700 bg-slate-800 p-8 text-white shadow-2xl">
          <div className="flex items-center justify-between">
            <span className="rounded bg-amityGold px-2.5 py-1 text-xs font-bold text-slate-950">INFRASTRUCTURE OPS</span>
            <button type="button" onClick={() => onNavigate('/')} className="text-xs text-amber-300 hover:underline">
              &larr; Student Portal
            </button>
          </div>
          <h1 className="mt-4 text-2xl font-bold">System Administrator Login</h1>
          <p className="mt-1 text-xs text-slate-400">Server Telemetry, Rate-Limit Guardrails &amp; JWT Key Rotation</p>

          <form onSubmit={handleLogin} className="mt-6 space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300">SysAdmin Username</label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="mt-1 w-full rounded-xl border border-slate-600 bg-slate-900 px-3 py-2 text-sm text-white"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-300">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="mt-1 w-full rounded-xl border border-slate-600 bg-slate-900 px-3 py-2 text-sm text-white"
                required
              />
            </div>
            {authError && <p className="rounded-lg bg-red-950/80 p-2.5 text-xs text-red-300">{authError}</p>}
            <button type="submit" className="w-full rounded-xl bg-amityGold py-2.5 text-sm font-bold text-slate-950 hover:bg-amber-400">
              Authenticate System Admin
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <header className="border-b border-slate-800 bg-slate-900 px-6 py-4">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-lg font-bold text-white">AskUni System Administrator Console (/sysadmin)</h1>
            <p className="text-xs text-slate-400">
              Incident State Machine: <strong className="text-emerald-400">{health?.incidentState || 'Healthy'}</strong>
            </p>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <button type="button" onClick={() => refreshTelemetry(token)} className="rounded-lg bg-slate-800 px-3 py-1.5 font-semibold hover:bg-slate-700">
              Refresh Metrics
            </button>
            <button type="button" onClick={() => onNavigate('/')} className="rounded-lg bg-slate-800 px-3 py-1.5 font-semibold hover:bg-slate-700">
              Portal
            </button>
            <button
              type="button"
              onClick={() => {
                sessionStorage.removeItem('askuni_sysadmin_token');
                setToken('');
              }}
              className="rounded-lg bg-red-600 px-3 py-1.5 font-semibold text-white hover:bg-red-500"
            >
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl space-y-6 px-6 py-6">
        {statusMessage && (
          <div className="rounded-xl border border-emerald-700 bg-emerald-950/70 p-3 text-xs text-emerald-300">
            {statusMessage}
          </div>
        )}
        {configError && (
          <div className="rounded-xl border border-red-700 bg-red-950/70 p-3 text-xs text-red-300">
            {configError}
          </div>
        )}

        {/* Health & External API Availability Cards */}
        {health && (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="rounded-2xl border border-slate-800 bg-slate-900 p-4">
              <p className="text-xs text-slate-400">Server Status &amp; Uptime</p>
              <p className="mt-1 text-xl font-bold uppercase text-emerald-400">{health.status}</p>
              <p className="mt-1 text-xs text-slate-400">Uptime: {health.uptimeSeconds}s • RSS: {health.memory?.rssMb} MB</p>
            </div>

            <div className="rounded-2xl border border-slate-800 bg-slate-900 p-4">
              <p className="text-xs text-slate-400">MongoDB Repository</p>
              <p className="mt-1 text-xl font-bold text-emerald-400">{health.database?.connected ? 'Connected' : 'Offline'}</p>
              <p className="mt-1 truncate text-xs text-slate-400">{health.database?.mode}</p>
            </div>

            <div className="rounded-2xl border border-slate-800 bg-slate-900 p-4">
              <p className="text-xs text-slate-400">External AI &amp; Vector APIs</p>
              <p className="mt-1 text-xs text-slate-200">OpenAI GPT-4: <strong className="text-emerald-400">{health.externalServices?.openai?.available ? 'UP' : 'DOWN'}</strong></p>
              <p className="text-xs text-slate-200">Pinecone Vector: <strong className="text-emerald-400">{health.externalServices?.pinecone?.available ? 'UP' : 'DOWN'}</strong></p>
              <p className="text-xs text-slate-200">Google Translate: <strong className="text-emerald-400">{health.externalServices?.googleTranslate?.available ? 'UP' : 'DOWN'}</strong></p>
            </div>

            <div className="rounded-2xl border border-slate-800 bg-slate-900 p-4">
              <p className="text-xs text-slate-400">API Rate-Limit Meter</p>
              <p className="mt-1 text-xl font-bold text-amber-400">
                {health.rateLimits?.totalRequestsObserved} / {health.rateLimits?.maxRequests}
              </p>
              <p className="mt-1 text-xs text-slate-400">429 Blocked: {health.rateLimits?.blocked429Count}</p>
            </div>
          </div>
        )}

        {/* Credential Rotation & Config Editor */}
        <div className="grid gap-6 lg:grid-cols-2">
          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
            <h2 className="text-sm font-bold text-white">JWT Credential Security &amp; Secret Rotation</h2>
            <p className="mt-1 text-xs text-slate-400">
              Signing keys are strictly masked in all UI views and server logs.
            </p>
            <div className="mt-4 rounded-xl border border-slate-800 bg-slate-950 p-3 text-xs space-y-1">
              <p>Algorithm: <span className="font-mono text-amber-300">{securityMeta?.algorithm || 'HS256'}</span></p>
              <p>Token Secret: <span className="font-mono text-emerald-400">{securityMeta?.tokenSecret || '***MASKED***'}</span></p>
              <p>Rotations Performed: <span className="font-mono text-slate-200">{securityMeta?.rotationCount ?? 0}</span></p>
            </div>
            <button
              type="button"
              onClick={handleRenewSecret}
              className="mt-4 rounded-xl bg-amityGold px-4 py-2 text-xs font-bold text-slate-950 hover:bg-amber-400"
            >
              Rotate JWT Signing Secret
            </button>
          </div>

          <form onSubmit={handleSaveConfig} className="space-y-3 rounded-2xl border border-slate-800 bg-slate-900 p-5">
            <h2 className="text-sm font-bold text-white">Rate-Limit &amp; Multilingual Config</h2>
            <div>
              <label className="block text-xs text-slate-300">Max Requests per Window</label>
              <input
                type="number"
                min={1}
                max={10000}
                value={rateLimitMax}
                onChange={(e) => setRateLimitMax(e.target.value)}
                className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-1.5 text-xs text-white"
              />
            </div>
            <div>
              <label className="block text-xs text-slate-300">Supported Language Codes (comma-separated)</label>
              <input
                type="text"
                value={languagesText}
                onChange={(e) => setLanguagesText(e.target.value)}
                className="mt-1 w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-1.5 text-xs text-white"
              />
            </div>
            <button type="submit" className="rounded-xl bg-emerald-500 px-4 py-2 text-xs font-bold text-slate-950 hover:bg-emerald-400">
              Save System Configuration
            </button>
          </form>
        </div>

        {/* Service Registry Table */}
        <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
          <h2 className="text-sm font-bold text-white">Service Architecture Registry</h2>
          <div className="mt-3 overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-slate-800 text-slate-400">
                <tr>
                  <th className="py-2">Service ID</th>
                  <th className="py-2">Endpoint / Index</th>
                  <th className="py-2">Secret Status</th>
                  <th className="py-2">Updated</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {services.map((svc) => (
                  <tr key={svc.configId}>
                    <td className="py-2 font-mono font-semibold text-amber-300">{svc.configId}</td>
                    <td className="py-2 text-slate-300">{svc.apiEndpoint || svc.indexName || svc.dbUri}</td>
                    <td className="py-2 font-mono text-emerald-400">{svc.maskedSecretHint}</td>
                    <td className="py-2 text-slate-400">{new Date(svc.updatedAt).toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}
'@

# 16. frontend/src/App.jsx
Write-ProjectFile -RelativePath "frontend\src\App.jsx" -Content @'
import React, { useEffect, useState } from 'react';
import CollegeLandingPage from './components/CollegeLandingPage';
import WidgetContainer from './components/WidgetContainer';
import AdminDashboard from './pages/AdminDashboard';
import SysAdminPanel from './pages/SysAdminPanel';

export default function App() {
  const [route, setRoute] = useState(() => window.location.pathname || '/');

  useEffect(() => {
    const onPop = () => setRoute(window.location.pathname || '/');
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);

  const navigate = (path) => {
    window.history.pushState({}, '', path);
    setRoute(path);
  };

  if (route === '/admin') {
    return <AdminDashboard onNavigate={navigate} />;
  }

  if (route === '/sysadmin') {
    return <SysAdminPanel onNavigate={navigate} />;
  }

  return (
    <>
      <CollegeLandingPage onNavigate={navigate} />
      <WidgetContainer />
    </>
  );
}
'@

# 17. frontend/src/main.jsx
Write-ProjectFile -RelativePath "frontend\src\main.jsx" -Content @'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
'@

# 18. frontend/src/embed.jsx (Standalone embed entry point)
Write-ProjectFile -RelativePath "frontend\src\embed.jsx" -Content @'
import React from 'react';
import ReactDOM from 'react-dom/client';
import WidgetContainer from './components/WidgetContainer';
import './index.css';

(function mountAskUniWidget() {
  if (typeof document === 'undefined') return;
  if (document.getElementById('askuni-widget-embed-root')) return;
  const container = document.createElement('div');
  container.id = 'askuni-widget-embed-root';
  document.body.appendChild(container);
  ReactDOM.createRoot(container).render(<WidgetContainer />);
})();
'@

# 19. frontend/src/tests/setup.js
Write-ProjectFile -RelativePath "frontend\src\tests\setup.js" -Content @'
import '@testing-library/jest-dom';
'@

# 20. frontend/src/tests/widget.test.jsx (12 automated frontend test cases: TC-01 through TC-12)
Write-ProjectFile -RelativePath "frontend\src\tests\widget.test.jsx" -Content @'
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, test, expect, vi, beforeEach } from 'vitest';
import WidgetContainer from '../components/WidgetContainer';
import { askUniApi } from '../services/api';

vi.mock('../services/api', () => ({
  askUniApi: {
    createAnonymousSession: vi.fn(),
    login: vi.fn(),
    fetchFaqs: vi.fn(),
    sendQuery: vi.fn()
  }
}));

const MOCK_FAQS = [
  {
    faqId: 'faq_exam_01',
    category: 'Examinations',
    question: 'When do Odd Semester End-Term Examinations begin?',
    answerText: 'Odd Semester End-Term Theory Examinations begin on December 4, 2026.'
  },
  {
    faqId: 'faq_fee_01',
    category: 'Fees & Finance',
    question: 'What is the annual tuition fee for B.Tech CSE?',
    answerText: 'Tuition fee is INR 1,86,000 per semester.'
  }
];

beforeEach(() => {
  vi.clearAllMocks();
  askUniApi.fetchFaqs.mockResolvedValue({ success: true, faqs: MOCK_FAQS });
  askUniApi.createAnonymousSession.mockResolvedValue({
    success: true,
    token: 'mock_anon_jwt',
    sessionId: 'sess_frontend_101',
    user: { userId: 'anon_user_1', widgetId: 'w_anon_user_1', role: 'anonymous' }
  });
});

describe('Module 1: Frontend AskUni Widget Interactions (TC-01 to TC-12)', () => {
  test('TC-01 opens chatbot dialog when floating launcher button is clicked', async () => {
    render(<WidgetContainer />);
    const launcher = screen.getByTestId('askuni-launcher');
    expect(launcher).toBeInTheDocument();

    fireEvent.click(launcher);
    await waitFor(() => {
      expect(screen.getByTestId('askuni-dialog')).toBeInTheDocument();
    });
  });

  test('TC-02 initializes widget state to awaiting input and loads Smart FAQs', async () => {
    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));

    await waitFor(() => {
      expect(screen.getByTestId('widget-state-badge')).toHaveTextContent('awaiting input');
      expect(askUniApi.fetchFaqs).toHaveBeenCalled();
    });
  });

  test('TC-03 submits valid English query and transitions to response displayed', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_01',
        sessionId: 'sess_frontend_101',
        generatedText: 'Tuition fee is INR 1,86,000 per semester.',
        translatedText: 'Tuition fee is INR 1,86,000 per semester.',
        targetLanguage: 'en',
        grounded: true,
        sources: [{ source: 'SmartFAQ', category: 'Fees & Finance' }],
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), {
      target: { value: 'What is the B.Tech CSE tuition fee?' }
    });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getByText(/1,86,000 per semester/i)).toBeInTheDocument();
      expect(screen.getByTestId('widget-state-badge')).toHaveTextContent('response displayed');
    });
  });

  test('TC-04 blocks empty or whitespace-only queries with visible validation message', async () => {
    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: '    ' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    expect(screen.getByTestId('validation-error')).toHaveTextContent(/empty or whitespace/i);
    expect(askUniApi.sendQuery).not.toHaveBeenCalled();
  });

  test('TC-05 submits Hindi query and displays localized Hindi assistant response', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_hi_01',
        sessionId: 'sess_frontend_101',
        generatedText: 'Theory exams start Dec 4, 2026.',
        translatedText: '[हिन्दी अनुवाद] सेमेस्टर अंत सिद्धांत परीक्षाएं 4 दिसंबर 2026 से शुरू होंगी।',
        targetLanguage: 'hi',
        grounded: true,
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'परीक्षा कब शुरू होगी?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getByText(/हिन्दी अनुवाद/i)).toBeInTheDocument();
    });
  });

  test('TC-06 selects a question from Smart FAQ dropdown and submits it immediately', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_faq_01',
        sessionId: 'sess_frontend_101',
        translatedText: 'Odd Semester End-Term Theory Examinations begin on December 4, 2026.',
        targetLanguage: 'en',
        grounded: true,
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('smart-faq-dropdown')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('smart-faq-dropdown'), {
      target: { value: 'When do Odd Semester End-Term Examinations begin?' }
    });

    await waitFor(() => {
      expect(askUniApi.sendQuery).toHaveBeenCalledTimes(1);
      expect(screen.getByText(/December 4, 2026/i)).toBeInTheDocument();
    });
  });

  test('TC-07 displays formatted ChatbotResponse with source attribution badges and timestamps', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_fmt_07',
        sessionId: 'sess_frontend_101',
        translatedText: 'BCS 522 Lab is held in Block-B Lab-204.',
        targetLanguage: 'en',
        grounded: true,
        sources: [{ source: 'PineconeVectorDB', category: 'Timetable & Labs' }],
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Where is BCS 522 lab?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getByText(/PineconeVectorDB: Timetable & Labs/i)).toBeInTheDocument();
      expect(screen.getByText(/AskUni \(en\)/i)).toBeInTheDocument();
    });
  });

  test('TC-08 switches preferredLanguage selector and requests translation in target language', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_mr_08',
        sessionId: 'sess_frontend_101',
        translatedText: '[\u092e\u0930\u093e\u0920\u0940 \u092d\u093e\u0937\u093e\u0902\u0924\u0930] \u0935\u0938\u0924\u093f\u0917\u0943\u0939 \u0936\u0941\u0932\u094d\u0915 INR 1,10,000 \u092a\u094d\u0930\u0924\u093f \u0935\u0930\u094d\u0937 \u0906\u0939\u0947.',
        targetLanguage: 'mr',
        grounded: true,
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('language-selector')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('language-selector'), { target: { value: 'mr' } });
    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Hostel fee?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(askUniApi.sendQuery).toHaveBeenCalledWith(
        expect.objectContaining({ language: 'mr' }),
        expect.any(String)
      );
      expect(screen.getByText(/\u092e\u0930\u093e\u0920\u0940 \u092d\u093e\u0937\u093e\u0902\u0924\u0930/i)).toBeInTheDocument();
    });
  });

  test('TC-09 maintains same sessionId across multiple consecutive turns in a conversation', async () => {
    askUniApi.sendQuery
      .mockResolvedValueOnce({
        success: true,
        data: { responseId: 'rs_t1', sessionId: 'sess_frontend_101', translatedText: 'Turn 1 answer', targetLanguage: 'en' }
      })
      .mockResolvedValueOnce({
        success: true,
        data: { responseId: 'rs_t2', sessionId: 'sess_frontend_101', translatedText: 'Turn 2 answer', targetLanguage: 'en' }
      });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'First question' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));
    await waitFor(() => expect(screen.getByText('Turn 1 answer')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Second question' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));
    await waitFor(() => expect(screen.getByText('Turn 2 answer')).toBeInTheDocument());

    expect(askUniApi.sendQuery.mock.calls[0][0].sessionId).toBe('sess_frontend_101');
    expect(askUniApi.sendQuery.mock.calls[1][0].sessionId).toBe('sess_frontend_101');
  });

  test('TC-10 minimizes and closes the chatbot widget cleanly', async () => {
    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('askuni-dialog')).toBeInTheDocument());

    fireEvent.click(screen.getByTestId('askuni-minimize'));
    expect(screen.queryByTestId('askuni-dialog')).not.toBeInTheDocument();
    expect(screen.getByTestId('askuni-launcher')).toHaveTextContent('Resume AskUni');

    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('askuni-dialog')).toBeInTheDocument());

    fireEvent.click(screen.getByTestId('askuni-close'));
    expect(screen.queryByTestId('askuni-dialog')).not.toBeInTheDocument();
    expect(screen.getByTestId('askuni-launcher')).toHaveTextContent('AskUni Chat');
  });

  test('TC-11 records both user and assistant messages in the conversation log', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_hist_11',
        sessionId: 'sess_frontend_101',
        translatedText: 'Anti-ragging helpline is 1800-180-5522.',
        targetLanguage: 'en'
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Anti ragging helpline?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getAllByTestId('chat-bubble-user')).toHaveLength(1);
      expect(screen.getAllByTestId('chat-bubble-assistant')).toHaveLength(1);
    });
  });

  test('TC-12 authenticates optional student login session while preserving anonymous fallback', async () => {
    askUniApi.login.mockResolvedValueOnce({
      success: true,
      token: 'stu_jwt_token',
      sessionId: 'sess_student_aarav',
      user: {
        userId: 'stu_a50105224001',
        widgetId: 'w_stu_a50105224001',
        name: 'Aarav Verma',
        enrollmentNo: 'A50105224001',
        program: 'B.Tech CSE'
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByText('Student Login')).toBeInTheDocument());

    fireEvent.click(screen.getByText('Student Login'));
    fireEvent.click(screen.getByText('Authenticate Student Session'));

    await waitFor(() => {
      expect(screen.getByText(/Signed in: Aarav Verma/i)).toBeInTheDocument();
    });
  });
});
'@

# Install frontend dependencies and build embeddable widget bundle
Write-Step "Installing frontend npm dependencies"
$frontendDir = Join-Path $RootDir "frontend"
Push-Location $frontendDir
try {
    & npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed in $frontendDir with exit code $LASTEXITCODE"
    }

    Write-Step "Building standalone embeddable widget bundle (askuni-widget.iife.js)"
    & npm run build:embed
    if ($LASTEXITCODE -ne 0) {
        throw "npm run build:embed failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Ok "Frontend widget, demo page, /admin, and /sysadmin scaffolded successfully! Proceed to 03-seed-and-test.ps1."
exit 0