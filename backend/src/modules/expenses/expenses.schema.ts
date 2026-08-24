import { z } from 'zod';

export const createExpenseSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  quantity: z.number().positive('Quantity must be greater than zero').optional(),
  unit: z.string().optional(),
  totalCost: z.number().int('Cost must be an integer').positive('Cost must be positive'),
});

export const updateExpenseSchema = createExpenseSchema.partial();

export type CreateExpenseInput = z.infer<typeof createExpenseSchema>;
export type UpdateExpenseInput = z.infer<typeof updateExpenseSchema>;
