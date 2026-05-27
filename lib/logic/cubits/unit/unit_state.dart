import 'package:kreatif_laundry_app/data/models/unit.dart';

abstract class UnitState {}

class UnitInitial extends UnitState {}

class UnitLoading extends UnitState {}

class UnitLoaded extends UnitState {
  final List<Unit> units;
  UnitLoaded(this.units);
}

class UnitOperationSuccess extends UnitState {
  final String message;
  UnitOperationSuccess(this.message);
}

class UnitError extends UnitState {
  final String message;
  UnitError(this.message);
}
