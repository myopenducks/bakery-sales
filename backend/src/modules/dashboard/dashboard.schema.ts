import { z } from 'zod';

export const dashboardQuerySchema = z.object({
  period: z.enum(['today', 'week', 'month', 'custom']).default('today'),
  month: z.string().regex(/^\d{4}-\d{2}$/, 'Month must be in YYYY-MM format').optional(),
});

export type DashboardQuery = z.infer<typeof dashboardQuerySchema>;
