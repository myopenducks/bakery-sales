import { FastifyPluginAsync } from 'fastify';
import { db } from '../../db';
import { sales, saleItems, products, cafes, expenses } from '../../db/schema';
import { eq, gte, lte, and, desc, sql } from 'drizzle-orm';
import { dashboardQuerySchema } from './dashboard.schema';

function getDateRange(period: string, customMonth?: string): { startDate: Date; endDate: Date } {
  const now = new Date();

  if (period === 'today') {
    const startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    const endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    return { startDate, endDate };
  }

  if (period === 'week') {
    // Current week starting from Monday
    const currentDay = now.getDay();
    const distanceToMonday = (currentDay + 6) % 7; // 0 if Monday, 6 if Sunday
    const startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - distanceToMonday, 0, 0, 0, 0);
    const endDate = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + 6, 23, 59, 59, 999);
    return { startDate, endDate };
  }

  if (period === 'month') {
    const startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
    const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    return { startDate, endDate };
  }

  if (period === 'custom' && customMonth) {
    const [yearStr, monthStr] = customMonth.split('-');
    const year = parseInt(yearStr || '0', 10);
    const month = parseInt(monthStr || '0', 10);
    if (!isNaN(year) && !isNaN(month) && month >= 1 && month <= 12) {
      const startDate = new Date(year, month - 1, 1, 0, 0, 0, 0);
      const endDate = new Date(year, month, 0, 23, 59, 59, 999);
      return { startDate, endDate };
    }
  }

  // Default fallback to current month
  const startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
  const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
  return { startDate, endDate };
}

const dashboardRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/dashboard/summary
  fastify.get('/summary', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = dashboardQuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid query parameters', details: parsed.error.issues });
    }

    const { period, month } = parsed.data;
    const { startDate, endDate } = getDateRange(period, month);

    // Sum revenue
    const [revenueResult] = await db
      .select({ total: sql<string>`COALESCE(SUM(${sales.totalAmount}), 0)` })
      .from(sales)
      .where(and(gte(sales.createdAt, startDate), lte(sales.createdAt, endDate)));
    const revenue = Number(revenueResult?.total || 0);

    // Sum expenses
    const [expenseResult] = await db
      .select({ total: sql<string>`COALESCE(SUM(${expenses.totalCost}), 0)` })
      .from(expenses)
      .where(and(gte(expenses.createdAt, startDate), lte(expenses.createdAt, endDate)));
    const expensesTotal = Number(expenseResult?.total || 0);

    const net = revenue - expensesTotal;

    // Recent 5 sales
    const recentSales = await db
      .select({
        id: sales.id,
        totalAmount: sales.totalAmount,
        createdAt: sales.createdAt,
        cafeId: cafes.id,
        cafeName: cafes.name,
      })
      .from(sales)
      .leftJoin(cafes, eq(sales.cafeId, cafes.id))
      .where(and(gte(sales.createdAt, startDate), lte(sales.createdAt, endDate)))
      .orderBy(desc(sales.createdAt))
      .limit(5);

    return reply.send({
      period,
      startDate,
      endDate,
      revenue,
      expenses: expensesTotal,
      net,
      recentSales,
    });
  });

  // GET /api/v1/dashboard/cafes
  fastify.get('/cafes', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = dashboardQuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid query parameters', details: parsed.error.issues });
    }

    const { period, month } = parsed.data;
    const { startDate, endDate } = getDateRange(period, month);

    // Get ranked cafes by revenue
    const topCafes = await db
      .select({
        cafeId: cafes.id,
        cafeName: cafes.name,
        totalRevenue: sql<number>`CAST(COALESCE(SUM(${sales.totalAmount}), 0) AS SIGNED)`,
        salesCount: sql<number>`CAST(COUNT(${sales.id}) AS SIGNED)`,
      })
      .from(sales)
      .innerJoin(cafes, eq(sales.cafeId, cafes.id))
      .where(and(gte(sales.createdAt, startDate), lte(sales.createdAt, endDate)))
      .groupBy(cafes.id, cafes.name)
      .orderBy(desc(sql`COALESCE(SUM(${sales.totalAmount}), 0)`));

    // Get product breakdown per cafe to find best selling product by revenue
    const cafeProductSales = await db
      .select({
        cafeId: sales.cafeId,
        productId: products.id,
        productName: products.name,
        revenue: sql<number>`CAST(COALESCE(SUM(${saleItems.totalAmount}), 0) AS SIGNED)`,
      })
      .from(saleItems)
      .innerJoin(sales, eq(saleItems.saleId, sales.id))
      .innerJoin(products, eq(saleItems.productId, products.id))
      .where(and(gte(sales.createdAt, startDate), lte(sales.createdAt, endDate)))
      .groupBy(sales.cafeId, products.id, products.name)
      .orderBy(desc(sql`COALESCE(SUM(${saleItems.totalAmount}), 0)`));

    // Map best product to each cafe
    const bestProductByCafe = new Map<string, { productId: string; productName: string; revenue: number }>();
    for (const item of cafeProductSales) {
      if (!bestProductByCafe.has(item.cafeId)) {
        bestProductByCafe.set(item.cafeId, {
          productId: item.productId,
          productName: item.productName,
          revenue: item.revenue,
        });
      }
    }

    const rankedCafesWithBestProduct = topCafes.map((cafe) => ({
      ...cafe,
      bestProduct: bestProductByCafe.get(cafe.cafeId) || null,
    }));

    return reply.send({
      period,
      startDate,
      endDate,
      topCafes: rankedCafesWithBestProduct,
    });
  });

  // GET /api/v1/dashboard/products
  fastify.get('/products', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = dashboardQuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid query parameters', details: parsed.error.issues });
    }

    const { period, month } = parsed.data;
    const { startDate, endDate } = getDateRange(period, month);

    // Get products ranked by total revenue
    const topProducts = await db
      .select({
        productId: products.id,
        productName: products.name,
        totalRevenue: sql<number>`CAST(COALESCE(SUM(${saleItems.totalAmount}), 0) AS SIGNED)`,
        salesCount: sql<number>`CAST(COUNT(${saleItems.id}) AS SIGNED)`,
      })
      .from(saleItems)
      .innerJoin(sales, eq(saleItems.saleId, sales.id))
      .innerJoin(products, eq(saleItems.productId, products.id))
      .where(and(gte(sales.createdAt, startDate), lte(sales.createdAt, endDate)))
      .groupBy(products.id, products.name)
      .orderBy(desc(sql`COALESCE(SUM(${saleItems.totalAmount}), 0)`));

    return reply.send({
      period,
      startDate,
      endDate,
      topProducts,
    });
  });
};

export default dashboardRoutes;
