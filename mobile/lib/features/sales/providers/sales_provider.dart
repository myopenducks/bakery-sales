import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/sales_repository.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(dioProvider));
});

final salesListProvider = FutureProvider.autoDispose<List<SaleModel>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  return await repo.getSales();
});

final saleDetailProvider = FutureProvider.autoDispose.family<SaleModel, String>((ref, id) async {
  final repo = ref.watch(salesRepositoryProvider);
  return await repo.getSaleDetail(id);
});
