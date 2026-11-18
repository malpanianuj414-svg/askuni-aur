const request = require('supertest');
const jwt = require('jsonwebtoken');
const { createApp } = require('../app');
const { runSeed } = require('../seed/seedData');
const { dbManager } = require('../config/db');
const { Models } = require('../models/schemas');

let app;
let studentToken;
let adminToken;
let sysAdminToken;

beforeAll(async () => {
  await runSeed({ forceReset: true });
  app = createApp();

  const stuLogin = await request(app)
    .post('/api/auth/login')
    .send({ username: 'A50105224001', password: 'Student@123', role: 'student' });
  studentToken = stuLogin.body.token;

  const admLogin = await request(app)
    .post('/api/auth/login')
    .send({ username: 'admin_aur', password: 'Admin@123', role: 'admin_staff' });
  adminToken = admLogin.body.token;

  const sysLogin = await request(app)
    .post('/api/auth/login')
    .send({ username: 'sysadmin_aur', password: 'SysAdmin@123', role: 'system_admin' });
  sysAdminToken = sysLogin.body.token;
});

afterEach(() => {
  // Reset any simulated outages between tests
  dbManager.simulateFailure = false;
  app.locals.services.pineconeAdapter.simulateFailure = false;
  app.locals.services.aiAdapter.simulateFailure = false;
  app.locals.services.translationAdapter.simulateFailure = false;
});

