import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import * as schema from './schema';
import * as argon2 from 'argon2';
import { eq } from 'drizzle-orm';
import { getDatabaseUrl } from './config';

async function main() {
  const dbUrl = getDatabaseUrl();
  console.log('[seed] Connecting to database...');
  const connection = await mysql.createConnection(dbUrl);

  const db = drizzle(connection, { schema, mode: 'default' });

  // Check if admin user already exists
  const existing = await db
    .select()
    .from(schema.users)
    .where(eq(schema.users.username, 'admin'))
    .limit(1);

  if (existing.length > 0) {
    console.log('Admin user already exists. Skipping seed.');
  } else {
    console.log('Seeding admin user...');
    const passwordHash = await argon2.hash('admin123');

    await db.insert(schema.users).values({
      username: 'admin',
      passwordHash,
    });
    console.log('Admin user created successfully.');
  }

  await connection.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
