# 05-unify-and-build.ps1
# Configures AskUni to run as a single unified web application on one URL/port (http://localhost:5000).
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

# 1. Update frontend/src/services/api.js so it works on any single domain or port automatically
Write-Step "Updating frontend API base resolver for single-origin deployment"
$apiJsPath = Join-Path $RootDir "frontend\src\services\api.js"
$apiJsContent = @'
const getApiBase = () => {
  if (typeof window !== 'undefined') {
    if (window.ASKUNI_API_BASE) {
      return window.ASKUNI_API_BASE;
    }
    if (window.location && window.location.port === '5173') {
      return 'http://localhost:5000/api';
    }
    if (window.location && window.location.origin && window.location.origin.startsWith('http')) {
      return `${window.location.origin}/api`;
    }
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
[System.IO.File]::WriteAllText($apiJsPath, $apiJsContent, $utf8NoBom)

# 2. Update frontend/public/embed-demo.html to use relative same-origin paths
Write-Step "Updating embed-demo.html for single-origin hosting"
$embedDemoPath = Join-Path $RootDir "frontend\public\embed-demo.html"
$embedDemoContent = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>External Campus Portal - Single &lt;script&gt; Embed Demo</title>
    <style>
      body { font-family: system-ui, -apple-system, sans-serif; margin: 0; background: #f1f5f9; color: #0f172a; }
      header { background: #003366; color: #fff; padding: 24px 32px; }
      main { max-width: 820px; margin: 32px auto; background: #fff; padding: 28px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.06); }
      pre { background: #0f172a; color: #f8fafc; padding: 14px; border-radius: 8px; overflow-x: auto; font-size: 13px; }
    </style>
  </head>
  <body>
    <header>
      <h1 style="margin:0;">Amity School of Engineering &amp; Technology - Student Notice Portal</h1>
      <p style="margin:6px 0 0; opacity:0.85;">Demonstrating single &lt;script&gt; tag embedding of AskUni Widget</p>
    </header>
    <main>
      <h2>How Any University Web Page Embeds AskUni</h2>
      <p>Add the following script snippet before the closing <code>&lt;/body&gt;</code> tag:</p>
      <pre id="embed-snippet"></pre>
      <p>Click the floating <strong>AskUni Chat</strong> button in the bottom-right corner to test live multilingual queries.</p>
    </main>
    <script>
      var origin = window.location.origin;
      window.ASKUNI_API_BASE = origin + "/api";
      document.getElementById("embed-snippet").textContent =
        '<script>window.ASKUNI_API_BASE = "' + origin + '/api";<\/script>\n' +
        '<script src="' + origin + '/widget/askuni-widget.js" async><\/script>';
    </script>
    <script src="/widget/askuni-widget.js" async></script>
  </body>
</html>
'@
[System.IO.File]::WriteAllText($embedDemoPath, $embedDemoContent, $utf8NoBom)

# 3. Update backend/src/app.js to serve frontend/dist + SPA fallback for /admin and /sysadmin
Write-Step "Configuring Express backend to serve built frontend SPA on single port"
$appJsPath = Join-Path $RootDir "backend\src\app.js"
$appJs = [System.IO.File]::ReadAllText($appJsPath)

if (-not $appJs.Contains("frontendDist")) {
    $spaBlock = @'
  // Serve compiled React SPA & static assets on the same unified URL
  const frontendDist = path.resolve(__dirname, '../../frontend/dist');
  if (fs.existsSync(frontendDist)) {
    app.use(express.static(frontendDist));
    app.get('*', (req, res, next) => {
      if (req.path.startsWith('/api/') || req.path.startsWith('/widget/')) {
        return next();
      }
      return res.sendFile(path.join(frontendDist, 'index.html'));
    });
  }

  app.use(errorHandler);
'@
    $appJs = $appJs.Replace("  app.use(errorHandler);", $spaBlock)
    [System.IO.File]::WriteAllText($appJsPath, $appJs, $utf8NoBom)
}

# 4. Build production frontend + embeddable widget bundle
Write-Step "Building production React SPA and embeddable widget bundle"
$frontendDir = Join-Path $RootDir "frontend"
Push-Location $frontendDir
try {
    & npm run build
    if ($LASTEXITCODE -ne 0) { throw "Frontend build failed with exit code $LASTEXITCODE" }

    & npm run build:embed
    if ($LASTEXITCODE -ne 0) { throw "Embed widget build failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}
Write-Ok "Production SPA and askuni-widget.iife.js compiled into frontend\dist."

# 5. Stop any old processes on ports 5000/5173 and launch the single unified server
Write-Step "Launching Unified AskUni Server on http://localhost:5000"
foreach ($port in @(5000, 5173)) {
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
    catch { }
}

$backendDir = Join-Path $RootDir "backend"
$psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
$serverCmd = "Set-Location '$backendDir'; `$Host.UI.RawUI.WindowTitle = 'AskUni Unified Web App (Port 5000)'; npm start"
Start-Process -FilePath $psExe -ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $serverCmd) | Out-Null

$healthUrl = "http://localhost:5000/api/health"
$ready = $false
for ($i = 1; $i -le 25; $i++) {
    try {
        $resp = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 2
        if ($null -ne $resp -and $resp.success -eq $true) {
            $ready = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    throw "Unified server did not respond on http://localhost:5000/api/health"
}

Write-Ok "Unified AskUni Website is live on a single URL: http://localhost:5000"
Start-Process "http://localhost:5000"
exit 0