import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/products_repository.dart';
import '../providers/products_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _pricePerKgController;

  late bool _supportsUnit;
  late bool _supportsKg;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _unitPriceController = TextEditingController(text: p?.unitPrice != null ? p!.unitPrice.toString() : '');
    _pricePerKgController = TextEditingController(text: p?.pricePerKg != null ? p!.pricePerKg.toString() : '');
    _supportsUnit = p?.supportsUnitSale ?? true;
    _supportsKg = p?.supportsKgSale ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitPriceController.dispose();
    _pricePerKgController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_supportsUnit && !_supportsKg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable at least one selling mode (Unit or Kg)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final name = _nameController.text.trim();
      final unitPrice = _supportsUnit ? int.tryParse(_unitPriceController.text.trim()) : null;
      final pricePerKg = _supportsKg ? int.tryParse(_pricePerKgController.text.trim()) : null;

      if (widget.product == null) {
        await repo.createProduct(
          name: name,
          supportsUnitSale: _supportsUnit,
          supportsKgSale: _supportsKg,
          unitPrice: unitPrice,
          pricePerKg: pricePerKg,
        );
      } else {
        await repo.updateProduct(
          id: widget.product!.id,
          name: name,
          supportsUnitSale: _supportsUnit,
          supportsKgSale: _supportsKg,
          unitPrice: unitPrice,
          pricePerKg: pricePerKg,
        );
      }

      ref.invalidate(productsListProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Msemmen or Trid',
                  prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
              ),
              const SizedBox(height: 24),

              // Selling Modes Header
              const Text(
                'Selling Modes & Pricing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A product can be sold by piece (Unit), by weight (Kg), or both.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Mode 1: Unit / Piece
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Sell by Unit / Piece',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text('e.g. 40 DA per piece'),
                        value: _supportsUnit,
                        onChanged: (val) {
                          setState(() {
                            _supportsUnit = val;
                            if (!_supportsUnit && !_supportsKg) _supportsKg = true;
                          });
                        },
                      ),
                      if (_supportsUnit) ...[
                        const Divider(height: 20),
                        TextFormField(
                          controller: _unitPriceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Unit Price (DA) *',
                            hintText: 'e.g. 40',
                            suffixText: 'DA',
                          ),
                          validator: (v) {
                            if (!_supportsUnit) return null;
                            if (v == null || v.trim().isEmpty) return 'Enter unit price';
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed <= 0) return 'Enter a valid positive price';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Mode 2: Kilogram / Weight
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Sell by Kilogram (Kg)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text('e.g. 320 DA per kg'),
                        value: _supportsKg,
                        onChanged: (val) {
                          setState(() {
                            _supportsKg = val;
                            if (!_supportsKg && !_supportsUnit) _supportsUnit = true;
                          });
                        },
                      ),
                      if (_supportsKg) ...[
                        const Divider(height: 20),
                        TextFormField(
                          controller: _pricePerKgController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Price per Kg (DA) *',
                            hintText: 'e.g. 320',
                            suffixText: 'DA / kg',
                          ),
                          validator: (v) {
                            if (!_supportsKg) return null;
                            if (v == null || v.trim().isEmpty) return 'Enter price per kg';
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed <= 0) return 'Enter a valid positive price';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(isEdit ? 'Update Product' : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
