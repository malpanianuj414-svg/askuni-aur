const getApiBase = () => {
  if (typeof window !== 'undefined') {
    if (window.ASKUNI_API_BASE) {
      return window.ASKUNI_API_BASE;
    }
    if (window.location && window.location.port === '5173') {
      return 'http://localhost:5000/api';
    }
    if (window.location && window.location.origin && window.location.origin.startsWith('http')) {
      return `${window.location.origin}/api`;
    }
  }
  return 'http://localhost:5000/api';
};

async function apiRequest(path, { method = 'GET', body = null, token = '' } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  const resp = await fetch(`${getApiBase()}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
  });
  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const errMsg = data?.error?.message || `Request failed with status ${resp.status}`;
    const err = new Error(errMsg);
    err.status = resp.status;
    err.code = data?.error?.code || 'API_ERROR';
    throw err;
  }
  return data;
}

export const askUniApi = {
  createAnonymousSession: (preferredLanguage = 'en') =>
    apiRequest('/auth/anonymous', { method: 'POST', body: { preferredLanguage } }),

  login: (username, password, role) =>
    apiRequest('/auth/login', { method: 'POST', body: { username, password, role } }),

  fetchFaqs: (category = '') =>
    apiRequest(`/faqs${category ? `?category=${encodeURIComponent(category)}` : ''}`),

  sendQuery: (payload, token = '') =>
    apiRequest('/chat/query', { method: 'POST', body: payload, token }),

  // Admin Staff
  getAdminLogs: (token, filters = {}) => {
    const params = new URLSearchParams();
    if (filters.date) params.set('date', filters.date);
    if (filters.language && filters.language !== 'all') params.set('language', filters.language);
    if (filters.keyword) params.set('keyword', filters.keyword);
    const qs = params.toString();
    return apiRequest(`/admin/logs${qs ? `?${qs}` : ''}`, { token });
  },

  getAdminSessionDetail: (token, sessionId) =>
    apiRequest(`/admin/logs/${encodeURIComponent(sessionId)}`, { token }),

  getAdminTrending: (token) =>
    apiRequest('/admin/trending', { token }),

  createFaq: (token, payload) =>
    apiRequest('/admin/faqs', { method: 'POST', body: payload, token }),

  updateFaq: (token, faqId, payload) =>
    apiRequest(`/admin/faqs/${encodeURIComponent(faqId)}`, { method: 'PUT', body: payload, token }),

  deleteFaq: (token, faqId) =>
    apiRequest(`/admin/faqs/${encodeURIComponent(faqId)}`, { method: 'DELETE', token }),

  uploadKnowledge: (token, payload) =>
    apiRequest('/admin/knowledge/upload', { method: 'POST', body: payload, token }),

  // System Admin
  getSysAdminHealth: (token) =>
    apiRequest('/sysadmin/health', { token }),

  getSysAdminServices: (token) =>
    apiRequest('/sysadmin/services', { token }),

  renewCredentials: (token) =>
    apiRequest('/sysadmin/credentials/renew', { method: 'POST', token }),

  updateSysConfig: (token, payload) =>
    apiRequest('/sysadmin/config', { method: 'PUT', body: payload, token })
};