const { z } = require('zod');
const { AppError } = require('../adapters/MongoDBRepository');

const schemas = {
  anonymousAuth: z.object({
    preferredLanguage: z.string().min(2).max(10).optional().default('en')
  }),
  loginAuth: z.object({
    username: z.string().min(1, 'Username or enrollment ID is required'),
    password: z.string().min(1, 'Password is required'),
    role: z.enum(['student', 'admin_staff', 'system_admin']).optional()
  }),
  chatQuery: z.object({
    queryId: z.string().max(25).optional(),
    userId: z.string().max(25).optional(),
    sessionId: z.string().max(64).optional(),
    queryText: z.string().refine((val) => val.trim().length > 0, {
      message: 'Query text cannot be empty or whitespace only.'
    }),
    language: z.string().min(2).max(15).optional().default('auto')
  }),
  createFaq: z.object({
    faqId: z.string().min(1).max(25, 'faqId must be at most 25 characters').optional(),
    question: z.string().trim().min(3, 'Question is required (min 3 characters)'),
    answerText: z.string().trim().min(3, 'Answer text is required (min 3 characters)'),
    category: z.string().trim().min(2, 'Category is required')
  }),
  updateFaq: z.object({
    question: z.string().trim().min(3).optional(),
    answerText: z.string().trim().min(3).optional(),
    category: z.string().trim().min(2).optional()
  }),
  uploadKnowledge: z.object({
    title: z.string().trim().min(2, 'Document title is required'),
    category: z.string().trim().min(2, 'Category is required'),
    content: z.string().trim().min(10, 'Document content must be at least 10 characters')
  }),
  updateSysConfig: z.object({
    adminId: z.string().max(25, 'adminId must be at most 25 characters').optional(),
    rateLimitMax: z.number().int().min(1).max(10000).optional(),
    rateLimitWindowMs: z.number().int().min(1000).max(3600000).optional(),
    supportedLanguages: z.array(z.string().min(2).max(10)).min(1).optional()
  })
};

function validateBody(schema) {
  return (req, _res, next) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      const msg = parsed.error.issues.map((i) => i.message).join('; ');
      return next(new AppError(msg, 400, 'VALIDATION_ERROR'));
    }
    req.body = parsed.data;
    return next();
  };
}

module.exports = { schemas, validateBody };