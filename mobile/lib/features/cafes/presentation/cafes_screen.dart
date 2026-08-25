import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../providers/cafes_provider.dart';
import '../data/cafes_repository.dart';
import 'cafe_form_dialog.dart';

class CafesScreen extends ConsumerStatefulWidget {
  const CafesScreen({super.key});

  @override
  ConsumerState<CafesScreen> createState() => _CafesScreenState();
}

class _CafesScreenState extends ConsumerState<CafesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cafesAsync = ref.watch(cafesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafés'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCafeDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Café', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search cafés...',
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

          // Café List
          Expanded(
            child: cafesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                    const SizedBox(height: 10),
                    Text('Failed to load cafés: $err', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(cafesListProvider),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (cafes) {
                final filtered = cafes.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 54, color: AppColors.surfaceSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No cafés added yet' : 'No cafés matching "$_searchQuery"',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(cafesListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cafe = filtered[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceSecondary.withValues(alpha: 0.4),
                            child: const Icon(Icons.local_cafe_rounded, color: AppColors.primaryDark),
                          ),
                          title: Text(
                            cafe.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                          ),
                          subtitle: cafe.phone != null && cafe.phone!.isNotEmpty
                              ? Text(
                                  cafe.phone!,
                                  style: const TextStyle(color: AppColors.textMuted),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                onPressed: () => _openCafeDialog(context, cafe),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => _confirmDelete(context, cafe),
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

  void _openCafeDialog(BuildContext context, [CafeModel? cafe]) {
    showDialog(
      context: context,
      builder: (_) => CafeFormDialog(cafe: cafe),
    );
  }

  void _confirmDelete(BuildContext context, CafeModel cafe) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Café?'),
        content: Text('Are you sure you want to delete "${cafe.name}"?'),
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
                await ref.read(cafesRepositoryProvider).deleteCafe(cafe.id);
                ref.invalidate(cafesListProvider);
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
