import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../data/products_repository.dart';
import '../providers/products_provider.dart';
import 'product_form_screen.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Product List
          Expanded(
            child: productsAsync.when(
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
                      onPressed: () => ref.invalidate(productsListProvider),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (products) {
                final filtered = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cookie_outlined, size: 54, color: AppColors.surfaceSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No products created yet' : 'No products matching "$_searchQuery"',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(productsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.surfaceLight,
                                    child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryDark),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                    onPressed: () => _openProductForm(context, product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _confirmDelete(context, product),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (product.supportsUnitSale)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSecondary.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.surfaceSecondary),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primaryDark),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Unit: ${AppFormatters.formatCurrency(product.unitPrice)}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (product.supportsKgSale)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.scale_rounded, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Kg: ${AppFormatters.formatCurrency(product.pricePerKg)}/kg',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
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
          ),
        ],
      ),
    );
  }

  void _openProductForm(BuildContext context, [ProductModel? product]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(90, 40)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogCtx).pop();
              try {
                await ref.read(productsRepositoryProvider).deleteProduct(product.id);
                ref.invalidate(productsListProvider);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Delete failed: ${friendlyError(e)}'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
