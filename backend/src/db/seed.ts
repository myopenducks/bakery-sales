import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import * as dotenv from 'dotenv';
import * as schema from './schema';
import * as argon2 from 'argon2';

dotenv.config();

async function main() {
  const connection = await mysql.createConnection({
    uri: process.env.DATABASE_URL || 'mysql://root:@localhost:3306/bakery_sales',
  });

  const db = drizzle(connection, { schema, mode: 'default' });

  console.log('Seeding admin user...');

  // Create admin user
  const passwordHash = await argon2.hash('admin123');

  await db.insert(schema.users).values({
    username: 'admin',
    passwordHash,
  });

  console.log('Seeding complete.');
  await connection.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
