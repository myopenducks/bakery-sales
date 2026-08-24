import * as dotenv from 'dotenv';
dotenv.config();

function cleanEnv(val: string | undefined): string | undefined {
  if (!val) return undefined;
  let clean = val.trim();
  if ((clean.startsWith('"') && clean.endsWith('"')) || (clean.startsWith("'") && clean.endsWith("'"))) {
    clean = clean.slice(1, -1).trim();
  }
  // If it's an unresolved template variable like ${{...}}, ignore it
  if (clean.startsWith('${{') || clean.length === 0) {
    return undefined;
  }
  return clean;
}

function isValidMysqlUrl(url: string | undefined): boolean {
  if (!url) return false;
  return url.startsWith('mysql://') || url.startsWith('mysql2://');
}

export function getDatabaseUrl(): string {
  const possibleUrls = [
    cleanEnv(process.env.MYSQL_URL),
    cleanEnv(process.env.DATABASE_URL),
    cleanEnv(process.env.MYSQL_PRIVATE_URL),
    cleanEnv(process.env.MYSQL_PUBLIC_URL),
  ];

  for (const url of possibleUrls) {
    if (isValidMysqlUrl(url)) {
      try {
        const parsed = new URL(url!);
        console.log(`[db] Using MySQL connection: host=${parsed.hostname}, port=${parsed.port || '3306'}, database=${parsed.pathname.replace('/', '')}`);
      } catch {
        console.log('[db] Using MySQL connection URL');
      }
      return url!;
    }
  }

  // Handle individual Railway/PaaS variables
  const host = cleanEnv(process.env.MYSQLHOST) || cleanEnv(process.env.DB_HOST) || '127.0.0.1';
  const port = cleanEnv(process.env.MYSQLPORT) || cleanEnv(process.env.DB_PORT) || '3306';
  const user = cleanEnv(process.env.MYSQLUSER) || cleanEnv(process.env.DB_USER) || 'root';
  const password = cleanEnv(process.env.MYSQLPASSWORD) || cleanEnv(process.env.DB_PASSWORD) || '';
  const database = cleanEnv(process.env.MYSQLDATABASE) || cleanEnv(process.env.DB_NAME) || 'bakery_sales';

  console.log(`[db] Constructed MySQL target: host=${host}, port=${port}, user=${user}, database=${database}`);

  const auth = password ? `${encodeURIComponent(user)}:${encodeURIComponent(password)}` : encodeURIComponent(user);
  return `mysql://${auth}@${host}:${port}/${database}`;
}
