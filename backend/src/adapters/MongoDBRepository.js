const { Models } = require('../models/schemas');
const { dbManager } = require('../config/db');
const config = require('../config/env');

class AppError extends Error {
  constructor(message, statusCode = 400, code = 'VALIDATION_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

const COLLECTION_MODEL_MAP = {
  students: { model: Models.Student, pk: 'userId' },
  widgets: { model: Models.ChatbotWidget, pk: 'widgetId' },
  userQueries: { model: Models.UserQuery, pk: 'queryId' },
  processors: { model: Models.BackendQueryProcessor, pk: 'processorId' },
  responses: { model: Models.ChatbotResponse, pk: 'responseId' },
  sessionHistory: { model: Models.ChatSessionHistory, pk: 'historyId' },
  sessionLogs: { model: Models.SessionLog, pk: 'logId' },
  smartFaqs: { model: Models.SmartFAQ, pk: 'faqId' },
  adminStaff: { model: Models.AdminStaff, pk: 'staffId' },
  systemAdmins: { model: Models.SystemAdministrator, pk: 'adminId' },
  serviceConfigs: { model: Models.ServiceConfig, pk: 'configId' }
};

class MongoDBRepository {
  constructor() {
    this.dbUri = config.mockMode
      ? 'mock://local-json-store/askuni_aur'
      : `${config.mongodbUri.replace(/\/\/.*@/, '//***:***@')}/${config.mongodbDbName}`;
  }

  async assertAvailable() {
    if (dbManager.simulateFailure) {
      throw new AppError('MongoDB repository is currently unreachable.', 503, 'MONGODB_UNAVAILABLE');
    }
    if (!dbManager.connected) {
      await dbManager.connect();
    }
  }

  validateMongooseDoc(ModelClass, doc) {
    const instance = new ModelClass(doc);
    const err = instance.validateSync();
    if (err) {
      const firstKey = Object.keys(err.errors)[0];
      const msg = firstKey ? err.errors[firstKey].message : err.message;
      throw new AppError(msg, 400, 'SCHEMA_VALIDATION_ERROR');
    }
    const clean = instance.toObject();
    delete clean._id;
    delete clean.__v;
    return clean;
  }

  validateIdLength(id, fieldName = 'id') {
    if (typeof id !== 'string' || id.trim().length === 0 || id.length > 25) {
      throw new AppError(
        `${fieldName} '${id}' is invalid: custom IDs must be 1 to 25 characters (received ${typeof id === 'string' ? id.length : 0}).`,
        400,
        'INVALID_ID_LENGTH'
      );
    }
  }

  async insertRecord(collectionKey, pkField, ModelClass, record, foreignChecks = []) {
    await this.assertAvailable();
    this.validateIdLength(record[pkField], pkField);
    const cleanDoc = this.validateMongooseDoc(ModelClass, record);

    if (config.mockMode) {
      const list = dbManager.store[collectionKey];
      if (list.some((item) => item[pkField] === cleanDoc[pkField])) {
        throw new AppError(
          `Duplicate primary key '${cleanDoc[pkField]}' for ${pkField} in ${collectionKey}.`,
          409,
          'DUPLICATE_PRIMARY_KEY'
        );
      }

      for (const fk of foreignChecks) {
        const fkVal = cleanDoc[fk.field];
        this.validateIdLength(fkVal, fk.field);
        const targetList = dbManager.store[fk.targetCollection] || [];
        const exists = targetList.some((row) => row[fk.targetField] === fkVal);
        if (!exists) {
          throw new AppError(
            `Foreign key constraint failed: ${fk.field}='${fkVal}' does not exist in ${fk.targetCollection}.${fk.targetField}.`,
            400,
            'FOREIGN_KEY_VIOLATION'
          );
        }
      }

      list.push(cleanDoc);
      dbManager.saveToDisk();
      return cleanDoc;
    }

    // Live MongoDB Atlas path
    const existing = await ModelClass.findOne({ [pkField]: cleanDoc[pkField] }).lean();
    if (existing) {
      throw new AppError(
        `Duplicate primary key '${cleanDoc[pkField]}' for ${pkField} in ${collectionKey}.`,
        409,
        'DUPLICATE_PRIMARY_KEY'
      );
    }

    for (const fk of foreignChecks) {
      const fkVal = cleanDoc[fk.field];
      this.validateIdLength(fkVal, fk.field);
      const targetMeta = COLLECTION_MODEL_MAP[fk.targetCollection];
      const exists = targetMeta
        ? await targetMeta.model.findOne({ [fk.targetField]: fkVal }).lean()
        : null;
      if (!exists) {
        throw new AppError(
          `Foreign key constraint failed: ${fk.field}='${fkVal}' does not exist in ${fk.targetCollection}.${fk.targetField}.`,
          400,
          'FOREIGN_KEY_VIOLATION'
        );
      }
    }

    const created = await ModelClass.create(cleanDoc);
    const saved = created.toObject();
    delete saved._id;
    delete saved.__v;
    return saved;
  }

  async ensureStudentAndWidget(userId, preferredLanguage = 'en', isAuthenticated = false, name = 'Visitor') {
    await this.assertAvailable();
    this.validateIdLength(userId, 'userId');

    let student;
    if (config.mockMode) {
      student = dbManager.store.students.find((s) => s.userId === userId);
      if (!student) {
        student = await this.insertRecord('students', 'userId', Models.Student, {
          userId,
          preferredLanguage,
          isAuthenticated,
          name,
          role: isAuthenticated ? 'student' : 'anonymous'
        });
      } else if (preferredLanguage && student.preferredLanguage !== preferredLanguage) {
        student.preferredLanguage = preferredLanguage;
        dbManager.saveToDisk();
      }
    } else {
      student = await Models.Student.findOne({ userId }).lean();
      if (!student) {
        student = await this.insertRecord('students', 'userId', Models.Student, {
          userId,
          preferredLanguage,
          isAuthenticated,
          name,
          role: isAuthenticated ? 'student' : 'anonymous'
        });
      } else if (preferredLanguage && student.preferredLanguage !== preferredLanguage) {
        await Models.Student.updateOne({ userId }, { $set: { preferredLanguage } });
        student.preferredLanguage = preferredLanguage;
      }
    }

    const widgetId = `w_${userId}`.slice(0, 25);
    let widget = config.mockMode
      ? dbManager.store.widgets.find((w) => w.widgetId === widgetId)
      : await Models.ChatbotWidget.findOne({ widgetId }).lean();

    if (!widget) {
      widget = await this.insertRecord(
        'widgets',
        'widgetId',
        Models.ChatbotWidget,
        { widgetId, userId, isVisible: true },
        [{ field: 'userId', targetCollection: 'students', targetField: 'userId' }]
      );
    }
    return { student, widget };
  }

  async findStudentByUsernameOrId(identifier) {
    await this.assertAvailable();
    const clean = String(identifier || '').trim();
    if (config.mockMode) {
      return dbManager.store.students.find(
        (s) =>
          s.userId === clean ||
          s.email.toLowerCase() === clean.toLowerCase() ||
          s.enrollmentNo.toLowerCase() === clean.toLowerCase()
      ) || null;
    }
    const regex = new RegExp(`^${clean.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i');
    return Models.Student.findOne({
      $or: [{ userId: clean }, { email: regex }, { enrollmentNo: regex }]
    }).lean();
  }

  async findAdminStaffByUsername(username) {
    await this.assertAvailable();
    const clean = String(username || '').trim();
    if (config.mockMode) {
      return dbManager.store.adminStaff.find((a) => a.username.toLowerCase() === clean.toLowerCase()) || null;
    }
    const regex = new RegExp(`^${clean.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i');
    return Models.AdminStaff.findOne({ username: regex }).lean();
  }

  async findSystemAdminByUsername(username) {
    await this.assertAvailable();
    const clean = String(username || '').trim();
    if (config.mockMode) {
      return dbManager.store.systemAdmins.find((a) => a.username.toLowerCase() === clean.toLowerCase()) || null;
    }
    const regex = new RegExp(`^${clean.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i');
    return Models.SystemAdministrator.findOne({ username: regex }).lean();
  }

  async fetchSmartFAQs(queryText = '', category = '') {
    await this.assertAvailable();
    let faqs = config.mockMode
      ? [...dbManager.store.smartFaqs]
      : await Models.SmartFAQ.find({}, { _id: 0, __v: 0 }).lean();

    if (category && category !== 'all') {
      faqs = faqs.filter((f) => f.category.toLowerCase() === category.toLowerCase());
    }
    if (!queryText || !queryText.trim()) {
      return faqs;
    }

    const tokens = queryText
      .toLowerCase()
      .replace(/[^\w\s\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0B80-\u0BFF]/g, ' ')
      .split(/\s+/)
      .filter((t) => t.length > 1);

    const scored = faqs.map((faq) => {
      const hay = `${faq.question} ${faq.answerText} ${faq.category}`.toLowerCase();
      let score = 0;
      for (const tok of tokens) {
        if (hay.includes(tok)) score += 1;
      }
      return { faq, score };
    });

    return scored
      .filter((item) => item.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5)
      .map((item) => item.faq);
  }

  async createFAQEntry({ faqId, question, answerText, category }) {
    await this.assertAvailable();
    const id = faqId || `faq_${Date.now().toString(36)}`.slice(0, 25);
    return this.insertRecord('smartFaqs', 'faqId', Models.SmartFAQ, {
      faqId: id,
      dbUri: this.dbUri,
      question,
      answerText,
      category,
      lastUpdated: new Date().toISOString()
    });
  }

  async updateFAQEntry(faqId, updates) {
    await this.assertAvailable();
    this.validateIdLength(faqId, 'faqId');

    if (config.mockMode) {
      const idx = dbManager.store.smartFaqs.findIndex((f) => f.faqId === faqId);
      if (idx === -1) {
        throw new AppError(`Smart FAQ '${faqId}' not found.`, 404, 'FAQ_NOT_FOUND');
      }
      const existing = dbManager.store.smartFaqs[idx];
      const merged = {
        ...existing,
        question: updates.question !== undefined ? updates.question : existing.question,
        answerText: updates.answerText !== undefined ? updates.answerText : existing.answerText,
        category: updates.category !== undefined ? updates.category : existing.category,
        lastUpdated: new Date().toISOString()
      };
      const validated = this.validateMongooseDoc(Models.SmartFAQ, merged);
      dbManager.store.smartFaqs[idx] = validated;
      dbManager.saveToDisk();
      return validated;
    }

    const existing = await Models.SmartFAQ.findOne({ faqId }, { _id: 0, __v: 0 }).lean();
    if (!existing) {
      throw new AppError(`Smart FAQ '${faqId}' not found.`, 404, 'FAQ_NOT_FOUND');
    }
    const merged = {
      ...existing,
      question: updates.question !== undefined ? updates.question : existing.question,
      answerText: updates.answerText !== undefined ? updates.answerText : existing.answerText,
      category: updates.category !== undefined ? updates.category : existing.category,
      lastUpdated: new Date().toISOString()
    };
    const validated = this.validateMongooseDoc(Models.SmartFAQ, merged);
    await Models.SmartFAQ.updateOne({ faqId }, { $set: validated });
    return validated;
  }

  async deleteFAQEntry(faqId) {
    await this.assertAvailable();
    this.validateIdLength(faqId, 'faqId');

    if (config.mockMode) {
      const idx = dbManager.store.smartFaqs.findIndex((f) => f.faqId === faqId);
      if (idx === -1) {
        throw new AppError(`Smart FAQ '${faqId}' not found.`, 404, 'FAQ_NOT_FOUND');
      }
      const [removed] = dbManager.store.smartFaqs.splice(idx, 1);
      dbManager.saveToDisk();
      return removed;
    }

    const existing = await Models.SmartFAQ.findOneAndDelete({ faqId }, { projection: { _id: 0, __v: 0 } }).lean();
    if (!existing) {
      throw new AppError(`Smart FAQ '${faqId}' not found.`, 404, 'FAQ_NOT_FOUND');
    }
    return existing;
  }

  async recordQueryExecutionChain({
    userQuery,
    processor,
    chatbotResponse,
    widgetId,
    sessionId,
    userId
  }) {
    await this.assertAvailable();

    const savedQuery = await this.insertRecord(
      'userQueries',
      'queryId',
      Models.UserQuery,
      userQuery,
      [
        { field: 'userId', targetCollection: 'students', targetField: 'userId' },
        { field: 'widgetId', targetCollection: 'widgets', targetField: 'widgetId' }
      ]
    );

    const savedProcessor = await this.insertRecord(
      'processors',
      'processorId',
      Models.BackendQueryProcessor,
      processor,
      [{ field: 'queryId', targetCollection: 'userQueries', targetField: 'queryId' }]
    );

    const savedResponse = await this.insertRecord(
      'responses',
      'responseId',
      Models.ChatbotResponse,
      chatbotResponse,
      [{ field: 'processorId', targetCollection: 'processors', targetField: 'processorId' }]
    );

    const nowIso = new Date().toISOString();
    const histUser = await this.insertRecord(
      'sessionHistory',
      'historyId',
      Models.ChatSessionHistory,
      {
        historyId: `hu_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25),
        widgetId,
        sessionId,
        messageText: userQuery.queryText,
        timestamp: userQuery.timestamp || nowIso,
        role: 'user'
      },
      [{ field: 'widgetId', targetCollection: 'widgets', targetField: 'widgetId' }]
    );

    const histBot = await this.insertRecord(
      'sessionHistory',
      'historyId',
      Models.ChatSessionHistory,
      {
        historyId: `hb_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25),
        widgetId,
        sessionId,
        messageText: chatbotResponse.translatedText,
        timestamp: nowIso,
        role: 'assistant'
      },
      [{ field: 'widgetId', targetCollection: 'widgets', targetField: 'widgetId' }]
    );

    const logEntry = await this.saveChatLog({
      logId: `lg_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25),
      dbUri: this.dbUri,
      sessionId,
      userId,
      queryText: userQuery.queryText,
      responseText: chatbotResponse.translatedText,
      language: chatbotResponse.targetLanguage,
      timestamp: nowIso
    });

    return { savedQuery, savedProcessor, savedResponse, histUser, histBot, logEntry };
  }

  async saveChatLog(logData) {
    await this.assertAvailable();
    return this.insertRecord('sessionLogs', 'logId', Models.SessionLog, logData);
  }

  async queryRecentSessions({ date = '', language = '', keyword = '' } = {}) {
    await this.assertAvailable();
    let logs = config.mockMode
      ? [...dbManager.store.sessionLogs]
      : await Models.SessionLog.find({}, { _id: 0, __v: 0 }).lean();

    if (date) {
      logs = logs.filter((l) => l.timestamp.startsWith(date));
    }
    if (language && language !== 'all') {
      logs = logs.filter((l) => l.language.toLowerCase() === language.toLowerCase());
    }
    if (keyword && keyword.trim()) {
      const kw = keyword.toLowerCase();
      logs = logs.filter(
        (l) =>
          l.queryText.toLowerCase().includes(kw) ||
          l.responseText.toLowerCase().includes(kw) ||
          l.sessionId.toLowerCase().includes(kw)
      );
    }

    logs.sort((a, b) => b.timestamp.localeCompare(a.timestamp));

    const sessionMap = new Map();
    for (const log of logs) {
      if (!sessionMap.has(log.sessionId)) {
        sessionMap.set(log.sessionId, {
          sessionId: log.sessionId,
          userId: log.userId,
          language: log.language,
          lastTimestamp: log.timestamp,
          latestQuery: log.queryText,
          latestResponse: log.responseText,
          turnCount: 0
        });
      }
      sessionMap.get(log.sessionId).turnCount += 1;
    }

    return {
      sessions: Array.from(sessionMap.values()),
      logs
    };
  }

  async getSessionDetail(sessionId) {
    await this.assertAvailable();
    const rawLogs = config.mockMode
      ? dbManager.store.sessionLogs.filter((l) => l.sessionId === sessionId)
      : await Models.SessionLog.find({ sessionId }, { _id: 0, __v: 0 }).lean();

    const rawHistory = config.mockMode
      ? dbManager.store.sessionHistory.filter((h) => h.sessionId === sessionId)
      : await Models.ChatSessionHistory.find({ sessionId }, { _id: 0, __v: 0 }).lean();

    const logs = rawLogs.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
    const history = rawHistory.sort((a, b) => a.timestamp.localeCompare(b.timestamp));

    return { sessionId, logs, history };
  }

  async getTrendingQuestions() {
    await this.assertAvailable();
    const allLogs = config.mockMode
      ? dbManager.store.sessionLogs
      : await Models.SessionLog.find({}, { _id: 0, __v: 0 }).lean();

    const counts = new Map();
    for (const log of allLogs) {
      const normalized = log.queryText.trim();
      if (!normalized) continue;
      const key = normalized.toLowerCase();
      if (!counts.has(key)) {
        counts.set(key, {
          question: normalized,
          count: 0,
          lastAsked: log.timestamp,
          sampleResponse: log.responseText
        });
      }
      const entry = counts.get(key);
      entry.count += 1;
      if (log.timestamp > entry.lastAsked) {
        entry.lastAsked = log.timestamp;
        entry.sampleResponse = log.responseText;
      }
    }
    return Array.from(counts.values()).sort((a, b) => b.count - a.count).slice(0, 10);
  }

  async getServiceConfigs() {
    await this.assertAvailable();
    if (config.mockMode) {
      return dbManager.store.serviceConfigs;
    }
    return Models.ServiceConfig.find({}, { _id: 0, __v: 0 }).lean();
  }

  async updateServiceConfig(configId, patch) {
    await this.assertAvailable();
    if (config.mockMode) {
      const idx = dbManager.store.serviceConfigs.findIndex((c) => c.configId === configId);
      if (idx === -1) {
        throw new AppError(`ServiceConfig '${configId}' not found.`, 404, 'CONFIG_NOT_FOUND');
      }
      const updated = {
        ...dbManager.store.serviceConfigs[idx],
        ...patch,
        updatedAt: new Date().toISOString()
      };
      const validated = this.validateMongooseDoc(Models.ServiceConfig, updated);
      dbManager.store.serviceConfigs[idx] = validated;
      dbManager.saveToDisk();
      return validated;
    }

    const existing = await Models.ServiceConfig.findOne({ configId }, { _id: 0, __v: 0 }).lean();
    if (!existing) {
      throw new AppError(`ServiceConfig '${configId}' not found.`, 404, 'CONFIG_NOT_FOUND');
    }
    const updated = {
      ...existing,
      ...patch,
      updatedAt: new Date().toISOString()
    };
    const validated = this.validateMongooseDoc(Models.ServiceConfig, updated);
    await Models.ServiceConfig.updateOne({ configId }, { $set: validated });
    return validated;
  }
}

module.exports = { MongoDBRepository, AppError };