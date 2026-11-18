const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { AppError } = require('../adapters/MongoDBRepository');

class JWTAuthService {
  constructor() {
    this.activeSecret = config.jwtSecret;
    this.rotationCount = 0;
    this.lastRotatedAt = new Date().toISOString();
  }

  issueToken(payload, expiresIn = config.jwtExpiresIn) {
    return jwt.sign(payload, this.activeSecret, { expiresIn });
  }

  validateToken(token) {
    try {
      return jwt.verify(token, this.activeSecret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        throw new AppError('Authentication token has expired.', 401, 'TOKEN_EXPIRED');
      }
      throw new AppError('Invalid authentication token.', 401, 'INVALID_TOKEN');
    }
  }

  verifyUserStatus(authHeader) {
    if (!authHeader) {
      return {
        isAuthenticated: false,
        role: 'anonymous',
        userId: null,
        name: 'Anonymous Visitor'
      };
    }

    const parts = String(authHeader).split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
      throw new AppError('Malformed Authorization header. Expected Bearer <token>.', 401, 'INVALID_AUTH_HEADER');
    }

    const decoded = this.validateToken(parts[1]);
    return {
      isAuthenticated: decoded.role !== 'anonymous',
      role: decoded.role || 'student',
      userId: decoded.userId,
      staffId: decoded.staffId || null,
      adminId: decoded.adminId || null,
      name: decoded.name || 'Authenticated User',
      preferredLanguage: decoded.preferredLanguage || 'en'
    };
  }

  rotateSecret() {
    const entropy = `${Date.now()}_${Math.random().toString(36).slice(2)}_${Math.random().toString(36).slice(2)}`;
    this.activeSecret = `askuni_rotated_${entropy}`;
    this.rotationCount += 1;
    this.lastRotatedAt = new Date().toISOString();
    // Never return or log this.activeSecret
    return {
      rotated: true,
      rotationCount: this.rotationCount,
      lastRotatedAt: this.lastRotatedAt,
      maskedSecret: '***MASKED***'
    };
  }

  getMaskedMetadata() {
    return {
      algorithm: 'HS256',
      expiresIn: config.jwtExpiresIn,
      rotationCount: this.rotationCount,
      lastRotatedAt: this.lastRotatedAt,
      tokenSecret: '***MASKED***'
    };
  }
}

module.exports = { JWTAuthService };