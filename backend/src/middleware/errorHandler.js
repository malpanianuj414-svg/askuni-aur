function errorHandler(err, _req, res, _next) {
  const statusCode = err.statusCode || 500;
  const code = err.code || 'INTERNAL_SERVER_ERROR';
  const message = err.message || 'An unexpected server error occurred.';

  // Never log secrets
  const safeMessage = String(message).replace(/askuni_[^\s'"]+/gi, '***MASKED***');

  res.status(statusCode).json({
    success: false,
    error: {
      code,
      message: safeMessage
    }
  });
}

module.exports = { errorHandler };