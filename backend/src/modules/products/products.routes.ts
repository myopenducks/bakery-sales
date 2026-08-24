import { FastifyPluginAsync } from 'fastify';
import { db } from '../../db';
import { products } from '../../db/schema';
import { eq } from 'drizzle-orm';
import { createProductSchema, updateProductSchema } from './products.schema';

const productsRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/products
  fastify.get('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const allProducts = await db.select().from(products);
    return reply.send({ products: allProducts });
  });

  // POST /api/v1/products
  fastify.post('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = createProductSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    const { name, supportsUnitSale, supportsKgSale, unitPrice, pricePerKg } = parsed.data;

    await db.insert(products).values({
      name,
      supportsUnitSale: supportsUnitSale ?? false,
      supportsKgSale: supportsKgSale ?? false,
      unitPrice: unitPrice ?? null,
      pricePerKg: pricePerKg ?? null,
    });

    return reply.status(201).send({ success: true });
  });

  // GET /api/v1/products/:id
  fastify.get('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const [product] = await db.select().from(products).where(eq(products.id, id));
    
    if (!product) {
      return reply.status(404).send({ error: 'Product not found' });
    }
    
    return reply.send({ product });
  });

  // PATCH /api/v1/products/:id
  fastify.patch('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    
    const parsed = updateProductSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    const [existing] = await db.select().from(products).where(eq(products.id, id));
    if (!existing) {
      return reply.status(404).send({ error: 'Product not found' });
    }

    const merged = {
      name: parsed.data.name ?? existing.name,
      supportsUnitSale: parsed.data.supportsUnitSale ?? existing.supportsUnitSale,
      supportsKgSale: parsed.data.supportsKgSale ?? existing.supportsKgSale,
      unitPrice: parsed.data.unitPrice !== undefined ? parsed.data.unitPrice : existing.unitPrice,
      pricePerKg: parsed.data.pricePerKg !== undefined ? parsed.data.pricePerKg : existing.pricePerKg,
    };

    // Run the merged object through the create schema for full validation
    const fullValidation = createProductSchema.safeParse(merged);
    if (!fullValidation.success) {
      return reply.status(400).send({ error: 'Invalid resulting state', details: fullValidation.error.issues });
    }

    await db.update(products)
      .set({
        name: merged.name,
        supportsUnitSale: merged.supportsUnitSale,
        supportsKgSale: merged.supportsKgSale,
        unitPrice: merged.unitPrice,
        pricePerKg: merged.pricePerKg,
      })
      .where(eq(products.id, id));

    return reply.send({ success: true });
  });

  // DELETE /api/v1/products/:id
  fastify.delete('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    
    await db.delete(products).where(eq(products.id, id));
    
    return reply.send({ success: true });
  });
};

export default productsRoutes;
