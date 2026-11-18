import React, { useEffect, useRef, useState } from 'react';
import { ChatbotWidget, WIDGET_STATES } from '../models/ChatbotWidget';
import { askUniApi } from '../services/api';

const LANGUAGE_OPTIONS = [
  { code: 'auto', label: 'Auto-Detect' },
  { code: 'en', label: 'English' },
  { code: 'hi', label: 'à¤¹à¤¿à¤¨à¥à¤¦à¥€ (Hindi)' },
  { code: 'mr', label: 'à¤®à¤°à¤¾à¤ à¥€ (Marathi)' },
  { code: 'ta', label: 'à®¤à®®à®¿à®´à¯ (Tamil)' },
  { code: 'bn', label: 'à¦¬à¦¾à¦‚à¦²à¦¾ (Bengali)' },
  { code: 'pa', label: 'à¨ªà©°à¨œà¨¾à¨¬à©€ (Punjabi)' }
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
                  <h2 className="text-sm font-bold tracking-wide">AskUni â€” Amity Rajasthan</h2>
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
                  âœ•
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
                  {msg.role === 'user' ? 'You' : `AskUni (${msg.language || 'en'})`} â€¢ {msg.formattedTime}
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