# 03-seed-and-test.ps1
# Writes seed data, seeds the AskUni database, runs all 53 automated tests (Vitest + Jest),
# generates .\reports\test-results.md, and prints demo credentials.
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

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERR]  $Message" -ForegroundColor Red
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

# 1. Ensure seedData.js is present and up-to-date
Write-Step "Verifying & Writing Institutional Seed Data (Amity University Rajasthan)"
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

$backendDir = Join-Path $RootDir "backend"
$frontendDir = Join-Path $RootDir "frontend"
$reportsDir = Join-Path $RootDir "reports"

if (-not (Test-Path -Path $reportsDir)) {
    New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null
}

# 2. Execute Initial Seed Script
Write-Step "Running Initial Database Seeding (backend/src/seed/seedData.js)"
Push-Location $backendDir
try {
    & npm run seed
    if ($LASTEXITCODE -ne 0) {
        throw "Database seeding failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
Write-Ok "Seeded 20 Smart FAQs, 5 Institutional Documents, Demo Students, Admin Staff, and SysAdmin."

# 3. Run Frontend Vitest Suite (Module 1: TC-01..TC-12)
$vitestJsonPath = Join-Path $reportsDir "vitest-results.json"
if (Test-Path $vitestJsonPath) { Remove-Item $vitestJsonPath -Force }

Write-Step "Running Module 1 Automated Frontend Widget Tests (Vitest: TC-01 to TC-12)"
$vitestExit = 0
Push-Location $frontendDir
try {
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & npx vitest run --reporter=json --outputFile="$vitestJsonPath"
    $vitestExit = $LASTEXITCODE
    $ErrorActionPreference = $prevPref
}
finally {
    Pop-Location
}

if (-not (Test-Path $vitestJsonPath)) {
    throw "Vitest JSON output was not generated at $vitestJsonPath"
}

# 4. Run Backend Jest Suite (Modules 2, 3, 4: TC-13..TC-53)
$jestJsonPath = Join-Path $reportsDir "jest-results.json"
if (Test-Path $jestJsonPath) { Remove-Item $jestJsonPath -Force }

Write-Step "Running Modules 2-4 Automated Backend, Admin & SysAdmin Tests (Jest: TC-13 to TC-53)"
$jestExit = 0
Push-Location $backendDir
try {
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & npx jest --runInBand --forceExit --json --outputFile="$jestJsonPath"
    $jestExit = $LASTEXITCODE
    $ErrorActionPreference = $prevPref
}
finally {
    Pop-Location
}

if (-not (Test-Path $jestJsonPath)) {
    throw "Jest JSON output was not generated at $jestJsonPath"
}

# 5. Re-seed clean state so test artifacts do not pollute live demo
Write-Step "Restoring Clean Seeded Database for Live Demo"
Push-Location $backendDir
try {
    & npm run seed
    if ($LASTEXITCODE -ne 0) {
        throw "Post-test re-seed failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

# 6. Parse Vitest & Jest JSON outputs and build .\reports\test-results.md
Write-Step "Generating Automated Verification Report (.\reports\test-results.md)"

$parsedResults = @{}

function Parse-TestJsonFile {
    param([string]$FilePath)
    $raw = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $jsonObj = $raw | ConvertFrom-Json
    foreach ($suite in $jsonObj.testResults) {
        foreach ($assertion in $suite.assertionResults) {
            $title = [string]$assertion.title
            if ($title -match '^(TC-\d{2})\s*(.*)$') {
                $tcId = $matches[1]
                $descFromTitle = $matches[2].Trim()
                $statusRaw = [string]$assertion.status
                $passed = ($statusRaw -eq 'passed')
                $failNote = ""
                if (-not $passed -and $null -ne $assertion.failureMessages -and $assertion.failureMessages.Count -gt 0) {
                    $firstMsg = [string]$assertion.failureMessages[0]
                    $firstLine = ($firstMsg -split "`r?`n")[0]
                    $failNote = $firstLine.Replace('|', '/')
                }
                $parsedResults[$tcId] = @{
                    TitleDesc = $descFromTitle
                    Result    = if ($passed) { "Pass" } else { "Fail" }
                    Note      = if ($passed) { "Verified via automated test suite" } else { "Failed: $failNote" }
                }
            }
        }
    }
}

Parse-TestJsonFile -FilePath $vitestJsonPath
Parse-TestJsonFile -FilePath $jestJsonPath

# Test Case Catalog (TC-01 to TC-53)
$testSpecs = @(
    # Module 1: Frontend Widget (12)
    @{ Id = "TC-01"; Mod = 1; Desc = "Open chatbot widget via floating launcher button"; Proc = "Render WidgetContainer and click floating AskUni launcher button"; Exp = "Chat dialog opens and renders header, log, and input controls" },
    @{ Id = "TC-02"; Mod = 1; Desc = "Initialize widget state to awaiting input and load Smart FAQs"; Proc = "Click launcher button and await anonymous session + FAQ fetch"; Exp = "State badge shows 'awaiting input' and Smart FAQ options populate" },
    @{ Id = "TC-03"; Mod = 1; Desc = "Submit valid English query and display grounded answer"; Proc = "Enter 'What is the B.Tech CSE tuition fee?' and click Send"; Exp = "Assistant bubble displays INR 1,86,000 and state updates to 'response displayed'" },
    @{ Id = "TC-04"; Mod = 1; Desc = "Reject empty or whitespace-only user query"; Proc = "Enter spaces ('    ') into chat input and click Send"; Exp = "Validation error banner displays; API sendQuery is not called" },
    @{ Id = "TC-05"; Mod = 1; Desc = "Submit Hindi query and display localized Hindi response"; Proc = "Enter Hindi Devanagari text and submit query"; Exp = "Assistant bubble renders translated Hindi response" },
    @{ Id = "TC-06"; Mod = 1; Desc = "Select Smart FAQ item from dropdown for instant submission"; Proc = "Select an examination FAQ from Smart FAQs dropdown"; Exp = "Selected question submits immediately and displays grounded answer" },
    @{ Id = "TC-07"; Mod = 1; Desc = "Display formatted ChatbotResponse with source badges and timestamps"; Proc = "Submit query returning PineconeVectorDB source metadata"; Exp = "Message bubble renders source badge and formatted timestamp" },
    @{ Id = "TC-08"; Mod = 1; Desc = "Switch preferredLanguage selector and translate response"; Proc = "Select Marathi ('mr') from language dropdown and submit query"; Exp = "API receives language='mr' and renders localized Marathi reply" },
    @{ Id = "TC-09"; Mod = 1; Desc = "Maintain same sessionId across multi-turn conversation"; Proc = "Send two consecutive queries within the same open widget session"; Exp = "Both POST /api/chat/query calls transmit identical sessionId" },
    @{ Id = "TC-10"; Mod = 1; Desc = "Minimize and close chatbot widget cleanly"; Proc = "Click minimize (_) button, resume, then click close (X) button"; Exp = "Dialog hides on minimize/close and restores launcher button cleanly" },
    @{ Id = "TC-11"; Mod = 1; Desc = "Record user and assistant messages in session conversation log"; Proc = "Submit query and inspect rendered message bubbles in chat log"; Exp = "Both chat-bubble-user and chat-bubble-assistant are recorded" },
    @{ Id = "TC-12"; Mod = 1; Desc = "Authenticate optional student login while supporting anonymous mode"; Proc = "Open Student Login drawer and submit valid enrollment credentials"; Exp = "Header updates to 'Signed in: Aarav Verma' with authenticated session" },

    # Module 2: Backend RAG & Data Integrity (20)
    @{ Id = "TC-13"; Mod = 2; Desc = "Receive valid UserQuery payload and return HTTP 200"; Proc = "POST /api/chat/query with valid queryText and language='en'"; Exp = "HTTP 200 with structured ChatbotResponse DTO" },
    @{ Id = "TC-14"; Mod = 2; Desc = "Process authenticated student query with personalized context"; Proc = "POST /api/chat/query with valid student Bearer JWT"; Exp = "Response marks isAuthenticated=true and greets student by name" },
    @{ Id = "TC-15"; Mod = 2; Desc = "Process anonymous visitor query without Bearer token"; Proc = "POST /api/chat/query without Authorization header"; Exp = "HTTP 200 with role='anonymous', isAuthenticated=false, and sess_ ID" },
    @{ Id = "TC-16"; Mod = 2; Desc = "Reject malformed or invalid JWT token"; Proc = "POST /api/chat/query with 'Bearer invalid.jwt.token.here'"; Exp = "HTTP 401 Unauthorized error response" },
    @{ Id = "TC-17"; Mod = 2; Desc = "Reject expired JWT token"; Proc = "POST /api/chat/query with JWT signed with past expiry"; Exp = "HTTP 401 Unauthorized with error code TOKEN_EXPIRED" },
    @{ Id = "TC-18"; Mod = 2; Desc = "Retrieve matching FAQ context from MongoDB repository"; Proc = "Call mongoRepo.fetchSmartFAQs('merit scholarship')"; Exp = "Returns ranked SmartFAQ entries in Scholarships category" },
    @{ Id = "TC-19"; Mod = 2; Desc = "Retrieve matching document chunks from Pinecone adapter"; Proc = "Call pineconeAdapter.searchVectorContext('BCS 522 Software Engineering Lab')"; Exp = "Returns relevant institutional document chunks with similarity scores" },
    @{ Id = "TC-20"; Mod = 2; Desc = "Execute parallel context retrieval from MongoDB and Pinecone"; Proc = "Call queryProcessor.retrieveAndMergeContext() with multi-source query"; Exp = "Merged context includes both SmartFAQ and PineconeVectorDB items" },
    @{ Id = "TC-21"; Mod = 2; Desc = "Handle missing context without hallucination"; Proc = "POST /api/chat/query with out-of-domain fictional topic"; Exp = "grounded=false and response advises contacting AUR Academic Office" },
    @{ Id = "TC-22"; Mod = 2; Desc = "Merge multi-source context without duplicate entries"; Proc = "Call retrieveAndMergeContext() on overlapping topic"; Exp = "All merged context titles are unique without duplication" },
    @{ Id = "TC-23"; Mod = 2; Desc = "Generate grounded AI answer from retrieved institutional facts"; Proc = "POST /api/chat/query asking about minimum attendance rule"; Exp = "grounded=true and response accurately states 75% attendance requirement" },
    @{ Id = "TC-24"; Mod = 2; Desc = "Translate grounded AI response into requested Hindi language"; Proc = "POST /api/chat/query with language='hi'"; Exp = "targetLanguage='hi', translationFailed=false, localized Hindi returned" },
    @{ Id = "TC-25"; Mod = 2; Desc = "Fallback to English with notice for unsupported language"; Proc = "POST /api/chat/query with unsupported language='fr'"; Exp = "targetLanguage='en', unsupportedLanguage=true, fallback notice appended" },
    @{ Id = "TC-26"; Mod = 2; Desc = "Handle AI generation service failure gracefully"; Proc = "Enable aiAdapter.simulateFailure=true and POST /api/chat/query"; Exp = "HTTP 200 safe fallback message with flags.aiFailed=true" },
    @{ Id = "TC-27"; Mod = 2; Desc = "Handle translation failure by returning English text and flag"; Proc = "Enable translationAdapter.simulateFailure=true and request Hindi"; Exp = "Original English answer returned with flags.translationFailed=true" },
    @{ Id = "TC-28"; Mod = 2; Desc = "Return ChatbotResponse linked to processorId and persist SessionLog"; Proc = "POST /api/chat/query and inspect persisted sessionLogs"; Exp = "Response links pr_ and rs_ IDs; SessionLog saved with matching sessionId" },
    @{ Id = "TC-29"; Mod = 2; Desc = "Accept custom primary key ID of exactly 25 characters"; Proc = "Create SmartFAQ with 25-character faqId ('faq_exact_twentyfive_1234')"; Exp = "Record created and persisted without validation error" },
    @{ Id = "TC-30"; Mod = 2; Desc = "Reject custom primary key ID of 26 or more characters"; Proc = "Attempt SmartFAQ creation with 26-character faqId"; Exp = "Rejected with 25-character maximum length validation error" },
    @{ Id = "TC-31"; Mod = 2; Desc = "Reject duplicate primary key insertion"; Proc = "Attempt to insert SmartFAQ with existing PK 'faq_exam_01'"; Exp = "Rejected with DUPLICATE_PRIMARY_KEY conflict error" },
    @{ Id = "TC-32"; Mod = 2; Desc = "Enforce foreign-key integrity across Query -> Processor -> Response"; Proc = "Insert processor with nonexistent queryId; verify valid chain links"; Exp = "Orphan FK rejected; valid execution chain links queryId and processorId" },

    # Module 3: Admin Staff Dashboard & Smart FAQs (11)
    @{ Id = "TC-33"; Mod = 3; Desc = "Allow authenticated admin_staff access to logs and trending"; Proc = "GET /api/admin/logs and /api/admin/trending with admin_staff JWT"; Exp = "HTTP 200 returning sessions array and trending questions" },
    @{ Id = "TC-34"; Mod = 3; Desc = "Reject unauthenticated or student access to /api/admin/*"; Proc = "GET /api/admin/logs without token and with student JWT"; Exp = "Returns HTTP 401 for unauthenticated and HTTP 403 for student role" },
    @{ Id = "TC-35"; Mod = 3; Desc = "Filter recent chat logs by language and keyword"; Proc = "GET /api/admin/logs?language=hi&keyword=fee as admin_staff"; Exp = "Returns matching Hindi session logs containing keyword" },
    @{ Id = "TC-36"; Mod = 3; Desc = "Inspect detailed session log transcript"; Proc = "GET /api/admin/logs/sess_demo_aur_01 as admin_staff"; Exp = "Returns queryText, responseText, and ISO timestamp for session" },
    @{ Id = "TC-37"; Mod = 3; Desc = "Create new Smart FAQ entry with valid fields"; Proc = "POST /api/admin/faqs with valid faqId, question, answerText, category"; Exp = "HTTP 201 Created returning persisted SmartFAQ record" },
    @{ Id = "TC-38"; Mod = 3; Desc = "Update existing Smart FAQ in place without duplication"; Proc = "PUT /api/admin/faqs/faq_admin_new_01 with updated answerText"; Exp = "HTTP 200 Updated; total FAQ collection count remains unchanged" },
    @{ Id = "TC-39"; Mod = 3; Desc = "Reject Smart FAQ creation when required fields are missing"; Proc = "POST /api/admin/faqs omitting answerText and category"; Exp = "HTTP 400 Bad Request validation failure" },
    @{ Id = "TC-40"; Mod = 3; Desc = "Persist new Smart FAQ for public listing and RAG queries"; Proc = "GET /api/faqs and POST /api/chat/query matching newly added FAQ"; Exp = "Public endpoint lists new FAQ and chatbot answers using updated text" },
    @{ Id = "TC-41"; Mod = 3; Desc = "Auto-update lastUpdated timestamp on Smart FAQ edit"; Proc = "Modify Smart FAQ via PUT /api/admin/faqs/:faqId and compare timestamp"; Exp = "lastUpdated ISO timestamp advances automatically" },
    @{ Id = "TC-42"; Mod = 3; Desc = "Reject Smart FAQ creation with faqId exceeding 25 characters"; Proc = "POST /api/admin/faqs with 40-character faqId"; Exp = "HTTP 400 Bad Request rejecting >25-char faqId" },
    @{ Id = "TC-43"; Mod = 3; Desc = "Maintain association between ChatSessionHistory, widgetId, and sessionId"; Proc = "Submit query with sessionId and inspect admin session history detail"; Exp = "ChatSessionHistory records link matching widgetId and sessionId" },

    # Module 4: System Administrator & Infrastructure Resilience (10)
    @{ Id = "TC-44"; Mod = 4; Desc = "Return server health telemetry (uptime, memory, DB status)"; Proc = "GET /api/sysadmin/health with system_admin JWT"; Exp = "HTTP 200 with uptimeSeconds, memory.rssMb, and database.connected=true" },
    @{ Id = "TC-45"; Mod = 4; Desc = "Report external API availability (OpenAI, Pinecone, Translate)"; Proc = "GET /api/sysadmin/health and inspect externalServices"; Exp = "Reports availability flags for OpenAI, Pinecone, and Google Translate" },
    @{ Id = "TC-46"; Mod = 4; Desc = "Reject expired system_admin credentials"; Proc = "GET /api/sysadmin/health with expired system_admin JWT"; Exp = "HTTP 401 Unauthorized" },
    @{ Id = "TC-47"; Mod = 4; Desc = "Enforce API rate limits and return HTTP 429 with retry hint"; Proc = "Set rateLimitMax=2 and issue 3 rapid requests to /api/health"; Exp = "3rd request receives HTTP 429 with retryAfterSeconds hint" },
    @{ Id = "TC-48"; Mod = 4; Desc = "Update system configuration (rate limits & languages) for sysadmin"; Proc = "PUT /api/sysadmin/config with valid adminId, rateLimitMax, languages"; Exp = "HTTP 200 updated=true and rateLimits.maxRequests reflects new value" },
    @{ Id = "TC-49"; Mod = 4; Desc = "Block non-system_admin roles from key rotation or config edits"; Proc = "Call /api/sysadmin/credentials/renew as admin_staff and config as student"; Exp = "Both requests rejected with HTTP 403 Forbidden" },
    @{ Id = "TC-50"; Mod = 4; Desc = "Mask tokenSecret in all UI/API responses and rotate secret safely"; Proc = "GET /api/sysadmin/services and POST /api/sysadmin/credentials/renew"; Exp = "Raw activeSecret never appears in responses; maskedSecret='***MASKED***'" },
    @{ Id = "TC-51"; Mod = 4; Desc = "Handle MongoDB repository failure gracefully without server crash"; Proc = "Set dbManager.simulateFailure=true and POST /api/chat/query"; Exp = "HTTP 200 returned with flags.mongoFailed=true using vector fallback" },
    @{ Id = "TC-52"; Mod = 4; Desc = "Handle Pinecone outage gracefully using MongoDB-only context"; Proc = "Set pineconeAdapter.simulateFailure=true and POST /api/chat/query"; Exp = "HTTP 200 returned with flags.pineconeFailed=true and partialContext=true" },
    @{ Id = "TC-53"; Mod = 4; Desc = "Validate adminId PK length (<=25 chars) and staffId FK integrity"; Proc = "PUT /api/sysadmin/config with >25-char adminId; test invalid staffId FK"; Exp = "HTTP 400 on >25-char adminId; FK violation error on invalid staffId" }
)

$testDate = (Get-Date).ToString("yyyy-MM-dd")

# Compute per-module counts
$modStats = @{
    1 = @{ Name = "Module 1: Frontend Widget (TC-01..TC-12)"; Total = 0; Pass = 0; Fail = 0 }
    2 = @{ Name = "Module 2: Backend RAG & Schema (TC-13..TC-32)"; Total = 0; Pass = 0; Fail = 0 }
    3 = @{ Name = "Module 3: Admin Dashboard & FAQs (TC-33..TC-43)"; Total = 0; Pass = 0; Fail = 0 }
    4 = @{ Name = "Module 4: SysAdmin & Resilience (TC-44..TC-53)"; Total = 0; Pass = 0; Fail = 0 }
}

$tableRows = New-Object System.Collections.Generic.List[string]

foreach ($spec in $testSpecs) {
    $id = $spec.Id
    $modNum = [int]$spec.Mod
    $modStats[$modNum].Total += 1

    $resultText = "Fail"
    $noteText = "Test case not found in runner output"
    if ($parsedResults.ContainsKey($id)) {
        $resultText = $parsedResults[$id].Result
        $noteText = $parsedResults[$id].Note
    }

    if ($resultText -eq "Pass") {
        $modStats[$modNum].Pass += 1
    }
    else {
        $modStats[$modNum].Fail += 1
    }

    $rowLine = "| $id | $($spec.Desc) | $($spec.Proc) | $($spec.Exp) | $testDate | $resultText | $noteText |"
    $tableRows.Add($rowLine)
}

$totalAll = $modStats[1].Total + $modStats[2].Total + $modStats[3].Total + $modStats[4].Total
$passAll = $modStats[1].Pass + $modStats[2].Pass + $modStats[3].Pass + $modStats[4].Pass
$failAll = $modStats[1].Fail + $modStats[2].Fail + $modStats[3].Fail + $modStats[4].Fail

$mdLines = New-Object System.Collections.Generic.List[string]
$mdLines.Add("# AskUni Automated Test Verification Report")
$mdLines.Add("")
$mdLines.Add("- **Institution:** Amity University Rajasthan (Jaipur) - B.Tech CSE, Software Engineering Lab (BCS 522)")
$mdLines.Add("- **Execution Timestamp:** $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
$mdLines.Add(("- **Overall Result:** **{0} / {1} Passed** ({2} Failed)" -f $passAll, $totalAll, $failAll))
$mdLines.Add("")
$mdLines.Add("## Module Summary Breakdown (12 / 20 / 11 / 10 = 53)")
$mdLines.Add("")
$mdLines.Add("| Module | Planned | Passed | Failed | Status |")
$mdLines.Add("| :--- | :---: | :---: | :---: | :---: |")
foreach ($m in @(1, 2, 3, 4)) {
    $st = $modStats[$m]
    $mStatus = if ($st.Fail -eq 0 -and $st.Pass -eq $st.Total) { "PASS" } else { "FAIL" }
    $mdLines.Add("| $($st.Name) | $($st.Total) | $($st.Pass) | $($st.Fail) | $mStatus |")
}
$overallStatus = if ($failAll -eq 0 -and $passAll -eq $totalAll) { "PASS" } else { "FAIL" }
$mdLines.Add("| **Total (All Modules)** | **$totalAll** | **$passAll** | **$failAll** | **$overallStatus** |")
$mdLines.Add("")
$mdLines.Add("## Detailed Test Execution Matrix (TC-01 to TC-53)")
$mdLines.Add("")
$mdLines.Add("| Test Case ID | Description | Procedure | Expected Output | Test Date | Result (Pass/Fail) | Note |")
$mdLines.Add("| :--- | :--- | :--- | :--- | :--- | :---: | :--- |")
foreach ($r in $tableRows) {
    $mdLines.Add($r)
}

$reportContent = ($mdLines -join "`r`n") + "`r`n"
Write-ProjectFile -RelativePath "reports\test-results.md" -Content $reportContent

Write-Host ""
Write-Host "================ TEST EXECUTION SUMMARY ================" -ForegroundColor Cyan
Write-Host ("Module 1 (Frontend Widget):     {0}/{1} Passed" -f $modStats[1].Pass, $modStats[1].Total) -ForegroundColor Green
Write-Host ("Module 2 (Backend RAG & Data):  {0}/{1} Passed" -f $modStats[2].Pass, $modStats[2].Total) -ForegroundColor Green
Write-Host ("Module 3 (Admin & Smart FAQs):  {0}/{1} Passed" -f $modStats[3].Pass, $modStats[3].Total) -ForegroundColor Green
Write-Host ("Module 4 (SysAdmin & Security): {0}/{1} Passed" -f $modStats[4].Pass, $modStats[4].Total) -ForegroundColor Green
Write-Host ("TOTAL VERIFIED:                 {0}/{1} Passed" -f $passAll, $totalAll) -ForegroundColor Cyan
Write-Host "Report saved to: $(Join-Path $RootDir 'reports\test-results.md')" -ForegroundColor Yellow

Write-Host ""
Write-Host "================ ASKUNI DEMO CREDENTIALS ===============" -ForegroundColor Cyan
Write-Host "  Student 1 (English):  Username = A50105224001  | Password = Student@123" -ForegroundColor White
Write-Host "  Student 2 (Hindi):    Username = A50105224002  | Password = Student@123" -ForegroundColor White
Write-Host "  Admin Staff (/admin): Username = admin_aur     | Password = Admin@123" -ForegroundColor White
Write-Host "  SysAdmin (/sysadmin): Username = sysadmin_aur  | Password = SysAdmin@123" -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Cyan

if ($failAll -gt 0 -or $vitestExit -ne 0 -or $jestExit -ne 0) {
    Write-Err "One or more automated tests failed ($failAll failed). Review reports\test-results.md for details."
    exit 1
}

Write-Host ""
Write-Ok "All 53 test cases passed and report generated! Proceed to 04-run-all.ps1."
exit 0