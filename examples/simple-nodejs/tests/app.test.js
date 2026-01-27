/**
 * Tests for Simple Express API
 */

const request = require('supertest');
const app = require('../src/index');

describe('Express API', () => {
  describe('GET /health', () => {
    it('should return 200 OK status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
    });

    it('should return health check data', async () => {
      const response = await request(app).get('/health');
      expect(response.body).toHaveProperty('status', 'OK');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
    });
  });

  describe('GET /api/info', () => {
    it('should return API information', async () => {
      const response = await request(app).get('/api/info');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('name');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('description');
    });
  });

  describe('GET /api/hello', () => {
    it('should greet World by default', async () => {
      const response = await request(app).get('/api/hello');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Hello, World!');
    });

    it('should greet custom name', async () => {
      const response = await request(app).get('/api/hello?name=CI/CD');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Hello, CI/CD!');
    });
  });

  describe('404 handler', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app).get('/unknown');
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Not Found');
    });
  });
});
