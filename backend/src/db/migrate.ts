import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import { migrate } from 'drizzle-orm/mysql2/migrator';
import { getDatabaseUrl } from './config';

async function main() {
  const dbUrl = getDatabaseUrl();
  const urlObj = new URL(dbUrl);
  const dbName = urlObj.pathname.replace('/', '') || 'bakery_sales';

  // 1. Ensure the database exists
  try {
    const rootConn = await mysql.createConnection({
      host: urlObj.hostname || '127.0.0.1',
      port: urlObj.port ? parseInt(urlObj.port) : 3306,
      user: urlObj.username || 'root',
      password: urlObj.password || '',
    });

    await rootConn.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
    await rootConn.end();
  } catch (e) {
    console.log('Database check/create skipped or not permitted:', e);
  }

  // 2. Connect to the database and run migrations
  const connection = await mysql.createConnection({
    uri: dbUrl,
  });

  const db = drizzle(connection);

  const path = await import('path');
  const fs = await import('fs');

  let migrationsFolder = path.resolve(__dirname, '../../drizzle');
  if (!fs.existsSync(migrationsFolder)) {
    migrationsFolder = path.resolve(process.cwd(), 'backend/drizzle');
    if (!fs.existsSync(migrationsFolder)) {
      migrationsFolder = path.resolve(process.cwd(), 'drizzle');
    }
  }

  console.log(`Running migrations from ${migrationsFolder}...`);
  await migrate(db, { migrationsFolder });
  console.log('Migrations complete.');

  await connection.end();
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
