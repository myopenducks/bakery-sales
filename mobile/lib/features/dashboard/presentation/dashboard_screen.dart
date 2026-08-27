import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../data/dashboard_repository.dart';
import '../providers/dashboard_provider.dart';
import '../../sales/data/sales_repository.dart';
import '../../sales/presentation/sale_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardFilterProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final cafesAsync = ref.watch(dashboardCafesProvider);
    final productsAsync = ref.watch(dashboardProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(dashboardCafesProvider);
              ref.invalidate(dashboardProductsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(dashboardCafesProvider);
          ref.invalidate(dashboardProductsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Filter Selector
              _buildPeriodSelector(context, ref, filter),
              const SizedBox(height: 16),

              // KPI Stats Grid (Revenue, Expenses, Net)
              summaryAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary))),
                error: (err, _) => Card(
                  color: AppColors.error.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(friendlyError(err), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
                  ),
                ),
                data: (summary) => _buildSummaryCards(summary),
              ),
              const SizedBox(height: 24),

              // Top Cafés Ranking
              _buildSectionHeader('Top Cafés', Icons.leaderboard_rounded),
              const SizedBox(height: 8),
              cafesAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary))),
                error: (err, _) => Text(friendlyError(err), style: const TextStyle(color: AppColors.error)),
                data: (cafes) => _buildTopCafesCard(cafes),
              ),
              const SizedBox(height: 24),

              // Best Selling Products
              _buildSectionHeader('Best Selling Products', Icons.emoji_events_rounded),
              const SizedBox(height: 8),
              productsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary))),
                error: (err, _) => Text(friendlyError(err), style: const TextStyle(color: AppColors.error)),
                data: (products) => _buildTopProductsCard(products),
              ),
              const SizedBox(height: 24),

              // Recent Sales
              _buildSectionHeader('Recent Sales', Icons.history_rounded),
              const SizedBox(height: 8),
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (summary) => _buildRecentSalesList(context, summary.recentSales),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, WidgetRef ref, DashboardFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(ref, 'Today', 'today', filter.period == 'today'),
          const SizedBox(width: 8),
          _buildFilterChip(ref, 'This Week', 'week', filter.period == 'week'),
          const SizedBox(width: 8),
          _buildFilterChip(ref, 'This Month', 'month', filter.period == 'month'),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primaryDark),
            label: Text(
              filter.period == 'custom' && filter.customMonth != null
                  ? filter.customMonth!
                  : 'Previous Month',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: filter.period == 'custom' ? Colors.white : AppColors.textDark,
              ),
            ),
            backgroundColor: filter.period == 'custom' ? AppColors.primaryDark : AppColors.surfaceLight,
            onPressed: () => _pickCustomMonth(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, String periodKey, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(dashboardFilterProvider.notifier).state = DashboardFilter(period: periodKey);
        }
      },
    );
  }

  Future<void> _pickCustomMonth(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month - 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'SELECT MONTH',
    );
    if (picked != null) {
      final monthStr = DateFormat('yyyy-MM').format(picked);
      ref.read(dashboardFilterProvider.notifier).state = DashboardFilter(
        period: 'custom',
        customMonth: monthStr,
      );
    }
  }

  Widget _buildSummaryCards(DashboardSummaryModel summary) {
    return Column(
      children: [
        Row(
          children: [
            // Revenue Card
            Expanded(
              child: _buildKpiCard(
                title: 'Revenue',
                amount: summary.revenue,
                color: AppColors.primary,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            // Expenses Card
            Expanded(
              child: _buildKpiCard(
                title: 'Expenses',
                amount: summary.expenses,
                color: AppColors.error,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Net Result Card
        Card(
          color: summary.net >= 0 ? AppColors.primaryDark : AppColors.error,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Net',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(summary.net),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppFormatters.formatCurrency(amount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color == AppColors.error ? AppColors.error : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildTopCafesCard(List<RankedCafeModel> cafes) {
    if (cafes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No sales to cafés in this period.', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cafes.length > 5 ? 5 : cafes.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cafe = cafes[index];
          final rank = index + 1;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: rank == 1
                  ? const Color(0xFFFFD700)
                  : rank == 2
                      ? const Color(0xFFC0C0C0)
                      : rank == 3
                          ? const Color(0xFFCD7F32)
                          : AppColors.surfaceLight,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.black87 : AppColors.textDark,
                ),
              ),
            ),
            title: Text(
              cafe.cafeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: cafe.bestProduct != null
                ? Text(
                    'Best: ${cafe.bestProduct!.productName} (${AppFormatters.formatCurrency(cafe.bestProduct!.revenue)})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  )
                : null,
            trailing: Text(
              AppFormatters.formatCurrency(cafe.totalRevenue),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopProductsCard(List<RankedProductModel> products) {
    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No product sales recorded in this period.', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length > 5 ? 5 : products.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: const Icon(Icons.cookie_rounded, color: AppColors.primaryDark),
            ),
            title: Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              '${product.salesCount} sales',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: Text(
              AppFormatters.formatCurrency(product.totalRevenue),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentSalesList(BuildContext context, List<SaleModel> recentSales) {
    if (recentSales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recent sales in this period.', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentSales.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final sale = recentSales[index];
          return ListTile(
            title: Text(
              sale.cafeName ?? 'Unknown Café',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              AppFormatters.formatDateTime(sale.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppFormatters.formatCurrency(sale.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id)),
              );
            },
          );
        },
      ),
    );
  }
}
