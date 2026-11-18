import React from 'react';

export default function CollegeLandingPage({ onNavigate }) {
  return (
    <div className="min-h-screen bg-slate-50">
      {/* Top Institution Bar */}
      <header className="bg-amityBlue text-white shadow-md">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-6 py-4">
          <div>
            <span className="rounded bg-amityGold px-2 py-0.5 text-[11px] font-bold uppercase tracking-wider text-slate-950">
              Amity University Rajasthan â€¢ Jaipur
            </span>
            <h1 className="mt-1 text-xl font-bold tracking-tight sm:text-2xl">
              Amity School of Engineering &amp; Technology (ASET)
            </h1>
            <p className="text-xs text-slate-200">
              B.Tech Computer Science &amp; Engineering â€¢ Software Engineering Lab (BCS 522)
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
              Practical &amp; Lab Viva-Voce (including BCS 522) run Nov 23â€“30, 2026. Theory End-Term Examinations commence December 4, 2026.
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <span className="text-xs font-bold uppercase tracking-wider text-amityBlue">Academics &amp; Fees</span>
            <h3 className="mt-1 text-lg font-bold text-slate-900">B.Tech CSE (2024â€“2028)</h3>
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