const bcrypt = require('bcryptjs');
const { AppError } = require('../adapters/MongoDBRepository');

function createControllers({
  mongoRepo,
  authService,
  queryProcessor,
  adminService,
  infraService
}) {
  return {
    // GET /api/health
    health: (_req, res) => {
      const health = infraService.monitorServerHealth();
      res.status(200).json({
        success: true,
        service: 'AskUni API (Amity University Rajasthan - BCS 522)',
        status: health.status,
        mockMode: health.mockMode,
        uptimeSeconds: health.uptimeSeconds,
        database: health.database,
        timestamp: health.timestamp
      });
    },

    // POST /api/auth/anonymous
    anonymousSession: async (req, res, next) => {
      try {
        const preferredLanguage = req.body.preferredLanguage || 'en';
        const userId = `anon_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 5)}`.slice(0, 25);
        const sessionId = `sess_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
        const { student, widget } = await mongoRepo.ensureStudentAndWidget(
          userId,
          preferredLanguage,
          false,
          'Anonymous Visitor'
        );
        const token = authService.issueToken({
          userId: student.userId,
          role: 'anonymous',
          name: 'Anonymous Visitor',
          preferredLanguage
        });

        res.status(200).json({
          success: true,
          token,
          sessionId,
          user: {
            userId: student.userId,
            widgetId: widget.widgetId,
            role: 'anonymous',
            isAuthenticated: false,
            preferredLanguage
          }
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/auth/login
    login: async (req, res, next) => {
      try {
        const { username, password, role } = req.body;

        if (role === 'system_admin' || String(username).toLowerCase().startsWith('sysadmin')) {
          const sysAdmin = await mongoRepo.findSystemAdminByUsername(username);
          if (!sysAdmin || !bcrypt.compareSync(password, sysAdmin.passwordHash)) {
            throw new AppError('Invalid system administrator credentials.', 401, 'INVALID_CREDENTIALS');
          }
          const token = authService.issueToken({
            userId: sysAdmin.adminId,
            adminId: sysAdmin.adminId,
            staffId: sysAdmin.staffId,
            role: 'system_admin',
            name: sysAdmin.name
          });
          return res.status(200).json({
            success: true,
            token,
            user: {
              adminId: sysAdmin.adminId,
              staffId: sysAdmin.staffId,
              username: sysAdmin.username,
              name: sysAdmin.name,
              role: 'system_admin',
              isAuthenticated: true
            }
          });
        }

        if (role === 'admin_staff' || String(username).toLowerCase().startsWith('admin')) {
          const staff = await mongoRepo.findAdminStaffByUsername(username);
          if (!staff || !bcrypt.compareSync(password, staff.passwordHash)) {
            throw new AppError('Invalid admin staff credentials.', 401, 'INVALID_CREDENTIALS');
          }
          const token = authService.issueToken({
            userId: staff.staffId,
            staffId: staff.staffId,
            role: 'admin_staff',
            name: staff.name
          });
          return res.status(200).json({
            success: true,
            token,
            user: {
              staffId: staff.staffId,
              username: staff.username,
              name: staff.name,
              role: 'admin_staff',
              isAuthenticated: true
            }
          });
        }

        const student = await mongoRepo.findStudentByUsernameOrId(username);
        if (!student || !student.passwordHash || !bcrypt.compareSync(password, student.passwordHash)) {
          throw new AppError('Invalid student credentials.', 401, 'INVALID_CREDENTIALS');
        }

        const { widget } = await mongoRepo.ensureStudentAndWidget(
          student.userId,
          student.preferredLanguage,
          true,
          student.name
        );

        const sessionId = `sess_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
        const token = authService.issueToken({
          userId: student.userId,
          role: 'student',
          name: student.name,
          preferredLanguage: student.preferredLanguage
        });

        return res.status(200).json({
          success: true,
          token,
          sessionId,
          user: {
            userId: student.userId,
            widgetId: widget.widgetId,
            name: student.name,
            email: student.email,
            enrollmentNo: student.enrollmentNo,
            program: student.program,
            semester: student.semester,
            role: 'student',
            isAuthenticated: true,
            preferredLanguage: student.preferredLanguage
          }
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/chat/query
    chatQuery: async (req, res, next) => {
      try {
        const result = await queryProcessor.orchestrateAIResponse(req.body, req.headers.authorization);
        res.status(200).json({
          success: true,
          data: result
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/faqs
    getPublicFaqs: async (req, res, next) => {
      try {
        const category = req.query.category || '';
        const q = req.query.q || '';
        const faqs = await mongoRepo.fetchSmartFAQs(q, category);
        res.status(200).json({
          success: true,
          count: faqs.length,
          faqs
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/admin/faqs
    createFaq: async (req, res, next) => {
      try {
        const created = await adminService.updateSmartFAQs('create', req.body);
        res.status(201).json({
          success: true,
          faq: created
        });
      } catch (err) {
        next(err);
      }
    },

    // PUT /api/admin/faqs/:faqId
    updateFaq: async (req, res, next) => {
      try {
        const updated = await adminService.updateSmartFAQs('update', {
          faqId: req.params.faqId,
          ...req.body
        });
        res.status(200).json({
          success: true,
          faq: updated
        });
      } catch (err) {
        next(err);
      }
    },

    // DELETE /api/admin/faqs/:faqId
    deleteFaq: async (req, res, next) => {
      try {
        const deleted = await adminService.updateSmartFAQs('delete', {
          faqId: req.params.faqId
        });
        res.status(200).json({
          success: true,
          deleted
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/admin/logs
    getAdminLogs: async (req, res, next) => {
      try {
        const { date, language, keyword } = req.query;
        const result = await adminService.reviewChatLogs({ date, language, keyword });
        res.status(200).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/admin/logs/:sessionId
    getAdminSessionDetail: async (req, res, next) => {
      try {
        const detail = await adminService.getSessionDetail(req.params.sessionId);
        res.status(200).json({
          success: true,
          ...detail
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/admin/trending
    getAdminTrending: async (_req, res, next) => {
      try {
        const trending = await adminService.getTrendingQuestions();
        res.status(200).json({
          success: true,
          trending
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/admin/knowledge/upload
    uploadKnowledge: async (req, res, next) => {
      try {
        const result = await adminService.uploadKnowledgeDocument(req.body);
        res.status(201).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    },

    // GET /api/sysadmin/health
    getSysAdminHealth: (_req, res) => {
      const health = infraService.monitorServerHealth();
      res.status(200).json({
        success: true,
        health
      });
    },

    // GET /api/sysadmin/services
    getSysAdminServices: async (_req, res, next) => {
      try {
        const services = await infraService.getServiceConfigurations();
        res.status(200).json({
          success: true,
          services,
          security: authService.getMaskedMetadata()
        });
      } catch (err) {
        next(err);
      }
    },

    // POST /api/sysadmin/credentials/renew
    renewCredentials: async (_req, res, next) => {
      try {
        const result = await infraService.renewCredentials();
        res.status(200).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    },

    // PUT /api/sysadmin/config
    updateSysConfig: async (req, res, next) => {
      try {
        const result = await infraService.manageRateLimitsAndConfig(req.body);
        res.status(200).json({
          success: true,
          ...result
        });
      } catch (err) {
        next(err);
      }
    }
  };
}

module.exports = { createControllers };