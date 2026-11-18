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
              <p className="mt-1 text-xs text-slate-400">Uptime: {health.uptimeSeconds}s â€¢ RSS: {health.memory?.rssMb} MB</p>
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