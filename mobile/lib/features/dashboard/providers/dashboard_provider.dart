import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardFilter {
  final String period; // 'today' | 'week' | 'month' | 'custom'
  final String? customMonth; // 'YYYY-MM'

  DashboardFilter({this.period = 'today', this.customMonth});

  DashboardFilter copyWith({String? period, String? customMonth}) {
    return DashboardFilter(
      period: period ?? this.period,
      customMonth: customMonth ?? this.customMonth,
    );
  }
}

final dashboardFilterProvider = StateProvider<DashboardFilter>((ref) {
  return DashboardFilter(period: 'today');
});

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummaryModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final filter = ref.watch(dashboardFilterProvider);
  return await repo.getSummary(period: filter.period, month: filter.customMonth);
});

final dashboardCafesProvider = FutureProvider.autoDispose<List<RankedCafeModel>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final filter = ref.watch(dashboardFilterProvider);
  return await repo.getTopCafes(period: filter.period, month: filter.customMonth);
});

final dashboardProductsProvider = FutureProvider.autoDispose<List<RankedProductModel>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final filter = ref.watch(dashboardFilterProvider);
  return await repo.getTopProducts(period: filter.period, month: filter.customMonth);
});
