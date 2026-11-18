# AskUni Automated Test Verification Report

- **Institution:** Amity University Rajasthan (Jaipur) - B.Tech CSE, Software Engineering Lab (BCS 522)
- **Execution Timestamp:** 2026-11-19 02:28:34
- **Overall Result:** **53 / 53 Passed** (0 Failed)

## Module Summary Breakdown (12 / 20 / 11 / 10 = 53)

| Module | Planned | Passed | Failed | Status |
| :--- | :---: | :---: | :---: | :---: |
| Module 1: Frontend Widget (TC-01..TC-12) | 12 | 12 | 0 | PASS |
| Module 2: Backend RAG & Schema (TC-13..TC-32) | 20 | 20 | 0 | PASS |
| Module 3: Admin Dashboard & FAQs (TC-33..TC-43) | 11 | 11 | 0 | PASS |
| Module 4: SysAdmin & Resilience (TC-44..TC-53) | 10 | 10 | 0 | PASS |
| **Total (All Modules)** | **53** | **53** | **0** | **PASS** |

## Detailed Test Execution Matrix (TC-01 to TC-53)

| Test Case ID | Description | Procedure | Expected Output | Test Date | Result (Pass/Fail) | Note |
| :--- | :--- | :--- | :--- | :--- | :---: | :--- |
| TC-01 | Open chatbot widget via floating launcher button | Render WidgetContainer and click floating AskUni launcher button | Chat dialog opens and renders header, log, and input controls | 2026-11-19 | Pass | Verified via automated test suite |
| TC-02 | Initialize widget state to awaiting input and load Smart FAQs | Click launcher button and await anonymous session + FAQ fetch | State badge shows 'awaiting input' and Smart FAQ options populate | 2026-11-19 | Pass | Verified via automated test suite |
| TC-03 | Submit valid English query and display grounded answer | Enter 'What is the B.Tech CSE tuition fee?' and click Send | Assistant bubble displays INR 1,86,000 and state updates to 'response displayed' | 2026-11-19 | Pass | Verified via automated test suite |
| TC-04 | Reject empty or whitespace-only user query | Enter spaces ('    ') into chat input and click Send | Validation error banner displays; API sendQuery is not called | 2026-11-19 | Pass | Verified via automated test suite |
| TC-05 | Submit Hindi query and display localized Hindi response | Enter Hindi Devanagari text and submit query | Assistant bubble renders translated Hindi response | 2026-11-19 | Pass | Verified via automated test suite |
| TC-06 | Select Smart FAQ item from dropdown for instant submission | Select an examination FAQ from Smart FAQs dropdown | Selected question submits immediately and displays grounded answer | 2026-11-19 | Pass | Verified via automated test suite |
| TC-07 | Display formatted ChatbotResponse with source badges and timestamps | Submit query returning PineconeVectorDB source metadata | Message bubble renders source badge and formatted timestamp | 2026-11-19 | Pass | Verified via automated test suite |
| TC-08 | Switch preferredLanguage selector and translate response | Select Marathi ('mr') from language dropdown and submit query | API receives language='mr' and renders localized Marathi reply | 2026-11-19 | Pass | Verified via automated test suite |
| TC-09 | Maintain same sessionId across multi-turn conversation | Send two consecutive queries within the same open widget session | Both POST /api/chat/query calls transmit identical sessionId | 2026-11-19 | Pass | Verified via automated test suite |
| TC-10 | Minimize and close chatbot widget cleanly | Click minimize (_) button, resume, then click close (X) button | Dialog hides on minimize/close and restores launcher button cleanly | 2026-11-19 | Pass | Verified via automated test suite |
| TC-11 | Record user and assistant messages in session conversation log | Submit query and inspect rendered message bubbles in chat log | Both chat-bubble-user and chat-bubble-assistant are recorded | 2026-11-19 | Pass | Verified via automated test suite |
| TC-12 | Authenticate optional student login while supporting anonymous mode | Open Student Login drawer and submit valid enrollment credentials | Header updates to 'Signed in: Aarav Verma' with authenticated session | 2026-11-19 | Pass | Verified via automated test suite |
| TC-13 | Receive valid UserQuery payload and return HTTP 200 | POST /api/chat/query with valid queryText and language='en' | HTTP 200 with structured ChatbotResponse DTO | 2026-11-19 | Pass | Verified via automated test suite |
| TC-14 | Process authenticated student query with personalized context | POST /api/chat/query with valid student Bearer JWT | Response marks isAuthenticated=true and greets student by name | 2026-11-19 | Pass | Verified via automated test suite |
| TC-15 | Process anonymous visitor query without Bearer token | POST /api/chat/query without Authorization header | HTTP 200 with role='anonymous', isAuthenticated=false, and sess_ ID | 2026-11-19 | Pass | Verified via automated test suite |
| TC-16 | Reject malformed or invalid JWT token | POST /api/chat/query with 'Bearer invalid.jwt.token.here' | HTTP 401 Unauthorized error response | 2026-11-19 | Pass | Verified via automated test suite |
| TC-17 | Reject expired JWT token | POST /api/chat/query with JWT signed with past expiry | HTTP 401 Unauthorized with error code TOKEN_EXPIRED | 2026-11-19 | Pass | Verified via automated test suite |
| TC-18 | Retrieve matching FAQ context from MongoDB repository | Call mongoRepo.fetchSmartFAQs('merit scholarship') | Returns ranked SmartFAQ entries in Scholarships category | 2026-11-19 | Pass | Verified via automated test suite |
| TC-19 | Retrieve matching document chunks from Pinecone adapter | Call pineconeAdapter.searchVectorContext('BCS 522 Software Engineering Lab') | Returns relevant institutional document chunks with similarity scores | 2026-11-19 | Pass | Verified via automated test suite |
| TC-20 | Execute parallel context retrieval from MongoDB and Pinecone | Call queryProcessor.retrieveAndMergeContext() with multi-source query | Merged context includes both SmartFAQ and PineconeVectorDB items | 2026-11-19 | Pass | Verified via automated test suite |
| TC-21 | Handle missing context without hallucination | POST /api/chat/query with out-of-domain fictional topic | grounded=false and response advises contacting AUR Academic Office | 2026-11-19 | Pass | Verified via automated test suite |
| TC-22 | Merge multi-source context without duplicate entries | Call retrieveAndMergeContext() on overlapping topic | All merged context titles are unique without duplication | 2026-11-19 | Pass | Verified via automated test suite |
| TC-23 | Generate grounded AI answer from retrieved institutional facts | POST /api/chat/query asking about minimum attendance rule | grounded=true and response accurately states 75% attendance requirement | 2026-11-19 | Pass | Verified via automated test suite |
| TC-24 | Translate grounded AI response into requested Hindi language | POST /api/chat/query with language='hi' | targetLanguage='hi', translationFailed=false, localized Hindi returned | 2026-11-19 | Pass | Verified via automated test suite |
| TC-25 | Fallback to English with notice for unsupported language | POST /api/chat/query with unsupported language='fr' | targetLanguage='en', unsupportedLanguage=true, fallback notice appended | 2026-11-19 | Pass | Verified via automated test suite |
| TC-26 | Handle AI generation service failure gracefully | Enable aiAdapter.simulateFailure=true and POST /api/chat/query | HTTP 200 safe fallback message with flags.aiFailed=true | 2026-11-19 | Pass | Verified via automated test suite |
| TC-27 | Handle translation failure by returning English text and flag | Enable translationAdapter.simulateFailure=true and request Hindi | Original English answer returned with flags.translationFailed=true | 2026-11-19 | Pass | Verified via automated test suite |
| TC-28 | Return ChatbotResponse linked to processorId and persist SessionLog | POST /api/chat/query and inspect persisted sessionLogs | Response links pr_ and rs_ IDs; SessionLog saved with matching sessionId | 2026-11-19 | Pass | Verified via automated test suite |
| TC-29 | Accept custom primary key ID of exactly 25 characters | Create SmartFAQ with 25-character faqId ('faq_exact_twentyfive_1234') | Record created and persisted without validation error | 2026-11-19 | Pass | Verified via automated test suite |
| TC-30 | Reject custom primary key ID of 26 or more characters | Attempt SmartFAQ creation with 26-character faqId | Rejected with 25-character maximum length validation error | 2026-11-19 | Pass | Verified via automated test suite |
| TC-31 | Reject duplicate primary key insertion | Attempt to insert SmartFAQ with existing PK 'faq_exam_01' | Rejected with DUPLICATE_PRIMARY_KEY conflict error | 2026-11-19 | Pass | Verified via automated test suite |
| TC-32 | Enforce foreign-key integrity across Query -> Processor -> Response | Insert processor with nonexistent queryId; verify valid chain links | Orphan FK rejected; valid execution chain links queryId and processorId | 2026-11-19 | Pass | Verified via automated test suite |
| TC-33 | Allow authenticated admin_staff access to logs and trending | GET /api/admin/logs and /api/admin/trending with admin_staff JWT | HTTP 200 returning sessions array and trending questions | 2026-11-19 | Pass | Verified via automated test suite |
| TC-34 | Reject unauthenticated or student access to /api/admin/* | GET /api/admin/logs without token and with student JWT | Returns HTTP 401 for unauthenticated and HTTP 403 for student role | 2026-11-19 | Pass | Verified via automated test suite |
| TC-35 | Filter recent chat logs by language and keyword | GET /api/admin/logs?language=hi&keyword=fee as admin_staff | Returns matching Hindi session logs containing keyword | 2026-11-19 | Pass | Verified via automated test suite |
| TC-36 | Inspect detailed session log transcript | GET /api/admin/logs/sess_demo_aur_01 as admin_staff | Returns queryText, responseText, and ISO timestamp for session | 2026-11-19 | Pass | Verified via automated test suite |
| TC-37 | Create new Smart FAQ entry with valid fields | POST /api/admin/faqs with valid faqId, question, answerText, category | HTTP 201 Created returning persisted SmartFAQ record | 2026-11-19 | Pass | Verified via automated test suite |
| TC-38 | Update existing Smart FAQ in place without duplication | PUT /api/admin/faqs/faq_admin_new_01 with updated answerText | HTTP 200 Updated; total FAQ collection count remains unchanged | 2026-11-19 | Pass | Verified via automated test suite |
| TC-39 | Reject Smart FAQ creation when required fields are missing | POST /api/admin/faqs omitting answerText and category | HTTP 400 Bad Request validation failure | 2026-11-19 | Pass | Verified via automated test suite |
| TC-40 | Persist new Smart FAQ for public listing and RAG queries | GET /api/faqs and POST /api/chat/query matching newly added FAQ | Public endpoint lists new FAQ and chatbot answers using updated text | 2026-11-19 | Pass | Verified via automated test suite |
| TC-41 | Auto-update lastUpdated timestamp on Smart FAQ edit | Modify Smart FAQ via PUT /api/admin/faqs/:faqId and compare timestamp | lastUpdated ISO timestamp advances automatically | 2026-11-19 | Pass | Verified via automated test suite |
| TC-42 | Reject Smart FAQ creation with faqId exceeding 25 characters | POST /api/admin/faqs with 40-character faqId | HTTP 400 Bad Request rejecting >25-char faqId | 2026-11-19 | Pass | Verified via automated test suite |
| TC-43 | Maintain association between ChatSessionHistory, widgetId, and sessionId | Submit query with sessionId and inspect admin session history detail | ChatSessionHistory records link matching widgetId and sessionId | 2026-11-19 | Pass | Verified via automated test suite |
| TC-44 | Return server health telemetry (uptime, memory, DB status) | GET /api/sysadmin/health with system_admin JWT | HTTP 200 with uptimeSeconds, memory.rssMb, and database.connected=true | 2026-11-19 | Pass | Verified via automated test suite |
| TC-45 | Report external API availability (OpenAI, Pinecone, Translate) | GET /api/sysadmin/health and inspect externalServices | Reports availability flags for OpenAI, Pinecone, and Google Translate | 2026-11-19 | Pass | Verified via automated test suite |
| TC-46 | Reject expired system_admin credentials | GET /api/sysadmin/health with expired system_admin JWT | HTTP 401 Unauthorized | 2026-11-19 | Pass | Verified via automated test suite |
| TC-47 | Enforce API rate limits and return HTTP 429 with retry hint | Set rateLimitMax=2 and issue 3 rapid requests to /api/health | 3rd request receives HTTP 429 with retryAfterSeconds hint | 2026-11-19 | Pass | Verified via automated test suite |
| TC-48 | Update system configuration (rate limits & languages) for sysadmin | PUT /api/sysadmin/config with valid adminId, rateLimitMax, languages | HTTP 200 updated=true and rateLimits.maxRequests reflects new value | 2026-11-19 | Pass | Verified via automated test suite |
| TC-49 | Block non-system_admin roles from key rotation or config edits | Call /api/sysadmin/credentials/renew as admin_staff and config as student | Both requests rejected with HTTP 403 Forbidden | 2026-11-19 | Pass | Verified via automated test suite |
| TC-50 | Mask tokenSecret in all UI/API responses and rotate secret safely | GET /api/sysadmin/services and POST /api/sysadmin/credentials/renew | Raw activeSecret never appears in responses; maskedSecret='***MASKED***' | 2026-11-19 | Pass | Verified via automated test suite |
| TC-51 | Handle MongoDB repository failure gracefully without server crash | Set dbManager.simulateFailure=true and POST /api/chat/query | HTTP 200 returned with flags.mongoFailed=true using vector fallback | 2026-11-19 | Pass | Verified via automated test suite |
| TC-52 | Handle Pinecone outage gracefully using MongoDB-only context | Set pineconeAdapter.simulateFailure=true and POST /api/chat/query | HTTP 200 returned with flags.pineconeFailed=true and partialContext=true | 2026-11-19 | Pass | Verified via automated test suite |
| TC-53 | Validate adminId PK length (<=25 chars) and staffId FK integrity | PUT /api/sysadmin/config with >25-char adminId; test invalid staffId FK | HTTP 400 on >25-char adminId; FK violation error on invalid staffId | 2026-11-19 | Pass | Verified via automated test suite |
