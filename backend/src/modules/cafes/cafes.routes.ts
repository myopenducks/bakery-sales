import { FastifyPluginAsync } from 'fastify';
import { db } from '../../db';
import { cafes, sales, saleItems } from '../../db/schema';
import { eq, inArray } from 'drizzle-orm';
import { createCafeSchema, updateCafeSchema } from './cafes.schema';

const cafesRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/cafes
  fastify.get('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const allCafes = await db.select().from(cafes);
    return reply.send({ cafes: allCafes });
  });

  // POST /api/v1/cafes
  fastify.post('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = createCafeSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    await db.insert(cafes).values({
      name: parsed.data.name,
      phone: parsed.data.phone || null,
    });

    return reply.status(201).send({ success: true });
  });

  // GET /api/v1/cafes/:id
  fastify.get('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const [cafe] = await db.select().from(cafes).where(eq(cafes.id, id));
    
    if (!cafe) {
      return reply.status(404).send({ error: 'Cafe not found' });
    }
    
    return reply.send({ cafe });
  });

  // PATCH /api/v1/cafes/:id
  fastify.patch('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    
    const parsed = updateCafeSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    await db.update(cafes)
      .set(parsed.data)
      .where(eq(cafes.id, id));

    return reply.send({ success: true });
  });

  // DELETE /api/v1/cafes/:id — cascade deletes related sales & items
  fastify.delete('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };

    // Find all sales for this café
    const cafeSales = await db
      .select({ id: sales.id })
      .from(sales)
      .where(eq(sales.cafeId, id));

    if (cafeSales.length > 0) {
      const saleIds = cafeSales.map((s) => s.id);
      // Delete sale items first (FK constraint)
      await db.delete(saleItems).where(inArray(saleItems.saleId, saleIds));
      // Then delete the sales
      await db.delete(sales).where(eq(sales.cafeId, id));
    }

    // Finally delete the café
    await db.delete(cafes).where(eq(cafes.id, id));
    
    return reply.send({ success: true });
  });
};

export default cafesRoutes;
