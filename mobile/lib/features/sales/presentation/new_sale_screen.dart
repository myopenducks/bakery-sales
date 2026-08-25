import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/formatters.dart';
import '../../cafes/data/cafes_repository.dart';
import '../../cafes/providers/cafes_provider.dart';
import '../../products/data/products_repository.dart';
import '../../products/providers/products_provider.dart';
import '../data/sales_repository.dart';
import '../providers/sales_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class SaleDraftItem {
  final ProductModel product;
  String sellingMode; // 'UNIT' | 'KG'
  num quantity;

  SaleDraftItem({
    required this.product,
    required this.sellingMode,
    this.quantity = 1,
  });

  int get unitPrice {
    if (sellingMode == 'UNIT') {
      return product.unitPrice ?? 0;
    } else {
      return product.pricePerKg ?? 0;
    }
  }

  int get subtotal {
    if (sellingMode == 'UNIT') {
      return (quantity.toInt() * (product.unitPrice ?? 0));
    } else {
      return (quantity * (product.pricePerKg ?? 0)).round();
    }
  }
}

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  CafeModel? _selectedCafe;
  final List<SaleDraftItem> _draftItems = [];
  bool _isSubmitting = false;

  int get _grandTotal => _draftItems.fold(0, (sum, item) => sum + item.subtotal);

  void _addProductToDraft(ProductModel product) {
    setState(() {
      final defaultMode = product.supportsUnitSale ? 'UNIT' : 'KG';
      _draftItems.add(SaleDraftItem(
        product: product,
        sellingMode: defaultMode,
        quantity: defaultMode == 'UNIT' ? 10 : 1.0,
      ));
    });
  }

  void _removeDraftItem(int index) {
    setState(() => _draftItems.removeAt(index));
  }

  Future<void> _submitSale() async {
    if (_selectedCafe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a café'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final items = _draftItems.map((item) {
        return SaleItemInput(
          productId: item.product.id,
          sellingMode: item.sellingMode,
          quantity: item.quantity,
        );
      }).toList();

      await ref.read(salesRepositoryProvider).createSale(
            cafeId: _selectedCafe!.id,
            items: items,
          );

      ref.invalidate(salesListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(dashboardCafesProvider);
      ref.invalidate(dashboardProductsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale confirmed successfully!'), backgroundColor: AppColors.success),
        );
        setState(() {
          _draftItems.clear();
          _selectedCafe = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale failed: ${friendlyError(e)}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafesAsync = ref.watch(cafesListProvider);
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  Text(
                    AppFormatters.formatCurrency(_grandTotal),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (_isSubmitting || _draftItems.isEmpty || _selectedCafe == null)
                    ? null
                    : _submitSale,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 22),
                          SizedBox(width: 8),
                          Text('Confirm Sale', style: TextStyle(fontSize: 17)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Café Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_cafe_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Select Café *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    cafesAsync.when(
                      loading: () => const Center(child: LinearProgressIndicator(color: AppColors.primary)),
                      error: (err, _) => Text('Error loading cafes: $err', style: const TextStyle(color: AppColors.error)),
                      data: (cafes) {
                        if (cafes.isEmpty) {
                          return const Text('No cafés found. Please add a café first in the Cafés tab.');
                        }
                        return DropdownButtonFormField<CafeModel>(
                          initialValue: _selectedCafe,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Choose Café...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: cafes.map((c) {
                            return DropdownMenuItem<CafeModel>(
                              value: c,
                              child: Text(
                                c.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                            );
                          }).toList(),
                          onChanged: (c) => setState(() => _selectedCafe = c),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products Section Header & Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products to Sell',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                TextButton.icon(
                  onPressed: () => _showProductPicker(context, productsAsync),
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_draftItems.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_basket_outlined, size: 48, color: AppColors.surfaceSecondary),
                    const SizedBox(height: 12),
                    const Text(
                      'No products added yet',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showProductPicker(context, productsAsync),
                      icon: const Icon(Icons.add),
                      label: const Text('Choose Products'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _draftItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _draftItems[index];
                  final product = item.product;
                  final supportsBoth = product.supportsUnitSale && product.supportsKgSale;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item title & remove button
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                                onPressed: () => _removeDraftItem(index),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          // Mode Selector (if product supports both)
                          if (supportsBoth) ...[
                            Row(
                              children: [
                                const Text('Mode: ', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Unit (Piece)'),
                                  selected: item.sellingMode == 'UNIT',
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: item.sellingMode == 'UNIT' ? Colors.white : AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        item.sellingMode = 'UNIT';
                                        item.quantity = item.quantity.toInt().clamp(1, 9999);
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Kg (Weight)'),
                                  selected: item.sellingMode == 'KG',
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: item.sellingMode == 'KG' ? Colors.white : AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => item.sellingMode = 'KG');
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Quantity / Weight Controls & Line Total
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: item.sellingMode == 'UNIT'
                                    ? Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                                            onPressed: item.quantity > 1
                                                ? () => setState(() => item.quantity -= 1)
                                                : null,
                                          ),
                                          SizedBox(
                                            width: 55,
                                            child: Text(
                                              '${item.quantity.toInt()} pcs',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                            onPressed: () => setState(() => item.quantity += 1),
                                          ),
                                        ],
                                      )
                                    : SizedBox(
                                        height: 46,
                                        child: TextField(
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Weight',
                                            suffixText: 'kg',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                          controller: TextEditingController(text: item.quantity.toString())
                                            ..selection = TextSelection.collapsed(offset: item.quantity.toString().length),
                                          onChanged: (val) {
                                            final parsed = num.tryParse(val);
                                            if (parsed != null && parsed > 0) {
                                              setState(() => item.quantity = parsed);
                                            }
                                          },
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),

                              // Snapshot Subtotal
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '@ ${AppFormatters.formatCurrency(item.unitPrice)}${item.sellingMode == 'KG' ? '/kg' : ''}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                    Text(
                                      AppFormatters.formatCurrency(item.subtotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showProductPicker(BuildContext context, AsyncValue<List<ProductModel>> productsAsync) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose Product to Add',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: productsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Text('Error: $err'),
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(child: Text('No products available. Add products in Products tab.'));
                      }
                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final p = products[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.surfaceLight,
                              child: const Icon(Icons.fastfood_rounded, color: AppColors.primaryDark),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              [
                                if (p.supportsUnitSale) 'Unit: ${AppFormatters.formatCurrency(p.unitPrice)}',
                                if (p.supportsKgSale) 'Kg: ${AppFormatters.formatCurrency(p.pricePerKg)}/kg',
                              ].join(' | '),
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                            onTap: () {
                              Navigator.of(bottomCtx).pop();
                              _addProductToDraft(p);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
