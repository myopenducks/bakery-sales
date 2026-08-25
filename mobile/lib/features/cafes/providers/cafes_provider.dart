import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/cafes_repository.dart';

final cafesRepositoryProvider = Provider<CafesRepository>((ref) {
  return CafesRepository(ref.watch(dioProvider));
});

final cafesListProvider = FutureProvider<List<CafeModel>>((ref) async {
  final repo = ref.watch(cafesRepositoryProvider);
  return await repo.getCafes();
});
