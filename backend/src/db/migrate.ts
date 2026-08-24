import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import { migrate } from 'drizzle-orm/mysql2/migrator';
import { getDatabaseUrl } from './config';
import path from 'path';
import fs from 'fs';

export async function runMigrations() {
  const dbUrl = getDatabaseUrl();
  console.log('[migrate] Connecting to database...');

  try {
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
  } catch (err) {
    console.error('[migrate] Migration warning/error:', err);
  }
}

if (require.main === module) {
  runMigrations().then(() => process.exit(0)).catch(() => process.exit(1));
}