describe('Module 2: Backend RAG Pipeline & Data Integrity (TC-13 to TC-32)', () => {
  test('TC-13 receives valid UserQuery payload and returns 200 with structured ChatbotResponse', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.responseId).toBeDefined();
    expect(res.body.data.translatedText).toContain('1,86,000');
  });

  test('TC-14 processes authenticated student query with student context and isAuthenticated=true', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ queryText: 'When do Odd Semester End-Term Examinations begin?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.isAuthenticated).toBe(true);
    expect(res.body.data.userId).toBe('stu_a50105224001');
    expect(res.body.data.translatedText).toContain('Aarav Verma');
  });

  test('TC-15 processes anonymous visitor query without Bearer token and assigns anonymous session', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the hostel fee at Amity University Rajasthan?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.isAuthenticated).toBe(false);
    expect(res.body.data.role).toBe('anonymous');
    expect(res.body.data.sessionId).toMatch(/^sess_/);
  });

  test('TC-16 rejects invalid or malformed JWT token with 401 Unauthorized', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .set('Authorization', 'Bearer invalid.jwt.token.here')
      .send({ queryText: 'Exam dates?', language: 'en' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  test('TC-17 rejects expired JWT token with 401 Unauthorized', async () => {
    const expiredToken = jwt.sign(
      { userId: 'stu_a50105224001', role: 'student' },
      app.locals.services.authService.activeSecret,
      { expiresIn: -10 }
    );

    const res = await request(app)
      .post('/api/chat/query')
      .set('Authorization', `Bearer ${expiredToken}`)
      .send({ queryText: 'Exam dates?', language: 'en' });

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('TOKEN_EXPIRED');
  });

  test('TC-18 retrieves relevant FAQ records from MongoDB repository', async () => {
    const faqs = await app.locals.services.mongoRepo.fetchSmartFAQs('merit scholarship');
    expect(Array.isArray(faqs)).toBe(true);
    expect(faqs.length).toBeGreaterThan(0);
    expect(faqs[0].category).toBe('Scholarships');
  });

  test('TC-19 retrieves relevant institutional document chunks from Pinecone vector adapter', async () => {
    const docs = await app.locals.services.pineconeAdapter.searchVectorContext('BCS 522 Software Engineering Lab', 3);
    expect(Array.isArray(docs)).toBe(true);
    expect(docs.length).toBeGreaterThan(0);
    expect(docs[0].title).toContain('BCS 522');
  });

  test('TC-20 retrieves and merges context from both MongoDB and Pinecone in parallel', async () => {
    const { mergedContext, flags } = await app.locals.services.queryProcessor.retrieveAndMergeContext(
      'Odd Semester Examination Guidelines BCS 522'
    );
    const sources = new Set(mergedContext.map((m) => m.source));
    expect(sources.has('SmartFAQ')).toBe(true);
    expect(sources.has('PineconeVectorDB')).toBe(true);
    expect(flags.mongoFailed).toBe(false);
    expect(flags.pineconeFailed).toBe(false);
  });

  test('TC-21 handles missing context gracefully without hallucinating and suggests contacting college office', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'Quantum teleportation mars colony cafeteria menu 2099', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.grounded).toBe(false);
    expect(res.body.data.translatedText).toMatch(/Administrative \/ Academic Office|\+91-1426-405555/i);
  });

  test('TC-22 merges Smart FAQ context and vector document context cleanly without duplication', async () => {
    const { mergedContext } = await app.locals.services.queryProcessor.retrieveAndMergeContext('hostel fee rules');
    const titles = mergedContext.map((c) => c.title.toLowerCase());
    const uniqueTitles = new Set(titles);
    expect(titles.length).toBe(uniqueTitles.size);
  });

  test('TC-23 generates grounded AI response referencing retrieved institutional facts', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the minimum attendance required for exams?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.grounded).toBe(true);
    expect(res.body.data.generatedText).toContain('75%');
  });

  test('TC-24 translates response accurately into requested supported language (Hindi)', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'hi' });

    expect(res.status).toBe(200);
    expect(res.body.data.targetLanguage).toBe('hi');
    expect(res.body.data.translatedText).toContain('à¤¹à¤¿à¤¨à¥à¤¦à¥€');
    expect(res.body.data.flags.translationFailed).toBe(false);
  });

  test('TC-25 falls back to English with clear notice when unsupported language is requested', async () => {
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'fr' });

    expect(res.status).toBe(200);
    expect(res.body.data.targetLanguage).toBe('en');
    expect(res.body.data.flags.unsupportedLanguage).toBe(true);
    expect(res.body.data.translatedText).toContain('not currently supported');
  });

  test('TC-26 handles AI service failure gracefully with safe error response and status flag', async () => {
    app.locals.services.aiAdapter.simulateFailure = true;

    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'When are exams?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.flags.aiFailed).toBe(true);
    expect(res.body.data.translatedText).toContain('temporary issue');
  });

  test('TC-27 handles translation service failure by returning original English text and flagging translationFailed', async () => {
    app.locals.services.translationAdapter.simulateFailure = true;

    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the B.Tech CSE tuition fee?', language: 'hi' });

    expect(res.status).toBe(200);
    expect(res.body.data.flags.translationFailed).toBe(true);
    expect(res.body.data.targetLanguage).toBe('en');
    expect(res.body.data.translatedText).toContain('1,86,000');
  });

  test('TC-28 returns formatted ChatbotResponse linked to processorId and persists SessionLog', async () => {
    const sessionId = 'sess_tc28_verify';
    const res = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'Library operating hours?', sessionId, language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.data.processorId).toMatch(/^pr_/);
    expect(res.body.data.responseId).toMatch(/^rs_/);

    const savedLog = dbManager.store.sessionLogs.find((l) => l.sessionId === sessionId);
    expect(savedLog).toBeDefined();
    expect(savedLog.queryText).toBe('Library operating hours?');
  });

  test('TC-29 accepts custom primary key IDs of exactly 25 characters', async () => {
    const exact25Id = 'faq_exact_twentyfive_1234'; // 25 chars
    expect(exact25Id.length).toBe(25);

    const created = await app.locals.services.mongoRepo.createFAQEntry({
      faqId: exact25Id,
      question: 'Exact 25 char ID test question?',
      answerText: 'Exact 25 char ID test answer.',
      category: 'Testing'
    });

    expect(created.faqId).toBe(exact25Id);
  });

  test('TC-30 rejects custom primary key IDs of 26 or more characters', async () => {
    const id26 = 'faq_twentysix_characters_1'; // 26 chars
    expect(id26.length).toBe(26);

    await expect(
      app.locals.services.mongoRepo.createFAQEntry({
        faqId: id26,
        question: 'Too long ID question?',
        answerText: 'Too long ID answer.',
        category: 'Testing'
      })
    ).rejects.toThrow(/25 characters/);
  });

  test('TC-31 rejects duplicate primary key insertion with conflict error', async () => {
    await expect(
      app.locals.services.mongoRepo.createFAQEntry({
        faqId: 'faq_exam_01',
        question: 'Duplicate PK question?',
        answerText: 'Duplicate PK answer.',
        category: 'Testing'
      })
    ).rejects.toThrow(/Duplicate primary key/);
  });

  test('TC-32 enforces foreign-key integrity and links UserQuery -> BackendQueryProcessor -> ChatbotResponse', async () => {
    await expect(
      app.locals.services.mongoRepo.insertRecord(
        'processors',
        'processorId',
        Models.BackendQueryProcessor,
        {
          processorId: 'pr_orphan_fk_01',
          queryId: 'non_existent_query_id',
          activeSessionId: 'sess_fk',
          dbUri: 'mock://db',
          indexName: 'askuni-aur-index',
          apiEndpoint: '/api/chat/query'
        },
        [{ field: 'queryId', targetCollection: 'userQueries', targetField: 'queryId' }]
      )
    ).rejects.toThrow(/Foreign key constraint failed/);

    const latestResp = dbManager.store.responses[dbManager.store.responses.length - 1];
    const linkedProc = dbManager.store.processors.find((p) => p.processorId === latestResp.processorId);
    const linkedQuery = dbManager.store.userQueries.find((q) => q.queryId === linkedProc.queryId);
    expect(linkedProc).toBeDefined();
    expect(linkedQuery).toBeDefined();
  });
});

