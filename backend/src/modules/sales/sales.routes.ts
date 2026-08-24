import { FastifyPluginAsync } from 'fastify';
import { db } from '../../db';
import { sales, saleItems, products, cafes } from '../../db/schema';
import { eq, desc } from 'drizzle-orm';
import { createSaleSchema } from './sales.schema';

const salesRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/sales
  fastify.get('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    // Basic history: returns all sales with minimal cafe info
    const allSales = await db
      .select({
        id: sales.id,
        totalAmount: sales.totalAmount,
        createdAt: sales.createdAt,
        cafeId: cafes.id,
        cafeName: cafes.name,
      })
      .from(sales)
      .leftJoin(cafes, eq(sales.cafeId, cafes.id))
      .orderBy(desc(sales.createdAt));

    return reply.send({ sales: allSales });
  });

  // GET /api/v1/sales/:id
  fastify.get('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const [saleInfo] = await db
      .select({
        id: sales.id,
        totalAmount: sales.totalAmount,
        createdAt: sales.createdAt,
        cafeId: cafes.id,
        cafeName: cafes.name,
      })
      .from(sales)
      .leftJoin(cafes, eq(sales.cafeId, cafes.id))
      .where(eq(sales.id, id));

    if (!saleInfo) {
      return reply.status(404).send({ error: 'Sale not found' });
    }

    const items = await db
      .select({
        id: saleItems.id,
        productId: products.id,
        productName: products.name,
        sellingMode: saleItems.sellingMode,
        quantity: saleItems.quantity,
        unitPriceSnapshot: saleItems.unitPriceSnapshot,
        totalAmount: saleItems.totalAmount,
      })
      .from(saleItems)
      .leftJoin(products, eq(saleItems.productId, products.id))
      .where(eq(saleItems.saleId, id));

    return reply.send({ sale: { ...saleInfo, items } });
  });

  // POST /api/v1/sales
  fastify.post('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = createSaleSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    const { cafeId, items } = parsed.data;

    try {
      await db.transaction(async (tx) => {
        // Validate cafe
        const [cafe] = await tx.select().from(cafes).where(eq(cafes.id, cafeId));
        if (!cafe) {
          throw new Error(`Cafe with ID ${cafeId} not found`);
        }

        let grandTotal = 0;
        const processedItems = [];

        // Validate products and calculate totals
        for (const item of items) {
          const [product] = await tx.select().from(products).where(eq(products.id, item.productId));
          if (!product) {
            throw new Error(`Product with ID ${item.productId} not found`);
          }

          let unitPriceSnapshot = 0;
          let lineTotal = 0;

          if (item.sellingMode === 'UNIT') {
            if (!product.supportsUnitSale || product.unitPrice === null) {
              throw new Error(`Product ${product.name} does not support UNIT sale`);
            }
            if (!Number.isInteger(item.quantity)) {
              throw new Error(`Product ${product.name} UNIT sale quantity must be an integer`);
            }
            unitPriceSnapshot = product.unitPrice;
            lineTotal = item.quantity * unitPriceSnapshot;
          } else if (item.sellingMode === 'KG') {
            if (!product.supportsKgSale || product.pricePerKg === null) {
              throw new Error(`Product ${product.name} does not support KG sale`);
            }
            unitPriceSnapshot = product.pricePerKg;
            // Kg quantities can be decimals. Calculate strictly.
            // Example: 2.5 kg * 320 DA = 800 DA
            lineTotal = Math.round(item.quantity * unitPriceSnapshot);
          }

          grandTotal += lineTotal;
          processedItems.push({
            productId: item.productId,
            sellingMode: item.sellingMode,
            quantity: item.quantity.toString(), // Convert to string for DECIMAL DB type mapping
            unitPriceSnapshot,
            totalAmount: lineTotal,
          });
        }

        // To ensure we have the created sale ID (since MySQL doesn't natively return it cleanly via Drizzle without returning clauses),
        // we explicitly generate the cuid.
        const { createId } = await import('@paralleldrive/cuid2');
        const newSaleId = createId();

        // Create Sale
        await tx.insert(sales).values({
          id: newSaleId,
          cafeId,
          totalAmount: grandTotal,
        });

        // Insert Sale Items
        const itemsToInsert = processedItems.map(pi => ({
          ...pi,
          id: createId(),
          saleId: newSaleId,
        }));

        await tx.insert(saleItems).values(itemsToInsert);
      });

      return reply.status(201).send({ success: true });
    } catch (error: any) {
      return reply.status(400).send({ error: error.message || 'Transaction failed' });
    }
  });
};

export default salesRoutes;
