# AskUni -- Language-Agnostic Institutional AI Chatbot Widget

**Institution:** Amity University Rajasthan (Jaipur) -- Amity School of Engineering & Technology (ASET)  
**Course:** B.Tech Computer Science & Engineering -- Software Engineering Lab (**BCS 522**)  
**Developer:** Anuj Malpani  

---

## 1. Project Overview

**AskUni** is an embeddable, multilingual AI chatbot widget and institutional knowledge management platform designed for university websites. It enables prospective applicants, parents, and enrolled students to get instant, verified answers on semester examinations, B.Tech CSE timetables, fee structures, hostel regulations, and merit scholarships without hallucination.

The repository is structured as a unified single-origin application (`frontend/dist` + Express REST API + Vercel Serverless adapter) supporting both **Windows-friendly Mock Mode (`MOCK_MODE=true`)** for zero-dependency execution and **Live Cloud Mode (`MOCK_MODE=false`)** for OpenAI GPT-4, Pinecone Vector DB, MongoDB, and Google Cloud Translation.

---

## 2. Core SRS Features & Architecture

- **Adaptive Multilingual Chat:** Supports English (`en`), Hindi (`hi`), Marathi (`mr`), Tamil (`ta`), Bengali (`bn`), and Punjabi (`pa`) with automatic script detection, user preference persistence, and graceful fallback to English for unsupported languages.
- **Parallel RAG Pipeline (`Promise.all`):** Simultaneously queries MongoDB Smart FAQs and Pinecone Vector Knowledge Base (circulars, fee schedules, lab manuals), merges non-duplicate context, and generates strictly grounded responses.
- **Zero-Hallucination & Fault Tolerance:** Advises contacting the AUR Academic/Administrative Office when no matching record exists, and gracefully handles AI outages, translation failures, Pinecone/MongoDB downtime, and HTTP 429 rate limits.
- **Role-Based Access Control (RBAC):** Supports Anonymous Visitors, Authenticated Students, Admin Staff (`/admin` for log review, Smart FAQ CRUD, and circular uploads), and System Administrators (`/sysadmin` for telemetry, rate limits, and JWT secret rotation).
- **Strict Data Integrity:** Enforces <=25-character primary keys, duplicate PK rejection, and foreign-key constraints across all 11 institutional data entities.

---

## 3. Quick Start (Local Windows Execution)

1. Open PowerShell or Command Prompt inside the `backend` folder:
   ```powershell
   cd backend
   npm start
   ```
2. Open the unified application in your browser:
   - **Student Portal & Floating Widget:** `http://localhost:5000/`
   - **Admin Staff Dashboard:** `http://localhost:5000/admin`
   - **System Administrator Console:** `http://localhost:5000/sysadmin`
   - **Single `<script>` Embed Demo:** `http://localhost:5000/embed-demo.html`
   - **Backend Health Check:** `http://localhost:5000/api/health`

---

## 4. Demo Login Credentials

| Role | Username / Enrollment No | Password | Access Scope |
| :--- | :--- | :--- | :--- |
| **Student (English)** | `A50105224001` | `Student@123` | Authenticated student chat session (Aarav Verma) |
| **Student (Hindi)** | `A50105224002` | `Student@123` | Authenticated Hindi student session (Priya Meena) |
| **Admin Staff** | `admin_aur` | `Admin@123` | `/admin` chat logs, Smart FAQ CRUD, KB document upload |
| **System Admin** | `sysadmin_aur` | `SysAdmin@123` | `/sysadmin` health telemetry, rate limits, JWT rotation |

---

## 5. Single `<script>` Tag Website Integration

Embed the AskUni widget on any university web page by adding:

```html
<script>window.ASKUNI_API_BASE = "[https://your-domain.vercel.app/api](https://your-domain.vercel.app/api)";</script>
<script src="[https://your-domain.vercel.app/widget/askuni-widget.js](https://your-domain.vercel.app/widget/askuni-widget.js)" async></script>
```

---

## 6. Automated Verification Matrix (53 Test Cases)

All **53 documented test cases (`TC-01` to `TC-53`)** are automated via Vitest (Module 1: 12 tests) and Jest + Supertest (Modules 2-4: 41 tests) and exported to `reports/test-results.md`:
- **Module 1 (`TC-01..TC-12`):** Frontend widget lifecycle, Smart FAQ selection, empty-input validation, multilingual rendering, and session continuity.
- **Module 2 (`TC-13..TC-32`):** Parallel RAG retrieval, JWT authentication, anti-hallucination fallback, translation failure handling, `<=25`-char PK validation, and FK integrity.
- **Module 3 (`TC-33..TC-43`):** Admin RBAC enforcement, log filtering, Smart FAQ creation/update without duplication, and `lastUpdated` timestamp tracking.
- **Module 4 (`TC-44..TC-53`):** Server health telemetry, HTTP `429` rate limiting, `***MASKED***` secret protection, and graceful MongoDB/Pinecone outage handling.

---

## 7. Switching to Live Cloud APIs (`MOCK_MODE=false`)

1. Open `backend/.env` (or configure Environment Variables in Vercel).
2. Set `MOCK_MODE=false`.
3. Provide valid values for `OPENAI_API_KEY`, `PINECONE_API_KEY`, `PINECONE_INDEX`, `PINECONE_HOST`, `GOOGLE_TRANSLATE_API_KEY`, and `MONGODB_URI`.
4. Restart the server or redeploy.
