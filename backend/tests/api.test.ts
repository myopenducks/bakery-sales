import Fastify from 'fastify';
import assert from 'node:assert';
import { describe, it, before, after } from 'node:test';
import { buildApp } from '../src/app';
import { db } from '../src/db';
import { users, cafes, products, sales, saleItems, expenses } from '../src/db/schema';
import * as argon2 from 'argon2';
import { eq } from 'drizzle-orm';

// ─── Helpers ────────────────────────────────────────────────────────────────

async function getAuthToken(app: Awaited<ReturnType<typeof buildApp>>) {
  const res = await app.inject({
    method: 'POST',
    url: '/api/v1/auth/login',
    payload: { username: 'test_admin', password: 'TestPass123' },
  });
  const body = JSON.parse(res.body);
  return body.token as string;
}

function authHeader(token: string) {
  return { Authorization: `Bearer ${token}` };
}

// ─── Test Suite ──────────────────────────────────────────────────────────────

describe('Bakery Sales API Integration Tests', () => {
  let app: Awaited<ReturnType<typeof buildApp>>;
  let token: string;
  let cafeId: string;
  let productId: string;
  let saleId: string;
  let expenseId: string;

  before(async () => {
    app = await buildApp();

    // Create a test admin user
    const existingUser = await db.select().from(users).where(eq(users.username, 'test_admin')).limit(1);
    if (existingUser.length === 0) {
      await db.insert(users).values({
        username: 'test_admin',
        passwordHash: await argon2.hash('TestPass123'),
      });
    }
  });

  after(async () => {
    // Cleanup: delete test data in reverse FK order
    await db.delete(saleItems);
    await db.delete(sales);
    await db.delete(cafes);
    await db.delete(products);
    await db.delete(expenses);
    await db.delete(users).where(eq(users.username, 'test_admin'));
    await app.close();
  });

  // ── Auth ───────────────────────────────────────────────────────────────────

  describe('Auth', () => {
    it('POST /auth/login — should fail with wrong password', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/login',
        payload: { username: 'test_admin', password: 'wrong' },
      });
      assert.strictEqual(res.statusCode, 401);
    });

    it('POST /auth/login — should succeed with correct credentials', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/login',
        payload: { username: 'test_admin', password: 'TestPass123' },
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      assert.ok(body.token, 'should return a token');
      token = body.token;
    });

    it('GET /auth/me — should return current user', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/auth/me',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      assert.strictEqual(body.user.username, 'test_admin');
    });

    it('GET /auth/me — should reject unauthenticated', async () => {
      const res = await app.inject({ method: 'GET', url: '/api/v1/auth/me' });
      assert.strictEqual(res.statusCode, 401);
    });
  });

  // ── Cafés ──────────────────────────────────────────────────────────────────

  describe('Cafés CRUD', () => {
    it('POST /cafes — should create a café', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/cafes',
        headers: authHeader(token),
        payload: { name: 'Test Café صبراوي', phone: '0549256794' },
      });
      assert.strictEqual(res.statusCode, 201);
    });

    it('GET /cafes — should list cafes including the new one', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/cafes',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      assert.ok(body.cafes.length > 0);
      const found = body.cafes.find((c: any) => c.name === 'Test Café صبراوي');
      assert.ok(found, 'Created café should appear in list');
      cafeId = found.id;
    });

    it('PATCH /cafes/:id — should update the café name', async () => {
      const res = await app.inject({
        method: 'PATCH',
        url: `/api/v1/cafes/${cafeId}`,
        headers: authHeader(token),
        payload: { name: 'Updated Café' },
      });
      assert.strictEqual(res.statusCode, 200);
    });
  });

  // ── Products ───────────────────────────────────────────────────────────────

  describe('Products CRUD', () => {
    it('POST /products — should create a unit product', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/products',
        headers: authHeader(token),
        payload: { name: 'Msemmen Test', supportsUnitSale: true, supportsKgSale: false, unitPrice: 10 },
      });
      assert.strictEqual(res.statusCode, 201);
    });

    it('GET /products — should list products', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/products',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      const found = body.products.find((p: any) => p.name === 'Msemmen Test');
      assert.ok(found, 'Created product should appear in list');
      productId = found.id;
    });

    it('POST /products — should reject product with no pricing mode', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/products',
        headers: authHeader(token),
        payload: { name: 'Bad Product', supportsUnitSale: false, supportsKgSale: false },
      });
      assert.strictEqual(res.statusCode, 400);
    });
  });

  // ── Sales ──────────────────────────────────────────────────────────────────

  describe('Sales', () => {
    it('POST /sales — should create a sale with items', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/sales',
        headers: authHeader(token),
        payload: {
          cafeId,
          items: [{ productId, sellingMode: 'UNIT', quantity: 5 }],
        },
      });
      assert.strictEqual(res.statusCode, 201);
      const body = JSON.parse(res.body);
      assert.ok(body.saleId, 'should return saleId');
      saleId = body.saleId;
    });

    it('GET /sales — should list sales', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/sales',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      assert.ok(body.sales.length > 0);
    });

    it('GET /sales/:id — should return sale with items and snapshots', async () => {
      const res = await app.inject({
        method: 'GET',
        url: `/api/v1/sales/${saleId}`,
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      assert.ok(body.sale.items.length > 0, 'Sale should have items');
      assert.strictEqual(body.sale.items[0].unitPriceSnapshot, 10, 'Price should be snapshotted at 10 DA');
      assert.strictEqual(body.sale.totalAmount, 50, 'Total = 5 units × 10 DA = 50 DA');
    });
  });

  // ── Expenses ───────────────────────────────────────────────────────────────

  describe('Expenses', () => {
    it('POST /expenses — should create an expense', async () => {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/expenses',
        headers: authHeader(token),
        payload: { name: 'Flour Test', quantity: 10, unit: 'kg', totalCost: 1500 },
      });
      assert.strictEqual(res.statusCode, 201);
    });

    it('GET /expenses — should list expenses', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/expenses',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      const found = body.expenses.find((e: any) => e.name === 'Flour Test');
      assert.ok(found);
      expenseId = found.id;
    });

    it('DELETE /expenses/:id — should delete an expense', async () => {
      const res = await app.inject({
        method: 'DELETE',
        url: `/api/v1/expenses/${expenseId}`,
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
    });
  });

  // ── Dashboard ──────────────────────────────────────────────────────────────

  describe('Dashboard', () => {
    it('GET /dashboard/summary?period=today — should return revenue, expenses, net', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/dashboard/summary?period=today',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
      const body = JSON.parse(res.body);
      assert.ok(typeof body.revenue === 'number');
      assert.ok(typeof body.expenses === 'number');
      assert.ok(typeof body.net === 'number');
    });

    it('GET /dashboard/cafes?period=today — should return top cafes', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/dashboard/cafes?period=today',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
    });

    it('GET /dashboard/products?period=today — should return top products', async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/api/v1/dashboard/products?period=today',
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 200);
    });
  });

  // ── Critical: Café Delete with Sales (the bug that was in prod) ────────────

  describe('Café Delete Cascade (FK safety)', () => {
    it('DELETE /cafes/:id — should cascade-delete sales and succeed even when café has sales and Content-Type is sent', async () => {
      const res = await app.inject({
        method: 'DELETE',
        url: `/api/v1/cafes/${cafeId}`,
        headers: {
          ...authHeader(token),
          'content-type': 'application/json',
        },
      });
      // This test ensures FST_ERR_CTP_EMPTY_JSON_BODY doesn't occur when clients send Content-Type header on DELETE
      assert.strictEqual(res.statusCode, 200, 'Deleting a café with sales should succeed (cascade delete)');
    });

    it('GET /cafes/:id — should return 404 after deletion', async () => {
      const res = await app.inject({
        method: 'GET',
        url: `/api/v1/cafes/${cafeId}`,
        headers: authHeader(token),
      });
      assert.strictEqual(res.statusCode, 404);
    });
  });
});