describe('Module 3: Admin Staff Dashboard & Smart FAQ Management (TC-33 to TC-43)', () => {
  test('TC-33 allows authenticated admin_staff user to access /api/admin/logs and /api/admin/trending', async () => {
    const logsRes = await request(app)
      .get('/api/admin/logs')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(logsRes.status).toBe(200);
    expect(Array.isArray(logsRes.body.sessions)).toBe(true);

    const trendRes = await request(app)
      .get('/api/admin/trending')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(trendRes.status).toBe(200);
    expect(Array.isArray(trendRes.body.trending)).toBe(true);
  });

  test('TC-34 rejects unauthenticated or student-role requests to admin endpoints with 401/403', async () => {
    const unauthRes = await request(app).get('/api/admin/logs');
    expect(unauthRes.status).toBe(401);

    const studentRes = await request(app)
      .get('/api/admin/logs')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(studentRes.status).toBe(403);
  });

  test('TC-35 lists recent chat sessions with filtering by language and keyword', async () => {
    const res = await request(app)
      .get('/api/admin/logs?language=hi&keyword=à¤«à¥€à¤¸')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.logs.length).toBeGreaterThan(0);
    expect(res.body.logs[0].language).toBe('hi');
  });

  test('TC-36 opens specific session log detail showing query, response, and timestamp', async () => {
    const res = await request(app)
      .get('/api/admin/logs/sess_demo_aur_01')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.sessionId).toBe('sess_demo_aur_01');
    expect(res.body.logs[0].queryText).toBeDefined();
    expect(res.body.logs[0].responseText).toBeDefined();
    expect(res.body.logs[0].timestamp).toBeDefined();
  });

  test('TC-37 creates a new Smart FAQ entry with valid fields and <=25-char faqId', async () => {
    const res = await request(app)
      .post('/api/admin/faqs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        faqId: 'faq_admin_new_01',
        question: 'Where is the ASET Robotics Lab located?',
        answerText: 'ASET Robotics & IoT Innovation Lab is located in Block-B, Room 108.',
        category: 'Labs & Facilities'
      });

    expect(res.status).toBe(201);
    expect(res.body.faq.faqId).toBe('faq_admin_new_01');
  });

  test('TC-38 updates an existing Smart FAQ entry in place without creating duplicates', async () => {
    const beforeCount = dbManager.store.smartFaqs.length;

    const res = await request(app)
      .put('/api/admin/faqs/faq_admin_new_01')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        answerText: 'ASET Robotics & IoT Innovation Lab is located in Block-B, Ground Floor Room 108.'
      });

    expect(res.status).toBe(200);
    expect(res.body.faq.answerText).toContain('Ground Floor Room 108');
    expect(dbManager.store.smartFaqs.length).toBe(beforeCount);
  });

  test('TC-39 rejects Smart FAQ creation/update when required fields are missing', async () => {
    const res = await request(app)
      .post('/api/admin/faqs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ question: 'Incomplete FAQ without answer or category' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('TC-40 persists newly added Smart FAQ so subsequent public GET /api/faqs and chat queries retrieve it', async () => {
    const publicRes = await request(app).get('/api/faqs');
    expect(publicRes.status).toBe(200);
    const found = publicRes.body.faqs.find((f) => f.faqId === 'faq_admin_new_01');
    expect(found).toBeDefined();

    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'Where is the ASET Robotics Lab located?', language: 'en' });
    expect(chatRes.body.data.translatedText).toContain('Ground Floor Room 108');
  });

  test('TC-41 automatically updates lastUpdated ISO timestamp whenever Smart FAQ is modified', async () => {
    const existing = dbManager.store.smartFaqs.find((f) => f.faqId === 'faq_admin_new_01');
    const prevTimestamp = existing.lastUpdated;

    await new Promise((r) => setTimeout(r, 15));

    const res = await request(app)
      .put('/api/admin/faqs/faq_admin_new_01')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ category: 'Robotics & Labs' });

    expect(res.status).toBe(200);
    expect(res.body.faq.lastUpdated).not.toBe(prevTimestamp);
  });

  test('TC-42 rejects Smart FAQ with faqId exceeding 25 characters', async () => {
    const res = await request(app)
      .post('/api/admin/faqs')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        faqId: 'faq_id_that_is_way_longer_than_25_chars',
        question: 'Valid question text here?',
        answerText: 'Valid answer text here.',
        category: 'General'
      });

    expect(res.status).toBe(400);
  });

  test('TC-43 maintains association between ChatSessionHistory messages, widgetId, and sessionId', async () => {
    const sessionId = 'sess_history_assoc_43';
    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'How do I get a Bonafide Certificate?', sessionId, language: 'en' });

    const { widgetId } = chatRes.body.data;
    const detailRes = await request(app)
      .get(`/api/admin/logs/${sessionId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(detailRes.status).toBe(200);
    expect(detailRes.body.history.length).toBeGreaterThanOrEqual(2);
    expect(detailRes.body.history[0].widgetId).toBe(widgetId);
    expect(detailRes.body.history[0].sessionId).toBe(sessionId);
  });
});

describe('Module 4: System Administrator & Infrastructure Resilience (TC-44 to TC-53)', () => {
  test('TC-44 returns server health metrics (uptime, memory, DB status) for system_admin', async () => {
    const res = await request(app)
      .get('/api/sysadmin/health')
      .set('Authorization', `Bearer ${sysAdminToken}`);

    expect(res.status).toBe(200);
    expect(typeof res.body.health.uptimeSeconds).toBe('number');
    expect(res.body.health.memory.rssMb).toBeGreaterThan(0);
    expect(res.body.health.database.connected).toBe(true);
  });

  test('TC-45 reports availability status of external API services (OpenAI, Pinecone, Google Translate)', async () => {
    const res = await request(app)
      .get('/api/sysadmin/health')
      .set('Authorization', `Bearer ${sysAdminToken}`);

    expect(res.status).toBe(200);
    const ext = res.body.health.externalServices;
    expect(ext.openai.available).toBe(true);
    expect(ext.pinecone.available).toBe(true);
    expect(ext.googleTranslate.available).toBe(true);
  });

  test('TC-46 rejects expired system_admin credentials with 401 Unauthorized', async () => {
    const expiredSysToken = jwt.sign(
      { userId: 'sysadmin_aur_01', adminId: 'sysadmin_aur_01', role: 'system_admin' },
      app.locals.services.authService.activeSecret,
      { expiresIn: -5 }
    );

    const res = await request(app)
      .get('/api/sysadmin/health')
      .set('Authorization', `Bearer ${expiredSysToken}`);

    expect(res.status).toBe(401);
  });

  test('TC-47 enforces API rate limits and returns HTTP 429 with retry hint when exceeded', async () => {
    // Temporarily lower rate limit to 2 requests for verification
    app.locals.services.infraService.rateLimitState.maxRequests = 2;

    await request(app).get('/api/health');
    await request(app).get('/api/health');
    const blockedRes = await request(app).get('/api/health');

    expect(blockedRes.status).toBe(429);
    expect(blockedRes.body.error.code).toBe('RATE_LIMIT_EXCEEDED');
    expect(blockedRes.body.error.retryAfterSeconds).toBeGreaterThan(0);

    // Restore normal rate limit
    app.locals.services.infraService.rateLimitState.maxRequests = 120;
  });

  test('TC-48 updates system configuration (supportedLanguages and rateLimitMax) for authorized system_admin', async () => {
    const res = await request(app)
      .put('/api/sysadmin/config')
      .set('Authorization', `Bearer ${sysAdminToken}`)
      .send({
        adminId: 'sysadmin_aur_01',
        rateLimitMax: 150,
        supportedLanguages: ['en', 'hi', 'mr', 'ta', 'bn', 'pa']
      });

    expect(res.status).toBe(200);
    expect(res.body.updated).toBe(true);
    expect(res.body.rateLimits.maxRequests).toBe(150);
  });

  test('TC-49 blocks non-system_admin roles (student, admin_staff) from modifying sysadmin config or rotating keys', async () => {
    const staffRes = await request(app)
      .post('/api/sysadmin/credentials/renew')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(staffRes.status).toBe(403);

    const stuRes = await request(app)
      .put('/api/sysadmin/config')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ rateLimitMax: 500 });
    expect(stuRes.status).toBe(403);
  });

  test('TC-50 masks tokenSecret in all API responses, config views, and logs (never exposes raw secret)', async () => {
    const servicesRes = await request(app)
      .get('/api/sysadmin/services')
      .set('Authorization', `Bearer ${sysAdminToken}`);
    expect(servicesRes.status).toBe(200);
    expect(JSON.stringify(servicesRes.body)).not.toContain(app.locals.services.authService.activeSecret);
    expect(servicesRes.body.security.tokenSecret).toBe('***MASKED***');

    const renewRes = await request(app)
      .post('/api/sysadmin/credentials/renew')
      .set('Authorization', `Bearer ${sysAdminToken}`);
    expect(renewRes.status).toBe(200);
    expect(JSON.stringify(renewRes.body)).not.toContain(app.locals.services.authService.activeSecret);
    expect(renewRes.body.rotation.maskedSecret).toBe('***MASKED***');

    // Re-issue tokens with new rotated secret for remaining tests
    const reLogin = await request(app)
      .post('/api/auth/login')
      .send({ username: 'sysadmin_aur', password: 'SysAdmin@123', role: 'system_admin' });
    sysAdminToken = reLogin.body.token;
  });

  test('TC-51 handles MongoDB repository failure gracefully without crashing the server', async () => {
    dbManager.simulateFailure = true;

    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'BCS 522 Software Engineering Lab evaluation rubric', language: 'en' });

    expect(chatRes.status).toBe(200);
    expect(chatRes.body.data.flags.mongoFailed).toBe(true);
    expect(chatRes.body.data.translatedText).toContain('BCS 522');
  });

  test('TC-52 handles Pinecone vector outage gracefully by falling back to MongoDB-only context with flag', async () => {
    app.locals.services.pineconeAdapter.simulateFailure = true;

    const chatRes = await request(app)
      .post('/api/chat/query')
      .send({ queryText: 'What is the annual tuition fee for B.Tech CSE?', language: 'en' });

    expect(chatRes.status).toBe(200);
    expect(chatRes.body.data.flags.pineconeFailed).toBe(true);
    expect(chatRes.body.data.flags.partialContext).toBe(true);
    expect(chatRes.body.data.translatedText).toContain('1,86,000');
  });

  test('TC-53 validates adminId primary key length (<=25 chars) and staffId foreign key integrity', async () => {
    const badIdRes = await request(app)
      .put('/api/sysadmin/config')
      .set('Authorization', `Bearer ${sysAdminToken}`)
      .send({ adminId: 'sysadmin_id_exceeding_twenty_five_characters' });
    expect(badIdRes.status).toBe(400);

    await expect(
      app.locals.services.mongoRepo.insertRecord(
        'systemAdmins',
        'adminId',
        Models.SystemAdministrator,
        {
          adminId: 'sysadmin_bad_fk_01',
          staffId: 'non_existent_staff_id',
          apiEndpoint: '/api/sysadmin',
          role: 'system_admin',
          username: 'bad_sys',
          passwordHash: 'hash'
        },
        [{ field: 'staffId', targetCollection: 'adminStaff', targetField: 'staffId' }]
      )
    ).rejects.toThrow(/Foreign key constraint failed/);
  });
});