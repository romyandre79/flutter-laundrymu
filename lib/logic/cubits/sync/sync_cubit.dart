import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_laundry_offline_app/core/services/api_service.dart';

part 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final ApiService _apiService;

  SyncCubit() : _apiService = ApiService(), super(SyncOffline());

  void toggleMode() {
    if (state is SyncOnline || state is SyncCompleted || state is Syncing) {
      goOffline();
    } else {
      goOnline();
    }
  }

  void goOffline() {
    emit(SyncOffline());
  }

  Future<void> goOnline() async {
    emit(Syncing());
    // Try to connect to backend
    final isConnected = await _apiService.checkHealth();
    if (isConnected) {
      emit(SyncOnline());
    } else {
      emit(const SyncFailed("Cannot connect to Backend"));
      await Future.delayed(const Duration(seconds: 2));
      // Revert to previous state if failed, or just Offline
      emit(SyncOffline());
    }
  }

  Future<void> syncData() async {
    if (state is SyncOffline) {
       emit(const SyncFailed("You are Offline"));
       return;
    }
    
    emit(Syncing());
    try {
      // TODO: Implement actual sync logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate sync
      emit(SyncCompleted());
      await Future.delayed(const Duration(seconds: 1));
      emit(SyncOnline());
    } catch (e) {
      emit(const SyncFailed("Sync failed"));
      await Future.delayed(const Duration(seconds: 2));
      emit(SyncOnline());
    }
  }
}
