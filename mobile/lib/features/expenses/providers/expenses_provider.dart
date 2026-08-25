import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/expenses_repository.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(dioProvider));
});

final expensesListProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  final repo = ref.watch(expensesRepositoryProvider);
  return await repo.getExpenses();
});
