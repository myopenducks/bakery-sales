import { z } from 'zod';

export const createProductSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  supportsUnitSale: z.boolean().default(false),
  supportsKgSale: z.boolean().default(false),
  unitPrice: z.number().int('Money must be an integer').positive('Price must be positive').optional(),
  pricePerKg: z.number().int('Money must be an integer').positive('Price must be positive').optional(),
}).superRefine((data, ctx) => {
  if (!data.supportsUnitSale && !data.supportsKgSale) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Product must support at least one selling mode (Unit or Kg)',
    });
  }

  if (data.supportsUnitSale && data.unitPrice === undefined) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'unitPrice is required when supportsUnitSale is true',
      path: ['unitPrice'],
    });
  }

  if (data.supportsKgSale && data.pricePerKg === undefined) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'pricePerKg is required when supportsKgSale is true',
      path: ['pricePerKg'],
    });
  }
});

export const updateProductSchema = z.object({
  name: z.string().min(1).optional(),
  supportsUnitSale: z.boolean().optional(),
  supportsKgSale: z.boolean().optional(),
  unitPrice: z.number().int().positive().nullable().optional(),
  pricePerKg: z.number().int().positive().nullable().optional(),
}).superRefine((data, ctx) => {
  // We can't do full state validation on partial updates without querying the DB first.
  // The actual route handler will fetch the existing product and validate the merged state.
});

export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
