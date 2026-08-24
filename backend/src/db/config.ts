import * as dotenv from 'dotenv';
dotenv.config();

export function getDatabaseUrl(): string {
  if (process.env.MYSQL_URL) {
    return process.env.MYSQL_URL;
  }
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  // Handle individual Railway/PaaS variables
  const host = process.env.MYSQLHOST || process.env.DB_HOST || '127.0.0.1';
  const port = process.env.MYSQLPORT || process.env.DB_PORT || '3306';
  const user = process.env.MYSQLUSER || process.env.DB_USER || 'root';
  const password = process.env.MYSQLPASSWORD || process.env.DB_PASSWORD || '';
  const database = process.env.MYSQLDATABASE || process.env.DB_NAME || 'bakery_sales';

  const auth = password ? `${user}:${password}` : user;
  return `mysql://${auth}@${host}:${port}/${database}`;
}
