import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kreatif_laundrymu_app/core/services/api_service.dart';
import 'package:kreatif_laundrymu_app/core/services/log_service.dart';
import 'package:kreatif_laundrymu_app/core/services/sync_service.dart';

part 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncService _syncService;
  final ApiService _apiService;
  final LogService _logService = LogService();

  SyncCubit(this._syncService) : _apiService = ApiService(), super(SyncOffline());

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
    await _logService.log('SYNC_CUBIT', 'Going online... checking server health.');
    // Try to connect to backend
    final isConnected = await _apiService.checkHealth();
    if (isConnected) {
      await _logService.log('SYNC_CUBIT', 'Server is online.');
      emit(SyncOnline());
    } else {
      await _logService.log('SYNC_CUBIT', 'ERROR: Cannot connect to server at ${_apiService.client.options.baseUrl}');
      emit(const SyncFailed("Cannot connect to Backend"));
      await Future.delayed(const Duration(seconds: 2));
      // Revert to previous state if failed, or just Offline
      emit(SyncOffline());
    }
  }

  Future<void> syncData() async {
    emit(Syncing());
    await _logService.log('SYNC_CUBIT', '=== SYNC STARTED ===');
    try {
      // Upload
      final uploadedCount = await _syncService.uploadOrders();
      await _logService.log('SYNC_CUBIT', 'Upload phase complete. $uploadedCount orders synced.');
      
      // Download
      await _syncService.downloadMasterData();
      await _logService.log('SYNC_CUBIT', 'Download phase complete.');
      
      await _logService.log('SYNC_CUBIT', '=== SYNC COMPLETED SUCCESSFULLY ===');
      emit(SyncCompleted());
      await Future.delayed(const Duration(seconds: 2));
      emit(SyncOnline());
    } catch (e) {
      await _logService.log('SYNC_CUBIT', '=== SYNC FAILED: ${e.toString()} ===');
      emit(SyncFailed(e.toString().replaceAll('Exception: ', '')));
      await Future.delayed(const Duration(seconds: 3));
      emit(SyncOnline());
    }
  }

  /// Get current log file path for debugging
  Future<String> getLogPath() async {
    return await _logService.getLogPath();
  }
}
