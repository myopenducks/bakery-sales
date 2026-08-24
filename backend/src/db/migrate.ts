import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import { migrate } from 'drizzle-orm/mysql2/migrator';
import * as dotenv from 'dotenv';

dotenv.config();

async function main() {
  const dbUrl = process.env.DATABASE_URL || 'mysql://root:1234@127.0.0.1:3306/bakery_sales';
  const urlObj = new URL(dbUrl);
  const dbName = urlObj.pathname.replace('/', '') || 'bakery_sales';

  // 1. Ensure the database exists
  const rootConn = await mysql.createConnection({
    host: urlObj.hostname || '127.0.0.1',
    port: urlObj.port ? parseInt(urlObj.port) : 3306,
    user: urlObj.username || 'root',
    password: urlObj.password || '1234',
  });

  await rootConn.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\`;`);
  await rootConn.end();

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
