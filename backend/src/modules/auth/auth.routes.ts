import { FastifyPluginAsync } from 'fastify';
import { db } from '../../db';
import { users } from '../../db/schema';
import { eq } from 'drizzle-orm';
import * as argon2 from 'argon2';
import { loginSchema, changePasswordSchema } from './auth.schema';

const authRoutes: FastifyPluginAsync = async (fastify) => {
  // POST /api/v1/auth/login
  fastify.post('/login', async (request, reply) => {
    const parsed = loginSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid input', details: parsed.error.issues });
    }

    const { username, password } = parsed.data;

    const [user] = await db.select().from(users).where(eq(users.username, username));
    if (!user) {
      return reply.status(401).send({ error: 'Invalid credentials' });
    }

    const isValid = await argon2.verify(user.passwordHash, password);
    if (!isValid) {
      return reply.status(401).send({ error: 'Invalid credentials' });
    }

    const token = fastify.jwt.sign({ id: user.id, username: user.username });
    return reply.send({ token });
  });

  // GET /api/v1/auth/me
  fastify.get('/me', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const userId = request.user.id;
    const [user] = await db
      .select({ id: users.id, username: users.username, createdAt: users.createdAt })
      .from(users)
      .where(eq(users.id, userId));
    if (!user) {
      return reply.status(404).send({ error: 'User not found' });
    }
    return reply.send({ user });
  });

  // POST /api/v1/auth/change-password
  fastify.post('/change-password', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const parsed = changePasswordSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.issues[0]?.message || 'Invalid input' });
    }

    const { oldPassword, newPassword } = parsed.data;
    const userId = request.user.id;

    const [user] = await db.select().from(users).where(eq(users.id, userId));
    if (!user) {
      return reply.status(404).send({ error: 'User not found' });
    }

    const isMatch = await argon2.verify(user.passwordHash, oldPassword);
    if (!isMatch) {
      return reply.status(400).send({ error: 'Current password is incorrect' });
    }

    const newHash = await argon2.hash(newPassword);
    await db.update(users).set({ passwordHash: newHash }).where(eq(users.id, userId));

    return reply.send({ success: true, message: 'Password updated successfully' });
  });
};

export default authRoutes;
