import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../providers/expenses_provider.dart';
import '../data/expenses_repository.dart';
import 'expense_form_dialog.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses & Purchases'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Record Expense', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 10),
              Text(friendlyError(err), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(expensesListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 54, color: AppColors.surfaceSecondary),
                  SizedBox(height: 12),
                  Text('No expenses recorded yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(expensesListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: expenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.error.withValues(alpha: 0.12),
                      child: const Icon(Icons.shopping_cart_outlined, color: AppColors.error),
                    ),
                    title: Text(
                      expense.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (expense.quantity != null)
                          Text(
                            'Qty: ${AppFormatters.formatQuantity(expense.quantity, expense.unit)}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        Text(
                          AppFormatters.formatDate(expense.createdAt),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormatters.formatCurrency(expense.totalCost),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.error,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _openExpenseDialog(context, expense);
                            } else if (val == 'delete') {
                              _confirmDelete(context, ref, expense);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openExpenseDialog(BuildContext context, [ExpenseModel? expense]) {
    showDialog(
      context: context,
      builder: (_) => ExpenseFormDialog(expense: expense),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(90, 40)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await ref.read(expensesRepositoryProvider).deleteExpense(expense.id);
                ref.invalidate(expensesListProvider);
                ref.invalidate(dashboardSummaryProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: ${friendlyError(e)}'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
