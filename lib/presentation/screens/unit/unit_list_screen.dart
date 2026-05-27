import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_app/data/models/unit.dart';
import 'package:kreatif_laundry_app/logic/cubits/unit/unit_cubit.dart';
import 'package:kreatif_laundry_app/logic/cubits/unit/unit_state.dart';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UnitCubit>().loadUnits();
  }

  void _showUnitDialog([Unit? unit]) {
    final TextEditingController nameController = TextEditingController(text: unit?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Text(unit == null ? 'Tambah Unit' : 'Edit Unit', style: AppTypography.titleLarge),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Unit (kg, pcs, dll)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: AppTypography.labelMedium.copyWith(color: AppThemeColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                if (unit == null) {
                  context.read<UnitCubit>().addUnit(nameController.text);
                } else {
                  context.read<UnitCubit>().updateUnit(unit.copyWith(name: nameController.text));
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.primary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
            ),
            child: Text('Simpan', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Unit unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Text('Hapus Unit', style: AppTypography.titleLarge),
        content: Text('Apakah Anda yakin ingin menghapus unit "${unit.name}"?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: AppTypography.labelMedium.copyWith(color: AppThemeColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UnitCubit>().deleteUnit(unit.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.error,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
            ),
            child: Text('Hapus', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        title: Text('Kelola Satuan (Unit)', style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppThemeColors.headerGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<UnitCubit, UnitState>(
        listener: (context, state) {
          if (state is UnitOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.success),
            );
          } else if (state is UnitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppThemeColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is UnitLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UnitLoaded) {
            final units = state.units;
            if (units.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.straighten, size: 64, color: AppThemeColors.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Belum ada data unit', style: AppTypography.bodyLarge.copyWith(color: AppThemeColors.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final unit = units[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius,
                    side: const BorderSide(color: AppThemeColors.border),
                  ),
                  child: ListTile(
                    title: Text(unit.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppThemeColors.primary),
                          onPressed: () => _showUnitDialog(unit),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppThemeColors.error),
                          onPressed: () => _confirmDelete(unit),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Terjadi kesalahan'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUnitDialog(),
        backgroundColor: AppThemeColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
