import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_app/logic/cubits/unit/unit_cubit.dart';
import 'package:kreatif_laundry_app/logic/cubits/unit/unit_state.dart';
import 'package:kreatif_laundry_app/data/models/unit.dart';
import 'package:kreatif_laundry_app/presentation/widgets/base_searchable_picker.dart';

class SearchableUnitPicker extends StatelessWidget {
  final String? selectedUnit;
  final Function(String) onUnitSelected;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;

  const SearchableUnitPicker({
    super.key,
    this.selectedUnit,
    required this.onUnitSelected,
    this.label,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnitCubit, UnitState>(
      builder: (context, state) {
        List<Unit> units = [];
        bool isLoading = state is UnitInitial || state is UnitLoading;
        
        if (state is UnitLoaded) {
          units = state.units;
        }

        return BaseSearchablePicker<Unit>(
          title: 'Pilih Satuan',
          label: label,
          hint: hint,
          items: units,
          isLoading: isLoading,
          selectedValue: units.any((u) => u.name == selectedUnit) 
            ? units.firstWhere((u) => u.name == selectedUnit) 
            : null,
          itemLabel: (unit) => unit.name,
          searchMatcher: (unit, query) => unit.name.toLowerCase().contains(query.toLowerCase()),
          onSelected: (unit) => onUnitSelected(unit.name),
          onRefresh: () => context.read<UnitCubit>().loadUnits(),
          validator: (val) => validator?.call(val?.name),
          icon: Icons.straighten,
          emptyMessage: 'Satuan tidak ditemukan',
        );
      },
    );
  }
}
