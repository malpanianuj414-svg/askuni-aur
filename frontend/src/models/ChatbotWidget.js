export const WIDGET_STATES = {
  HIDDEN: 'hidden',
  INITIALIZED: 'initialized',
  ACTIVE: 'active',
  AWAITING_INPUT: 'awaiting input',
  QUERY_SUBMITTED: 'query submitted',
  PROCESSING: 'processing',
  RESPONSE_DISPLAYED: 'response displayed'
};

export class UserQuery {
  constructor({ queryId, userId, widgetId, queryText, language = 'auto', sessionId = '' }) {
    this.queryId = queryId || `q_${Date.now().toString(36)}`.slice(0, 25);
    this.userId = userId || 'anon_visitor';
    this.widgetId = widgetId || 'w_default';
    this.queryText = typeof queryText === 'string' ? queryText : '';
    this.language = language || 'auto';
    this.sessionId = sessionId;
    this.timestamp = new Date().toISOString();
  }

  validatePayload() {
    if (typeof this.queryText !== 'string' || this.queryText.trim().length === 0) {
      return {
        valid: false,
        error: 'Please enter a valid question (empty or whitespace-only queries are not allowed).'
      };
    }
    if (this.queryText.trim().length > 1000) {
      return {
        valid: false,
        error: 'Question exceeds maximum length of 1000 characters.'
      };
    }
    return { valid: true, error: null };
  }

  toJSON() {
    return {
      queryId: this.queryId,
      userId: this.userId,
      widgetId: this.widgetId,
      queryText: this.queryText.trim(),
      language: this.language,
      sessionId: this.sessionId,
      timestamp: this.timestamp
    };
  }
}

export class ChatbotResponse {
  constructor(apiData = {}) {
    this.responseId = apiData.responseId || `rs_${Date.now().toString(36)}`;
    this.processorId = apiData.processorId || '';
    this.generatedText = apiData.generatedText || '';
    this.translatedText = apiData.translatedText || apiData.generatedText || '';
    this.targetLanguage = apiData.targetLanguage || 'en';
    this.grounded = Boolean(apiData.grounded);
    this.sources = Array.isArray(apiData.sources) ? apiData.sources : [];
    this.flags = apiData.flags || {};
    this.notice = apiData.notice || null;
    this.timestamp = apiData.timestamp || new Date().toISOString();
  }

  formatForDisplay() {
    return {
      id: this.responseId,
      role: 'assistant',
      text: this.translatedText,
      originalText: this.generatedText,
      language: this.targetLanguage,
      grounded: this.grounded,
      sources: this.sources,
      flags: this.flags,
      notice: this.notice,
      formattedTime: new Date(this.timestamp).toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit'
      }),
      timestamp: this.timestamp
    };
  }
}

export class ChatbotWidget {
  constructor({ widgetId = 'w_aur_main', userId = 'anon_visitor', preferredLanguage = 'auto' } = {}) {
    this.widgetId = widgetId;
    this.userId = userId;
    this.preferredLanguage = preferredLanguage;
    this.isVisible = false;
    this.isMinimized = false;
    this.state = WIDGET_STATES.HIDDEN;
    this.sessionId = `sess_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    this.history = [];
  }

  initialize(sessionData = {}) {
    if (sessionData.sessionId) this.sessionId = sessionData.sessionId;
    if (sessionData.userId) this.userId = sessionData.userId;
    if (sessionData.widgetId) this.widgetId = sessionData.widgetId;
    this.isVisible = true;
    this.isMinimized = false;
    this.state = WIDGET_STATES.INITIALIZED;
    return this.getSnapshot();
  }

  renderInterface() {
    this.isVisible = true;
    this.isMinimized = false;
    this.state = WIDGET_STATES.AWAITING_INPUT;
    return this.getSnapshot();
  }

  captureInput(rawText, language = this.preferredLanguage) {
    const query = new UserQuery({
      userId: this.userId,
      widgetId: this.widgetId,
      queryText: rawText,
      language,
      sessionId: this.sessionId
    });
    const validation = query.validatePayload();
    if (!validation.valid) {
      return { ok: false, error: validation.error, query: null };
    }
    this.state = WIDGET_STATES.QUERY_SUBMITTED;
    this.history.push({
      historyId: `hu_${Date.now().toString(36)}`,
      widgetId: this.widgetId,
      sessionId: this.sessionId,
      role: 'user',
      text: query.queryText.trim(),
      language,
      formattedTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      timestamp: query.timestamp
    });
    this.state = WIDGET_STATES.PROCESSING;
    return { ok: true, error: null, query };
  }

  displayResponse(rawApiData) {
    if (rawApiData && rawApiData.sessionId) {
      this.sessionId = rawApiData.sessionId;
    }
    const dto = new ChatbotResponse(rawApiData);
    const formatted = dto.formatForDisplay();
    this.history.push({
      historyId: formatted.id,
      widgetId: this.widgetId,
      sessionId: this.sessionId,
      ...formatted
    });
    this.state = WIDGET_STATES.RESPONSE_DISPLAYED;
    return formatted;
  }

  minimize() {
    this.isMinimized = true;
    this.state = WIDGET_STATES.ACTIVE;
    return this.getSnapshot();
  }

  close() {
    this.isVisible = false;
    this.isMinimized = false;
    this.state = WIDGET_STATES.HIDDEN;
    return this.getSnapshot();
  }

  getSnapshot() {
    return {
      widgetId: this.widgetId,
      userId: this.userId,
      preferredLanguage: this.preferredLanguage,
      isVisible: this.isVisible,
      isMinimized: this.isMinimized,
      state: this.state,
      sessionId: this.sessionId,
      history: [...this.history]
    };
  }
}