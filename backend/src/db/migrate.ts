import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import { migrate } from 'drizzle-orm/mysql2/migrator';
import { getDatabaseUrl } from './config';
import path from 'path';
import fs from 'fs';

async function main() {
  const dbUrl = getDatabaseUrl();
  console.log('[migrate] Connecting to database...');

  // Connect directly with database connection string
  const connection = await mysql.createConnection(dbUrl);
  const db = drizzle(connection);

  let migrationsFolder = path.resolve(__dirname, '../../drizzle');
  if (!fs.existsSync(migrationsFolder)) {
    migrationsFolder = path.resolve(process.cwd(), 'backend/drizzle');
    if (!fs.existsSync(migrationsFolder)) {
      migrationsFolder = path.resolve(process.cwd(), 'drizzle');
    }
  }

  console.log(`[migrate] Running migrations from ${migrationsFolder}...`);
  await migrate(db, { migrationsFolder });
  console.log('[migrate] Migrations completed successfully.');

  await connection.end();
}

main().catch((err) => {
  console.error('[migrate] Migration error:', err);
  process.exit(1);
});
