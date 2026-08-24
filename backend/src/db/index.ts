import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import * as schema from './schema';
import { getDatabaseUrl } from './config';

const poolConnection = mysql.createPool({
  uri: getDatabaseUrl(),
});

export const db = drizzle(poolConnection, { schema, mode: 'default' });

