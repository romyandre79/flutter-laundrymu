part of 'sync_cubit.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object> get props => [];
}

class SyncInitial extends SyncState {}

class SyncOffline extends SyncState {}

class SyncOnline extends SyncState {}

class Syncing extends SyncState {}

class SyncCompleted extends SyncState {}

class SyncFailed extends SyncState {
  final String message;

  const SyncFailed(this.message);

  @override
  List<Object> get props => [message];
}
