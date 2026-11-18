const path = require('path');
const fs = require('fs');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const config = require('./config/env');
const { MongoDBRepository } = require('./adapters/MongoDBRepository');
const { PineconeVectorAdapter } = require('./adapters/PineconeVectorAdapter');
const { AIServiceAdapter } = require('./adapters/AIServiceAdapter');
const { TranslationServiceAdapter } = require('./adapters/TranslationServiceAdapter');
const { JWTAuthService } = require('./services/JWTAuthService');
const { BackendQueryProcessor } = require('./services/BackendQueryProcessor');
const { AdminStaffService } = require('./services/AdminStaffService');
const { InfrastructureAdminService } = require('./services/InfrastructureAdminService');
const { createAuthMiddleware } = require('./middleware/authMiddleware');
const { createControllers } = require('./controllers/apiControllers');
const { createApiRouter } = require('./routes/apiRoutes');
const { errorHandler } = require('./middleware/errorHandler');

function createApp(customDeps = {}) {
  const app = express();
  app.set('trust proxy', 1);

  const mongoRepo = customDeps.mongoRepo || new MongoDBRepository();
  const pineconeAdapter = customDeps.pineconeAdapter || new PineconeVectorAdapter();
  const aiAdapter = customDeps.aiAdapter || new AIServiceAdapter();
  const translationAdapter = customDeps.translationAdapter || new TranslationServiceAdapter();
  const authService = customDeps.authService || new JWTAuthService();

  const queryProcessor = new BackendQueryProcessor({
    mongoRepo,
    pineconeAdapter,
    aiAdapter,
    translationAdapter,
    authService
  });

  const adminService = new AdminStaffService({ mongoRepo, pineconeAdapter });
  const infraService = new InfrastructureAdminService({
    mongoRepo,
    pineconeAdapter,
    aiAdapter,
    translationAdapter,
    authService
  });

  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(
    cors({
      origin: (origin, callback) => {
        if (!origin || config.corsOrigins.includes(origin) || origin.startsWith('http://localhost:')) {
          callback(null, true);
        } else {
          callback(null, true); // Allow embed widget on partner campus portals
        }
      },
      credentials: true
    })
  );
  app.use(express.json({ limit: '1mb' }));

  // Dynamic rate limiter backed by InfrastructureAdminService settings
  const limiter = rateLimit({
    windowMs: config.rateLimitWindowMs,
    limit: () => infraService.rateLimitState.maxRequests,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      infraService.recordRequest(true);
      const retrySec = Math.ceil(infraService.rateLimitState.windowMs / 1000);
      res.status(429).json({
        success: false,
        error: {
          code: 'RATE_LIMIT_EXCEEDED',
          message: `Too many requests. Please retry after ${retrySec} seconds.`,
          retryAfterSeconds: retrySec
        }
      });
    }
  });

  app.use('/api', (req, _res, next) => {
    infraService.recordRequest(false);
    next();
  }, limiter);

  const authMiddleware = createAuthMiddleware(authService);
  const controllers = createControllers({
    mongoRepo,
    authService,
    queryProcessor,
    adminService,
    infraService
  });

  app.use('/api', createApiRouter(controllers, authMiddleware));

  // Single <script> tag embeddable widget loader endpoint
  app.get('/widget/askuni-widget.js', (req, res) => {
    res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
    const builtEmbed = path.resolve(__dirname, '../../frontend/dist/askuni-widget.iife.js');
    if (fs.existsSync(builtEmbed)) {
      return res.sendFile(builtEmbed);
    }
    const apiBase = `${req.protocol}://${req.get('host')}/api`;
    const fallbackLoader = `(function(){
  if (window.__ASKUNI_LOADED__) return;
  window.__ASKUNI_LOADED__ = true;
  var API_BASE = window.ASKUNI_API_BASE || '${apiBase}';
  var host = document.createElement('div');
  host.id = 'askuni-embed-root';
  document.body.appendChild(host);
  var btn = document.createElement('button');
  btn.textContent = 'AskUni Chat (AUR)';
  btn.setAttribute('aria-label', 'Open AskUni Assistant');
  btn.style.cssText = 'position:fixed;bottom:20px;right:20px;z-index:99999;background:#003366;color:#fff;border:none;border-radius:999px;padding:12px 20px;font-family:sans-serif;font-weight:600;cursor:pointer;box-shadow:0 8px 24px rgba(0,0,0,0.2);';
  var box = document.createElement('div');
  box.style.cssText = 'display:none;position:fixed;bottom:76px;right:20px;width:360px;max-width:92vw;height:460px;background:#fff;border:1px solid #cbd5e1;border-radius:16px;z-index:99999;flex-direction:column;overflow:hidden;font-family:sans-serif;box-shadow:0 16px 40px rgba(0,0,0,0.22);';
  box.innerHTML = '<div style="background:#003366;color:#fff;padding:12px 16px;display:flex;justify-content:space-between;align-items:center;"><strong>AskUni â€” Amity Rajasthan</strong><button id="au-close" style="background:none;border:none;color:#fff;font-size:18px;cursor:pointer;">&times;</button></div><div id="au-msgs" style="flex:1;padding:12px;overflow-y:auto;font-size:13px;background:#f8fafc;"><div style="background:#e2e8f0;padding:8px 12px;border-radius:10px;margin-bottom:8px;">Namaste! Ask me about AUR exams, fees, timetables, hostel, or scholarships.</div></div><form id="au-form" style="display:flex;border-top:1px solid #e2e8f0;padding:8px;gap:6px;"><input id="au-in" placeholder="Type your question..." style="flex:1;padding:8px;border:1px solid #cbd5e1;border-radius:8px;"/><button type="submit" style="background:#f59e0b;color:#0f172a;border:none;border-radius:8px;padding:8px 14px;font-weight:700;cursor:pointer;">Send</button></form>';
  host.appendChild(btn);
  host.appendChild(box);
  btn.onclick = function(){ box.style.display = box.style.display === 'none' ? 'flex' : 'none'; };
  box.querySelector('#au-close').onclick = function(){ box.style.display = 'none'; };
  box.querySelector('#au-form').onsubmit = function(e){
    e.preventDefault();
    var inp = box.querySelector('#au-in');
    var q = inp.value.trim();
    if (!q) return;
    var msgs = box.querySelector('#au-msgs');
    msgs.innerHTML += '<div style="text-align:right;margin-bottom:8px;"><span style="display:inline-block;background:#003366;color:#fff;padding:8px 12px;border-radius:10px;">' + q + '</span></div>';
    inp.value = '';
    fetch(API_BASE + '/chat/query', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ queryText: q, language: 'auto' })
    }).then(function(r){ return r.json(); }).then(function(d){
      var ans = (d && d.data && d.data.translatedText) || 'Unable to fetch answer.';
      msgs.innerHTML += '<div style="margin-bottom:8px;"><span style="display:inline-block;background:#e2e8f0;color:#0f172a;padding:8px 12px;border-radius:10px;">' + ans + '</span></div>';
      msgs.scrollTop = msgs.scrollHeight;
    });
  };
})();`;
    return res.send(fallbackLoader);
  });

  // Serve compiled React SPA & static assets on the same unified URL
  const frontendDist = path.resolve(__dirname, '../../frontend/dist');
  if (fs.existsSync(frontendDist)) {
    app.use(express.static(frontendDist));
    app.get('*', (req, res, next) => {
      if (req.path.startsWith('/api/') || req.path.startsWith('/widget/')) {
        return next();
      }
      return res.sendFile(path.join(frontendDist, 'index.html'));
    });
  }

  app.use(errorHandler);

  app.locals.services = {
    mongoRepo,
    pineconeAdapter,
    aiAdapter,
    translationAdapter,
    authService,
    queryProcessor,
    adminService,
    infraService
  };

  return app;
}

module.exports = { createApp };