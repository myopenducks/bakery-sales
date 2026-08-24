import { FastifyPluginAsync } from 'fastify';
import { db } from '../../db';
import { expenses } from '../../db/schema';
import { eq, desc } from 'drizzle-orm';
import { createExpenseSchema, updateExpenseSchema } from './expenses.schema';

const expensesRoutes: FastifyPluginAsync = async (fastify) => {
  // GET /api/v1/expenses
  fastify.get('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const allExpenses = await db.select().from(expenses).orderBy(desc(expenses.createdAt));
    return reply.send({ expenses: allExpenses });
  });

  // POST /api/v1/expenses
  fastify.post('/', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = createExpenseSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    const { name, quantity, unit, totalCost } = parsed.data;

    await db.insert(expenses).values({
      name,
      quantity: quantity ? quantity.toString() : null, // Convert decimal number to string for DECIMAL column
      unit: unit || null,
      totalCost,
    });

    return reply.status(201).send({ success: true });
  });

  // PATCH /api/v1/expenses/:id
  fastify.patch('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    
    const parsed = updateExpenseSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    const [existing] = await db.select().from(expenses).where(eq(expenses.id, id));
    if (!existing) {
      return reply.status(404).send({ error: 'Expense not found' });
    }

    const updateData: any = {};
    if (parsed.data.name !== undefined) updateData.name = parsed.data.name;
    if (parsed.data.quantity !== undefined) updateData.quantity = parsed.data.quantity?.toString();
    if (parsed.data.unit !== undefined) updateData.unit = parsed.data.unit;
    if (parsed.data.totalCost !== undefined) updateData.totalCost = parsed.data.totalCost;

    if (Object.keys(updateData).length > 0) {
      await db.update(expenses)
        .set(updateData)
        .where(eq(expenses.id, id));
    }

    return reply.send({ success: true });
  });

  // DELETE /api/v1/expenses/:id
  fastify.delete('/:id', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    
    await db.delete(expenses).where(eq(expenses.id, id));
    
    return reply.send({ success: true });
  });
};

export default expensesRoutes;
