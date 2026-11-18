const express = require('express');
const { schemas, validateBody } = require('../middleware/validateMiddleware');

function createApiRouter(controllers, authMiddleware) {
  const router = express.Router();
  const { requireRoles } = authMiddleware;

  // Health
  router.get('/health', controllers.health);

  // Auth
  router.post('/auth/anonymous', validateBody(schemas.anonymousAuth), controllers.anonymousSession);
  router.post('/auth/login', validateBody(schemas.loginAuth), controllers.login);

  // Public FAQ & Chat RAG
  router.get('/faqs', controllers.getPublicFaqs);
  router.post('/chat/query', validateBody(schemas.chatQuery), controllers.chatQuery);

  // Admin Staff Routes (/api/admin/*)
  router.get('/admin/logs', requireRoles('admin_staff', 'system_admin'), controllers.getAdminLogs);
  router.get('/admin/logs/:sessionId', requireRoles('admin_staff', 'system_admin'), controllers.getAdminSessionDetail);
  router.get('/admin/trending', requireRoles('admin_staff', 'system_admin'), controllers.getAdminTrending);
  router.post('/admin/faqs', requireRoles('admin_staff', 'system_admin'), validateBody(schemas.createFaq), controllers.createFaq);
  router.put('/admin/faqs/:faqId', requireRoles('admin_staff', 'system_admin'), validateBody(schemas.updateFaq), controllers.updateFaq);
  router.delete('/admin/faqs/:faqId', requireRoles('admin_staff', 'system_admin'), controllers.deleteFaq);
  router.post('/admin/knowledge/upload', requireRoles('admin_staff', 'system_admin'), validateBody(schemas.uploadKnowledge), controllers.uploadKnowledge);

  // System Administrator Routes (/api/sysadmin/*)
  router.get('/sysadmin/health', requireRoles('system_admin'), controllers.getSysAdminHealth);
  router.get('/sysadmin/services', requireRoles('system_admin'), controllers.getSysAdminServices);
  router.post('/sysadmin/credentials/renew', requireRoles('system_admin'), controllers.renewCredentials);
  router.put('/sysadmin/config', requireRoles('system_admin'), validateBody(schemas.updateSysConfig), controllers.updateSysConfig);

  return router;
}

module.exports = { createApiRouter };