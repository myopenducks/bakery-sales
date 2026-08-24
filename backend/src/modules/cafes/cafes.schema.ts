import { z } from 'zod';

export const createCafeSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone: z.string().optional(),
});

export const updateCafeSchema = createCafeSchema.partial();

export type CreateCafeInput = z.infer<typeof createCafeSchema>;
export type UpdateCafeInput = z.infer<typeof updateCafeSchema>;
