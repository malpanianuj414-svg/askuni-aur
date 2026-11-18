const mongoose = require('mongoose');

const customIdValidator = {
  validator: function (v) {
    return typeof v === 'string' && v.trim().length > 0 && v.length <= 25;
  },
  message: (props) => `ID '${props.value}' must be a non-empty string of at most 25 characters.`
};

// 1. STUDENT(userId PK, preferredLanguage, isAuthenticated)
const studentSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true, validate: customIdValidator },
  preferredLanguage: { type: String, default: 'en' },
  isAuthenticated: { type: Boolean, default: false },
  name: { type: String, default: 'Visitor' },
  email: { type: String, default: '' },
  enrollmentNo: { type: String, default: '' },
  program: { type: String, default: 'B.Tech CSE' },
  semester: { type: Number, default: 5 },
  role: { type: String, enum: ['anonymous', 'student'], default: 'anonymous' },
  passwordHash: { type: String, default: '' }
}, { _id: false, versionKey: false });

// 2. CHATBOT_WIDGET(widgetId PK, userId FK, isVisible)
const chatbotWidgetSchema = new mongoose.Schema({
  widgetId: { type: String, required: true, unique: true, validate: customIdValidator },
  userId: { type: String, required: true, validate: customIdValidator },
  isVisible: { type: Boolean, default: true }
}, { _id: false, versionKey: false });

// 3. USER_QUERY(queryId PK, userId FK, widgetId FK, queryText, language, timestamp)
const userQuerySchema = new mongoose.Schema({
  queryId: { type: String, required: true, unique: true, validate: customIdValidator },
  userId: { type: String, required: true, validate: customIdValidator },
  widgetId: { type: String, required: true, validate: customIdValidator },
  queryText: { type: String, required: true, trim: true, minLength: 1 },
  language: { type: String, default: 'en' },
  timestamp: { type: String, required: true }
}, { _id: false, versionKey: false });

// 4. BACKEND_QUERY_PROCESSOR(processorId PK, queryId FK, activeSessionId, dbUri, indexName, apiEndpoint)
const backendQueryProcessorSchema = new mongoose.Schema({
  processorId: { type: String, required: true, unique: true, validate: customIdValidator },
  queryId: { type: String, required: true, validate: customIdValidator },
  activeSessionId: { type: String, required: true },
  dbUri: { type: String, required: true },
  indexName: { type: String, required: true },
  apiEndpoint: { type: String, required: true }
}, { _id: false, versionKey: false });

// 5. CHATBOT_RESPONSE(responseId PK, processorId FK, generatedText, translatedText, targetLanguage)
const chatbotResponseSchema = new mongoose.Schema({
  responseId: { type: String, required: true, unique: true, validate: customIdValidator },
  processorId: { type: String, required: true, validate: customIdValidator },
  generatedText: { type: String, required: true },
  translatedText: { type: String, required: true },
  targetLanguage: { type: String, default: 'en' }
}, { _id: false, versionKey: false });

// 6. CHAT_SESSION_HISTORY(historyId PK, widgetId FK, sessionId, messageText, timestamp, role user|assistant)
const chatSessionHistorySchema = new mongoose.Schema({
  historyId: { type: String, required: true, unique: true, validate: customIdValidator },
  widgetId: { type: String, required: true, validate: customIdValidator },
  sessionId: { type: String, required: true },
  messageText: { type: String, required: true },
  timestamp: { type: String, required: true },
  role: { type: String, enum: ['user', 'assistant'], required: true }
}, { _id: false, versionKey: false });

// 7. SESSION_LOG(logId PK, dbUri, sessionId, queryText, responseText, timestamp)
const sessionLogSchema = new mongoose.Schema({
  logId: { type: String, required: true, unique: true, validate: customIdValidator },
  dbUri: { type: String, required: true },
  sessionId: { type: String, required: true },
  userId: { type: String, default: 'anon_guest' },
  queryText: { type: String, required: true },
  responseText: { type: String, required: true },
  language: { type: String, default: 'en' },
  timestamp: { type: String, required: true }
}, { _id: false, versionKey: false });

