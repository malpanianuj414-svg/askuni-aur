const { AppError } = require('../adapters/MongoDBRepository');

function createAuthMiddleware(authService) {
  function requireRoles(...allowedRoles) {
    return (req, _res, next) => {
      try {
        const authHeader = req.headers.authorization;
        if (!authHeader) {
          throw new AppError('Authentication required.', 401, 'AUTH_REQUIRED');
        }
        const user = authService.verifyUserStatus(authHeader);
        if (!user.isAuthenticated) {
          throw new AppError('Authenticated role required.', 401, 'AUTH_REQUIRED');
        }
        if (allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
          throw new AppError(
            `Access denied. Role '${user.role}' is not permitted for this resource.`,
            403,
            'FORBIDDEN_ROLE'
          );
        }
        req.user = user;
        next();
      } catch (err) {
        next(err);
      }
    };
  }

  return { requireRoles };
}

module.exports = { createAuthMiddleware };