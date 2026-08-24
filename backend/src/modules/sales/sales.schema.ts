import { z } from 'zod';

export const createSaleItemSchema = z.object({
  productId: z.string().min(1, 'Product ID is required'),
  sellingMode: z.enum(['UNIT', 'KG']),
  quantity: z.number().positive('Quantity must be greater than zero'),
});

export const createSaleSchema = z.object({
  cafeId: z.string().min(1, 'Cafe ID is required'),
  items: z.array(createSaleItemSchema).min(1, 'At least one item is required'),
});

export type CreateSaleInput = z.infer<typeof createSaleSchema>;
