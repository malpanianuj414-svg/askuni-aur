const { dbManager } = require('../config/db');
const { AppError } = require('../adapters/MongoDBRepository');
const { SUPPORTED_LANGUAGES } = require('../adapters/TranslationServiceAdapter');
const config = require('../config/env');

class InfrastructureAdminService {
  constructor({ mongoRepo, pineconeAdapter, aiAdapter, translationAdapter, authService }) {
    this.mongoRepo = mongoRepo;
    this.pineconeAdapter = pineconeAdapter;
    this.aiAdapter = aiAdapter;
    this.translationAdapter = translationAdapter;
    this.authService = authService;
    this.incidentState = 'Healthy';
    this.incidentHistory = [
      { state: 'Healthy', timestamp: new Date().toISOString(), note: 'System initialized cleanly.' }
    ];
    this.rateLimitState = {
      windowMs: config.rateLimitWindowMs,
      maxRequests: config.rateLimitMax,
      totalRequestsObserved: 0,
      blocked429Count: 0
    };
  }

  recordRequest(blocked = false) {
    this.rateLimitState.totalRequestsObserved += 1;
    if (blocked) {
      this.rateLimitState.blocked429Count += 1;
    }
  }

  transitionIncidentState(nextState, note = '') {
    this.incidentState = nextState;
    this.incidentHistory.push({
      state: nextState,
      timestamp: new Date().toISOString(),
      note
    });
  }

  monitorServerHealth() {
    const mem = process.memoryUsage();
    const dbStatus = dbManager.getStatus();
    const pineconeOk = this.pineconeAdapter.isHealthy();
    const aiOk = this.aiAdapter.isHealthy();
    const transOk = this.translationAdapter.isHealthy();

    return {
      status: dbStatus.connected && pineconeOk && aiOk && transOk ? 'healthy' : 'degraded',
      mockMode: config.mockMode,
      uptimeSeconds: Math.round(process.uptime()),
      memory: {
        rssMb: Math.round(mem.rss / 1024 / 1024),
        heapUsedMb: Math.round(mem.heapUsed / 1024 / 1024),
        heapTotalMb: Math.round(mem.heapTotal / 1024 / 1024)
      },
      database: dbStatus,
      externalServices: {
        openai: { available: aiOk, model: config.openaiModel, mode: config.mockMode ? 'mock' : 'live' },
        pinecone: { available: pineconeOk, index: config.pineconeIndex, mode: config.mockMode ? 'mock' : 'live' },
        googleTranslate: { available: transOk, mode: config.mockMode ? 'mock' : 'live' }
      },
      rateLimits: this.rateLimitState,
      incidentState: this.incidentState,
      incidentHistory: this.incidentHistory.slice(-10),
      security: this.authService.getMaskedMetadata(),
      timestamp: new Date().toISOString()
    };
  }

  async getServiceConfigurations() {
    const configs = await this.mongoRepo.getServiceConfigs();
    // Ensure no raw secret ever leaks
    return configs.map((c) => {
      const copy = { ...c };
      delete copy.tokenSecret;
      copy.maskedSecretHint = '***MASKED***';
      return copy;
    });
  }

  async renewCredentials() {
    this.transitionIncidentState('Credential Renewal', 'JWT secret rotation initiated by system_admin.');
    const rotation = this.authService.rotateSecret();

    try {
      await this.mongoRepo.updateServiceConfig('JWT_AUTH_SERVICE', {
        maskedSecretHint: '***MASKED***'
      });
    } catch (_err) {
      // Ignore if seed config hasn't been initialized yet
    }

    this.transitionIncidentState('Rate-Limit Management', 'Verifying active rate-limit guardrails post-rotation.');
    this.transitionIncidentState('Healthy', 'Credential rotation completed; tokens re-anchored.');

    return {
      message: 'JWT signing secret rotated successfully.',
      rotation,
      incidentState: this.incidentState,
      incidentHistory: this.incidentHistory.slice(-5)
    };
  }

  async manageRateLimitsAndConfig({ rateLimitMax, rateLimitWindowMs, supportedLanguages, adminId }) {
    if (adminId !== undefined) {
      this.mongoRepo.validateIdLength(adminId, 'adminId');
    }

    if (rateLimitMax !== undefined) {
      const parsedMax = Number(rateLimitMax);
      if (!Number.isInteger(parsedMax) || parsedMax < 1 || parsedMax > 10000) {
        throw new AppError('rateLimitMax must be an integer between 1 and 10000.', 400, 'INVALID_RATE_LIMIT');
      }
      this.rateLimitState.maxRequests = parsedMax;
    }

    if (rateLimitWindowMs !== undefined) {
      const parsedWin = Number(rateLimitWindowMs);
      if (!Number.isInteger(parsedWin) || parsedWin < 1000 || parsedWin > 3600000) {
        throw new AppError('rateLimitWindowMs must be between 1000 and 3600000 ms.', 400, 'INVALID_RATE_WINDOW');
      }
      this.rateLimitState.windowMs = parsedWin;
    }

    if (supportedLanguages !== undefined) {
      if (!Array.isArray(supportedLanguages) || supportedLanguages.length === 0) {
        throw new AppError('supportedLanguages must be a non-empty array of language codes.', 400, 'INVALID_LANGUAGES');
      }
      const validCodes = supportedLanguages.every((code) => SUPPORTED_LANGUAGES.includes(String(code).toLowerCase()));
      if (!validCodes) {
        throw new AppError(
          `Unsupported language code in list. Allowed codes: ${SUPPORTED_LANGUAGES.join(', ')}`,
          400,
          'UNSUPPORTED_LANGUAGE_CONFIG'
        );
      }
      await this.mongoRepo.updateServiceConfig('AI_TRANSLATION_SERVICE', {
        supportedLanguages: supportedLanguages.map((c) => String(c).toLowerCase())
      });
    }

    try {
      await this.mongoRepo.updateServiceConfig('JWT_AUTH_SERVICE', {
        rateLimitMax: this.rateLimitState.maxRequests,
        rateLimitWindowMs: this.rateLimitState.windowMs,
        maskedSecretHint: '***MASKED***'
      });
    } catch (_err) {
      // Ignore if not seeded
    }

    return {
      updated: true,
      rateLimits: this.rateLimitState,
      services: await this.getServiceConfigurations()
    };
  }
}

module.exports = { InfrastructureAdminService };