import { buildApp } from './app';
import { runMigrations } from './db/migrate';
import { runSeed } from './db/seed';

const start = async () => {
  // Run migrations and admin seed gracefully
  await runMigrations();
  await runSeed();

  const app = await buildApp();
  const port = parseInt(process.env.PORT || '3000', 10);
  const host = process.env.HOST || '0.0.0.0';

  try {
    await app.listen({ port, host });
    console.log(`Server listening on http://${host}:${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();
