import Fastify, { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyCors from '@fastify/cors';
import * as dotenv from 'dotenv';
import authRoutes from './modules/auth/auth.routes';
import cafesRoutes from './modules/cafes/cafes.routes';
import productsRoutes from './modules/products/products.routes';
import salesRoutes from './modules/sales/sales.routes';
import expensesRoutes from './modules/expenses/expenses.routes';
import dashboardRoutes from './modules/dashboard/dashboard.routes';

dotenv.config();

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: { id: string, username: string }
    user: { id: string, username: string }
  }
}

export const buildApp = async (): Promise<FastifyInstance> => {
  const app = Fastify({ logger: true });

  // Plugins
  await app.register(fastifyCors, {
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // Gracefully handle empty JSON body on requests like DELETE/GET where clients send Content-Type header
  app.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
    if (!body || (typeof body === 'string' && body.trim().length === 0)) {
      done(null, undefined);
      return;
    }
    try {
      const json = JSON.parse(body as string);
      done(null, json);
    } catch (err: any) {
      err.statusCode = 400;
      done(err, undefined);
    }
  });

  await app.register(fastifyJwt, {
    secret: process.env.JWT_SECRET || 'super_secret_jwt_key_change_me'
  });

  // Decorators
  app.decorate('authenticate', async function (request: FastifyRequest, reply: FastifyReply) {
    try {
      await request.jwtVerify();
    } catch (err) {
      reply.send(err);
    }
  });

  // Healthcheck for Railway / monitoring
  app.get('/health', async () => {
    return { status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() };
  });

  // Routes
  await app.register(authRoutes, { prefix: '/api/v1/auth' });
  await app.register(cafesRoutes, { prefix: '/api/v1/cafes' });
  await app.register(productsRoutes, { prefix: '/api/v1/products' });
  await app.register(salesRoutes, { prefix: '/api/v1/sales' });
  await app.register(expensesRoutes, { prefix: '/api/v1/expenses' });
  await app.register(dashboardRoutes, { prefix: '/api/v1/dashboard' });

  return app;
};