// 8. SMART_FAQ(faqId PK, dbUri, question, answerText, category, lastUpdated)
const smartFaqSchema = new mongoose.Schema({
  faqId: { type: String, required: true, unique: true, validate: customIdValidator },
  dbUri: { type: String, required: true },
  question: { type: String, required: true, trim: true, minLength: 3 },
  answerText: { type: String, required: true, trim: true, minLength: 3 },
  category: { type: String, required: true, trim: true },
  lastUpdated: { type: String, required: true }
}, { _id: false, versionKey: false });

// 9. ADMIN_STAFF(staffId PK, dbUri, indexName, role)
const adminStaffSchema = new mongoose.Schema({
  staffId: { type: String, required: true, unique: true, validate: customIdValidator },
  dbUri: { type: String, required: true },
  indexName: { type: String, required: true },
  role: { type: String, default: 'admin_staff' },
  username: { type: String, required: true },
  name: { type: String, default: 'Admin Staff' },
  passwordHash: { type: String, required: true }
}, { _id: false, versionKey: false });

// 10. SYSTEM_ADMINISTRATOR(adminId PK, staffId FK, apiEndpoint, role)
const systemAdministratorSchema = new mongoose.Schema({
  adminId: { type: String, required: true, unique: true, validate: customIdValidator },
  staffId: { type: String, required: true, validate: customIdValidator },
  apiEndpoint: { type: String, required: true },
  role: { type: String, default: 'system_admin' },
  username: { type: String, required: true },
  name: { type: String, default: 'System Administrator' },
  passwordHash: { type: String, required: true }
}, { _id: false, versionKey: false });

// 11. SERVICE_CONFIG (JWT_AUTH_SERVICE, MONGODB_REPOSITORY, PINECONE_VECTOR_DB, PINECONE_VECTOR_ADAPTER, AI_TRANSLATION_SERVICE)
const serviceConfigSchema = new mongoose.Schema({
  configId: { type: String, required: true, unique: true, validate: customIdValidator },
  serviceName: { type: String, required: true },
  supportedLanguages: { type: [String], default: ['en', 'hi', 'mr', 'ta', 'bn', 'pa'] },
  rateLimitMax: { type: Number, default: 120 },
  rateLimitWindowMs: { type: Number, default: 60000 },
  apiEndpoint: { type: String, default: '' },
  indexName: { type: String, default: '' },
  dbUri: { type: String, default: '' },
  maskedSecretHint: { type: String, default: '***MASKED***' },
  updatedAt: { type: String, required: true }
}, { _id: false, versionKey: false });

const Models = {
  Student: mongoose.models.Student || mongoose.model('Student', studentSchema),
  ChatbotWidget: mongoose.models.ChatbotWidget || mongoose.model('ChatbotWidget', chatbotWidgetSchema),
  UserQuery: mongoose.models.UserQuery || mongoose.model('UserQuery', userQuerySchema),
  BackendQueryProcessor: mongoose.models.BackendQueryProcessor || mongoose.model('BackendQueryProcessor', backendQueryProcessorSchema),
  ChatbotResponse: mongoose.models.ChatbotResponse || mongoose.model('ChatbotResponse', chatbotResponseSchema),
  ChatSessionHistory: mongoose.models.ChatSessionHistory || mongoose.model('ChatSessionHistory', chatSessionHistorySchema),
  SessionLog: mongoose.models.SessionLog || mongoose.model('SessionLog', sessionLogSchema),
  SmartFAQ: mongoose.models.SmartFAQ || mongoose.model('SmartFAQ', smartFaqSchema),
  AdminStaff: mongoose.models.AdminStaff || mongoose.model('AdminStaff', adminStaffSchema),
  SystemAdministrator: mongoose.models.SystemAdministrator || mongoose.model('SystemAdministrator', systemAdministratorSchema),
  ServiceConfig: mongoose.models.ServiceConfig || mongoose.model('ServiceConfig', serviceConfigSchema)
};

module.exports = { Models, customIdValidator };