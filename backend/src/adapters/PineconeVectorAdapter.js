const fs = require('fs');
const os = require('os');
const path = require('path');
const config = require('../config/env');

const SEED_KB_FILE = path.resolve(__dirname, '../../data/knowledge-base.json');
const KB_FILE = process.env.VERCEL ? path.join(os.tmpdir(), 'askuni-knowledge-base.json') : SEED_KB_FILE;

class PineconeVectorAdapter {
  constructor() {
    this.indexName = config.pineconeIndex;
    this.simulateFailure = false;
    this.documents = [];
    this.loadDocuments();
  }

  loadDocuments() {
    try {
      const sourceFile = fs.existsSync(KB_FILE) ? KB_FILE : SEED_KB_FILE;
      if (fs.existsSync(sourceFile)) {
        this.documents = JSON.parse(fs.readFileSync(sourceFile, 'utf8'));
      }
    } catch (_err) {
      this.documents = [];
    }
  }

  saveDocuments() {
    const dir = path.dirname(KB_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(KB_FILE, JSON.stringify(this.documents, null, 2), 'utf8');
  }

  // Deterministic lightweight bag-of-words embedding vector (16 dims) for mock mode
  async retrieveEmbeddings(text) {
    if (this.simulateFailure) {
      throw new Error('Pinecone embedding service unavailable');
    }
    if (!config.mockMode && config.openaiApiKey) {
      const resp = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.openaiApiKey}`
        },
        body: JSON.stringify({
          model: config.openaiEmbeddingModel,
          input: text
        })
      });
      if (!resp.ok) throw new Error(`OpenAI Embeddings HTTP ${resp.status}`);
      const data = await resp.json();
      return data.data[0].embedding;
    }

    const vec = new Array(16).fill(0);
    const clean = String(text || '').toLowerCase();
    for (let i = 0; i < clean.length; i += 1) {
      vec[i % 16] += clean.charCodeAt(i) / 1000;
    }
    const norm = Math.sqrt(vec.reduce((s, v) => s + v * v, 0)) || 1;
    return vec.map((v) => Number((v / norm).toFixed(4)));
  }

  async searchVectorContext(queryText, topK = 4) {
    if (this.simulateFailure) {
      throw new Error('Pinecone Vector DB connection timed out');
    }

    if (!config.mockMode && config.pineconeApiKey && config.pineconeHost) {
      const vector = await this.retrieveEmbeddings(queryText);
      const resp = await fetch(`${config.pineconeHost}/query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': config.pineconeApiKey
        },
        body: JSON.stringify({ vector, topK, includeMetadata: true })
      });
      if (!resp.ok) throw new Error(`Pinecone query HTTP ${resp.status}`);
      const json = await resp.json();
      return (json.matches || []).map((m) => ({
        docId: m.id,
        title: m.metadata?.title || 'Institutional Document',
        category: m.metadata?.category || 'Circular',
        content: m.metadata?.content || '',
        score: m.score || 0
      }));
    }

    // Mock TF-IDF / keyword overlap retrieval over local knowledge-base.json
    if (this.documents.length === 0) {
      this.loadDocuments();
    }

    const tokens = String(queryText || '')
      .toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter((t) => t.length > 1);

    if (tokens.length === 0) return [];

    const scored = this.documents.map((doc) => {
      const hay = `${doc.title} ${doc.category} ${doc.content}`.toLowerCase();
      let matches = 0;
      for (const tok of tokens) {
        if (hay.includes(tok)) {
          matches += doc.title.toLowerCase().includes(tok) ? 2 : 1;
        }
      }
      const score = Number((matches / (tokens.length + 2)).toFixed(3));
      return { ...doc, score };
    });

    return scored
      .filter((d) => d.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, topK);
  }

  async upsertDocument({ title, category, content }) {
    if (this.simulateFailure) {
      throw new Error('Pinecone Vector DB unavailable for upsert');
    }
    const cleanText = String(content || '').trim();
    const chunkSize = 500;
    const chunks = [];
    for (let i = 0; i < cleanText.length; i += chunkSize) {
      chunks.push(cleanText.slice(i, i + chunkSize));
    }
    if (chunks.length === 0) chunks.push('');

    const created = [];
    for (let idx = 0; idx < chunks.length; idx += 1) {
      const docId = `kb_${Date.now().toString(36)}_${idx}`.slice(0, 25);
      const embedding = await this.retrieveEmbeddings(chunks[idx]);
      const record = {
        docId,
        title: chunks.length > 1 ? `${title} (Part ${idx + 1})` : title,
        category: category || 'Circular',
        content: chunks[idx],
        embeddingPreview: embedding.slice(0, 4),
        updatedAt: new Date().toISOString()
      };
      this.documents.push(record);
      created.push(record);
    }
    this.saveDocuments();
    return created;
  }

  getAllDocuments() {
    if (this.documents.length === 0) {
      this.loadDocuments();
    }
    return this.documents;
  }

  isHealthy() {
    return !this.simulateFailure;
  }
}

module.exports = { PineconeVectorAdapter, KB_FILE };