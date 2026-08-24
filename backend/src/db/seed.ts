import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import * as schema from './schema';
import * as argon2 from 'argon2';
import { eq } from 'drizzle-orm';
import { getDatabaseUrl } from './config';

export async function runSeed() {
  try {
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
      console.log('[seed] Admin user already exists. Skipping seed.');
    } else {
      console.log('[seed] Seeding admin user...');
      const passwordHash = await argon2.hash('admin123');

      await db.insert(schema.users).values({
        username: 'admin',
        passwordHash,
      });
      console.log('[seed] Admin user created successfully.');
    }

    await connection.end();
  } catch (err) {
    console.error('[seed] Seed warning/error:', err);
  }
}

if (require.main === module) {
  runSeed().then(() => process.exit(0)).catch(() => process.exit(1));
}
