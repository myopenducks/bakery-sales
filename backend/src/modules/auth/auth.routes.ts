import { FastifyPluginAsync } from 'fastify';
import { db } from '../../db';
import { users } from '../../db/schema';
import { eq } from 'drizzle-orm';
import * as argon2 from 'argon2';
import { loginSchema } from './auth.schema';

const authRoutes: FastifyPluginAsync = async (fastify) => {
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

  fastify.get('/me', { preValidation: [fastify.authenticate] }, async (request, reply) => {
    const userId = request.user.id;
    const [user] = await db.select({ id: users.id, username: users.username, createdAt: users.createdAt }).from(users).where(eq(users.id, userId));
    if (!user) {
      return reply.status(404).send({ error: 'User not found' });
    }
    return reply.send({ user });
  });
};

export default authRoutes;
