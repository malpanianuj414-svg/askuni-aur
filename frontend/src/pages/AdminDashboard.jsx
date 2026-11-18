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
          <p className="mt-1 text-xs text-slate-500">Amity University Rajasthan â€” Knowledge Base &amp; Chat Log Review</p>

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
                        <span className="rounded bg-slate-100 px-2 py-0.5 text-[11px]">{s.language} â€¢ {s.turnCount} turn(s)</span>
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
                      {faq.category} â€¢ {faq.faqId}
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