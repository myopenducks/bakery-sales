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

  console.log('Running migrations...');
  await migrate(db, { migrationsFolder: './drizzle' });
  console.log('Migrations complete.');

  await connection.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
