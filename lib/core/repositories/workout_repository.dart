import '../models/workout_session.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

/// Orchestrates data flow for workouts and routines.
/// Reads locally. Writes locally instantly, then syncs remotely async.
class WorkoutRepository {
  final SyncService _syncService;

  WorkoutRepository(this._syncService);

  List<WorkoutSession> getSessions() {
    return StorageService.instance.getSessions();
  }

  Future<void> saveSession(WorkoutSession session) async {
    await StorageService.instance.saveSession(session);
    _syncService.enqueueTask('saveSession', session.toMap());
  }

  Future<void> deleteSession(String id) async {
    await StorageService.instance.deleteSession(id);
    _syncService.enqueueTask('deleteSession', {'id': id});
  }

  List<WorkoutSession> getRoutines() {
    return StorageService.instance.getRoutines();
  }

  Future<void> saveRoutine(WorkoutSession routine) async {
    await StorageService.instance.saveRoutine(routine);
    _syncService.enqueueTask('saveRoutine', routine.toMap());
  }

  Future<void> deleteRoutine(String id) async {
    await StorageService.instance.deleteRoutine(id);
    _syncService.enqueueTask('deleteRoutine', {'id': id});
  }
}
