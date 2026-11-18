class AdminStaffService {
  constructor({ mongoRepo, pineconeAdapter }) {
    this.mongoRepo = mongoRepo;
    this.pineconeAdapter = pineconeAdapter;
  }

  async reviewChatLogs(filters) {
    return this.mongoRepo.queryRecentSessions(filters);
  }

  async getSessionDetail(sessionId) {
    return this.mongoRepo.getSessionDetail(sessionId);
  }

  async getTrendingQuestions() {
    return this.mongoRepo.getTrendingQuestions();
  }

  async listSmartFAQs(category = '') {
    return this.mongoRepo.fetchSmartFAQs('', category);
  }

  async updateSmartFAQs(action, payload) {
    if (action === 'create') {
      return this.mongoRepo.createFAQEntry(payload);
    }
    if (action === 'update') {
      return this.mongoRepo.updateFAQEntry(payload.faqId, payload);
    }
    if (action === 'delete') {
      return this.mongoRepo.deleteFAQEntry(payload.faqId);
    }
    throw new Error(`Unsupported Smart FAQ action: ${action}`);
  }

  async uploadKnowledgeDocument({ title, category, content }) {
    const chunks = await this.pineconeAdapter.upsertDocument({ title, category, content });
    return {
      uploaded: true,
      chunksCreated: chunks.length,
      chunks
    };
  }
}

module.exports = { AdminStaffService };