const { AppError } = require('../adapters/MongoDBRepository');
const config = require('../config/env');

class BackendQueryProcessor {
  constructor({ mongoRepo, pineconeAdapter, aiAdapter, translationAdapter, authService }) {
    this.mongoRepo = mongoRepo;
    this.pineconeAdapter = pineconeAdapter;
    this.aiAdapter = aiAdapter;
    this.translationAdapter = translationAdapter;
    this.authService = authService;
  }

  receiveQuery(rawBody) {
    if (!rawBody || typeof rawBody.queryText !== 'string' || rawBody.queryText.trim().length === 0) {
      throw new AppError('Query text cannot be empty or whitespace only.', 400, 'EMPTY_QUERY');
    }
    const cleanText = rawBody.queryText.trim();
    const detectedLang = this.translationAdapter.detectLanguage(cleanText);
    const requestedLang = rawBody.language && rawBody.language !== 'auto'
      ? String(rawBody.language).trim().toLowerCase()
      : detectedLang;

    const queryId = rawBody.queryId || `q_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.slice(0, 25);
    const sessionId = rawBody.sessionId || `sess_${Date.now().toString(36)}`;

    return {
      queryId,
      sessionId,
      queryText: cleanText,
      language: requestedLang,
      detectedLanguage: detectedLang,
      timestamp: new Date().toISOString()
    };
  }

  authenticateRequest(authHeader) {
    return this.authService.verifyUserStatus(authHeader);
  }

  async retrieveAndMergeContext(queryText) {
    const searchQuery = this.translationAdapter.normalizeQueryToEnglish(queryText);

    const [mongoResult, pineconeResult] = await Promise.allSettled([
      this.mongoRepo.fetchSmartFAQs(searchQuery),
      this.pineconeAdapter.searchVectorContext(searchQuery, 4)
    ]);

    const flags = {
      mongoFailed: mongoResult.status === 'rejected',
      pineconeFailed: pineconeResult.status === 'rejected',
      partialContext: false
    };

    const faqs = mongoResult.status === 'fulfilled' ? mongoResult.value : [];
    const docs = pineconeResult.status === 'fulfilled' ? pineconeResult.value : [];

    if (flags.pineconeFailed && !flags.mongoFailed) {
      flags.partialContext = true;
    }

    // Merge and deduplicate context items
    const merged = [];
    const seen = new Set();

    for (const faq of faqs) {
      const key = faq.question.toLowerCase().trim();
      if (!seen.has(key)) {
        seen.add(key);
        merged.push({
          source: 'SmartFAQ',
          id: faq.faqId,
          title: faq.question,
          category: faq.category,
          text: faq.answerText
        });
      }
    }

    for (const doc of docs) {
      const key = doc.title.toLowerCase().trim();
      if (!seen.has(key)) {
        seen.add(key);
        merged.push({
          source: 'PineconeVectorDB',
          id: doc.docId,
          title: doc.title,
          category: doc.category,
          text: doc.content
        });
      }
    }

    return { mergedContext: merged, flags };
  }

  async orchestrateAIResponse(rawBody, authHeader) {
    const normalized = this.receiveQuery(rawBody);
    const authUser = this.authenticateRequest(authHeader);

    const effectiveUserId = authUser.userId || rawBody.userId || `anon_${normalized.sessionId.slice(-8)}`.slice(0, 25);

    let studentAndWidget = null;
    try {
      studentAndWidget = await this.mongoRepo.ensureStudentAndWidget(
        effectiveUserId,
        normalized.language,
        authUser.isAuthenticated,
        authUser.name
      );
    } catch (_dbErr) {
      // Allow graceful continuation if DB write is temporarily unavailable
      studentAndWidget = {
        student: { userId: effectiveUserId, preferredLanguage: normalized.language, isAuthenticated: authUser.isAuthenticated },
        widget: { widgetId: `w_${effectiveUserId}`.slice(0, 25), userId: effectiveUserId, isVisible: true }
      };
    }

    const { mergedContext, flags } = await this.retrieveAndMergeContext(normalized.queryText);

    // Fetch supportedLanguages from service config if available
    let supportedLanguages = ['en', 'hi', 'mr', 'ta', 'bn', 'pa'];
    try {
      const configs = await this.mongoRepo.getServiceConfigs();
      const transCfg = configs.find((c) => c.configId === 'AI_TRANSLATION_SERVICE');
      if (transCfg && Array.isArray(transCfg.supportedLanguages) && transCfg.supportedLanguages.length > 0) {
        supportedLanguages = transCfg.supportedLanguages;
      }
    } catch (_err) {
      // Use default supported languages
    }

    let aiOutput;
    let aiFailed = false;
    try {
      aiOutput = await this.aiAdapter.generateGroundedAnswer({
        queryText: normalized.queryText,
        mergedContext,
        userContext: authUser
      });
    } catch (err) {
      aiFailed = true;
      aiOutput = {
        text: 'We encountered a temporary issue generating an AI response. Please try again shortly or contact the Amity University Rajasthan Helpdesk.',
        grounded: false,
        sourceCount: 0,
        error: err.message
      };
    }

    const translationOutput = await this.translationAdapter.translateText(
      aiOutput.text,
      normalized.language,
      supportedLanguages
    );

    const processorId = `pr_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.slice(0, 25);
    const responseId = `rs_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.slice(0, 25);

    const userQueryRecord = {
      queryId: normalized.queryId,
      userId: studentAndWidget.student.userId,
      widgetId: studentAndWidget.widget.widgetId,
      queryText: normalized.queryText,
      language: normalized.language,
      timestamp: normalized.timestamp
    };

    const processorRecord = {
      processorId,
      queryId: normalized.queryId,
      activeSessionId: normalized.sessionId,
      dbUri: this.mongoRepo.dbUri,
      indexName: this.pineconeAdapter.indexName || config.pineconeIndex,
      apiEndpoint: '/api/chat/query'
    };

    const responseRecord = {
      responseId,
      processorId,
      generatedText: aiOutput.text,
      translatedText: translationOutput.translatedText,
      targetLanguage: translationOutput.effectiveLanguage
    };

    let persisted = true;
    try {
      await this.mongoRepo.recordQueryExecutionChain({
        userQuery: userQueryRecord,
        processor: processorRecord,
        chatbotResponse: responseRecord,
        widgetId: studentAndWidget.widget.widgetId,
        sessionId: normalized.sessionId,
        userId: studentAndWidget.student.userId
      });
    } catch (_persistErr) {
      persisted = false;
    }

    return {
      responseId,
      processorId,
      queryId: normalized.queryId,
      sessionId: normalized.sessionId,
      userId: studentAndWidget.student.userId,
      widgetId: studentAndWidget.widget.widgetId,
      isAuthenticated: authUser.isAuthenticated,
      role: authUser.role,
      generatedText: aiOutput.text,
      translatedText: translationOutput.translatedText,
      targetLanguage: translationOutput.effectiveLanguage,
      requestedLanguage: normalized.language,
      grounded: aiOutput.grounded,
      sources: mergedContext.map((c) => ({ source: c.source, title: c.title, category: c.category })),
      flags: {
        mongoFailed: flags.mongoFailed,
        pineconeFailed: flags.pineconeFailed,
        partialContext: flags.partialContext,
        aiFailed,
        unsupportedLanguage: translationOutput.unsupportedLanguage,
        translationFailed: translationOutput.translationFailed,
        persisted
      },
      notice: translationOutput.failureReason || (flags.pineconeFailed ? 'Vector knowledge base unavailable; answered using Smart FAQs.' : null),
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = { BackendQueryProcessor };