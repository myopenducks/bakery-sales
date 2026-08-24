import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/expenses_repository.dart';
import '../providers/expenses_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class ExpenseFormDialog extends ConsumerStatefulWidget {
  final ExpenseModel? expense;

  const ExpenseFormDialog({super.key, this.expense});

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _totalCostController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _nameController = TextEditingController(text: e?.name ?? '');
    _quantityController = TextEditingController(text: e?.quantity != null ? e!.quantity.toString() : '');
    _unitController = TextEditingController(text: e?.unit ?? '');
    _totalCostController = TextEditingController(text: e?.totalCost != null ? e!.totalCost.toString() : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(expensesRepositoryProvider);
      final name = _nameController.text.trim();
      final quantity = num.tryParse(_quantityController.text.trim());
      final unit = _unitController.text.trim();
      final totalCost = int.parse(_totalCostController.text.trim());

      if (widget.expense == null) {
        await repo.createExpense(
          name: name,
          quantity: quantity,
          unit: unit.isEmpty ? null : unit,
          totalCost: totalCost,
        );
      } else {
        await repo.updateExpense(
          id: widget.expense!.id,
          name: name,
          quantity: quantity,
          unit: unit.isEmpty ? null : unit,
          totalCost: totalCost,
        );
      }

      ref.invalidate(expensesListProvider);
      ref.invalidate(dashboardSummaryProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Expense' : 'Record Expense / Purchase',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item / Expense Name *',
                  hintText: 'e.g. Flour, Oil, Sugar...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty (optional)',
                        hintText: 'e.g. 25',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g. kg, L',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _totalCostController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Total Cost (DA) *',
                  hintText: 'e.g. 3200',
                  suffixText: 'DA',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Total cost is required';
                  final parsed = int.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Enter a valid positive amount';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 44),
            backgroundColor: AppColors.primary,
          ),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isEdit ? 'Save' : 'Record'),
        ),
      ],
    );
  }
}
