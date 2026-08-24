import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/cafes_repository.dart';
import '../providers/cafes_provider.dart';

class CafeFormDialog extends ConsumerStatefulWidget {
  final CafeModel? cafe;

  const CafeFormDialog({super.key, this.cafe});

  @override
  ConsumerState<CafeFormDialog> createState() => _CafeFormDialogState();
}

class _CafeFormDialogState extends ConsumerState<CafeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cafe?.name ?? '');
    _phoneController = TextEditingController(text: widget.cafe?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(cafesRepositoryProvider);
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (widget.cafe == null) {
        await repo.createCafe(name, phone.isEmpty ? null : phone);
      } else {
        await repo.updateCafe(widget.cafe!.id, name, phone.isEmpty ? null : phone);
      }

      ref.invalidate(cafesListProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save café: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.cafe != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Café' : 'New Café',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Café Name *',
                hintText: 'e.g. Café El Bahia',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                hintText: 'e.g. 0550xxxxxx',
              ),
            ),
          ],
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
              : Text(isEdit ? 'Save' : 'Add Café'),
        ),
      ],
    );
  }
}
