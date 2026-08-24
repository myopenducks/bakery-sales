import {
  mysqlTable,
  varchar,
  timestamp,
  boolean,
  int,
  decimal,
  mysqlEnum,
} from 'drizzle-orm/mysql-core';
import { sql } from 'drizzle-orm';
import { createId } from '@paralleldrive/cuid2';

export const users = mysqlTable('users', {
  id: varchar('id', { length: 128 }).primaryKey().$defaultFn(() => createId()),
  username: varchar('username', { length: 255 }).notNull().unique(),
  passwordHash: varchar('password_hash', { length: 255 }).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().onUpdateNow().notNull(),
});

export const cafes = mysqlTable('cafes', {
  id: varchar('id', { length: 128 }).primaryKey().$defaultFn(() => createId()),
  name: varchar('name', { length: 255 }).notNull(),
  phone: varchar('phone', { length: 255 }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().onUpdateNow().notNull(),
});

export const products = mysqlTable('products', {
  id: varchar('id', { length: 128 }).primaryKey().$defaultFn(() => createId()),
  name: varchar('name', { length: 255 }).notNull(),
  supportsUnitSale: boolean('supports_unit_sale').notNull().default(false),
  supportsKgSale: boolean('supports_kg_sale').notNull().default(false),
  unitPrice: int('unit_price'), // DA
  pricePerKg: int('price_per_kg'), // DA
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().onUpdateNow().notNull(),
});

export const sales = mysqlTable('sales', {
  id: varchar('id', { length: 128 }).primaryKey().$defaultFn(() => createId()),
  cafeId: varchar('cafe_id', { length: 128 })
    .notNull()
    .references(() => cafes.id),
  totalAmount: int('total_amount').notNull(), // DA
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().onUpdateNow().notNull(),
});

export const saleItems = mysqlTable('sale_items', {
  id: varchar('id', { length: 128 }).primaryKey().$defaultFn(() => createId()),
  saleId: varchar('sale_id', { length: 128 })
    .notNull()
    .references(() => sales.id),
  productId: varchar('product_id', { length: 128 })
    .notNull()
    .references(() => products.id),
  sellingMode: mysqlEnum('selling_mode', ['UNIT', 'KG']).notNull(),
  quantity: decimal('quantity', { precision: 10, scale: 3 }).notNull(),
  unitPriceSnapshot: int('unit_price_snapshot').notNull(), // DA
  totalAmount: int('total_amount').notNull(), // DA
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const expenses = mysqlTable('expenses', {
  id: varchar('id', { length: 128 }).primaryKey().$defaultFn(() => createId()),
  name: varchar('name', { length: 255 }).notNull(),
  quantity: decimal('quantity', { precision: 10, scale: 3 }),
  unit: varchar('unit', { length: 50 }),
  totalCost: int('total_cost').notNull(), // DA
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().onUpdateNow().notNull(),
});
