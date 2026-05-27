import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_app/data/models/unit.dart';
import 'package:kreatif_laundry_app/data/repositories/unit_repository.dart';
import 'package:kreatif_laundry_app/logic/cubits/unit/unit_state.dart';

class UnitCubit extends Cubit<UnitState> {
  final UnitRepository _unitRepository;

  UnitCubit({UnitRepository? unitRepository})
      : _unitRepository = unitRepository ?? UnitRepository(),
        super(UnitInitial());

  Future<void> loadUnits() async {
    emit(UnitLoading());
    try {
      final units = await _unitRepository.getUnits();
      emit(UnitLoaded(units));
    } catch (e) {
      emit(UnitError('Gagal memuat units: $e'));
    }
  }

  Future<void> addUnit(String name) async {
    try {
      await _unitRepository.insertUnit(Unit(name: name));
      emit(UnitOperationSuccess('Unit berhasil ditambahkan'));
      loadUnits();
    } catch (e) {
      emit(UnitError('Gagal menambah unit: $e'));
    }
  }

  Future<void> updateUnit(Unit unit) async {
    try {
      await _unitRepository.updateUnit(unit);
      emit(UnitOperationSuccess('Unit berhasil diperbarui'));
      loadUnits();
    } catch (e) {
      emit(UnitError('Gagal memperbarui unit: $e'));
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      await _unitRepository.deleteUnit(id);
      emit(UnitOperationSuccess('Unit berhasil dihapus'));
      loadUnits();
    } catch (e) {
      emit(UnitError('Gagal menghapus unit: $e'));
    }
  }
}
