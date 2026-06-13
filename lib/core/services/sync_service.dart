import 'dart:async';
import 'package:flutter/foundation.dart';
import 'remote_service.dart';
import 'storage_service.dart';

/// Handles background synchronization of local Hive tasks to the RemoteService.
/// Uses a persistent outbox pattern to ensure data durability.
class SyncService {
  final RemoteService _remote;
  bool _isProcessing = false;

  SyncService(this._remote);

  RemoteService get remote => _remote;

  /// Enqueues a task for background synchronization.
  /// Persists the task to local storage instantly.
  Future<void> enqueueTask(String action, Map<dynamic, dynamic> payload) async {
    final taskId = '${DateTime.now().millisecondsSinceEpoch}_$action';
    final task = {
      'taskId': taskId,
      'action': action,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await StorageService.instance.enqueueSyncTask(task);
      debugPrint('[SyncService] Task enqueued: $taskId');
      // Kick off processing in the background without awaiting it here
      processQueue();
    } catch (e) {
      debugPrint('[SyncService] Failed to enqueue task: $e');
    }
  }

  /// Iterates through the persistent task queue and attempts to sync with RemoteService.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final tasks = StorageService.instance.getSyncTasks();
      if (tasks.isEmpty) return;

      debugPrint('[SyncService] Processing queue (${tasks.length} tasks)...');

      // Sort by timestamp to ensure chronological order
      tasks.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));

      for (var task in tasks) {
        final taskId = task['taskId'] as String;
        final action = task['action'] as String;
        final payload = task['payload'] as Map<dynamic, dynamic>;

        bool success = false;
        try {
          switch (action) {
            case 'saveProfile':   await _remote.saveProfile(payload); break;
            case 'saveSession':   await _remote.saveSession(payload); break;
            case 'deleteSession': await _remote.deleteSession(payload['id'] as String); break;
            case 'saveRoutine':   await _remote.saveRoutine(payload); break;
            case 'deleteRoutine': await _remote.deleteRoutine(payload['id'] as String); break;
            case 'saveFeedPost':  await _remote.saveFeedPost(payload); break;
            default: 
              debugPrint('[SyncService] Unknown action ignored: $action');
              success = true; // Mark true to remove from queue
              break;
          }
          success = true;
        } catch (e) {
          debugPrint('[SyncService] Task $taskId failed (will retry): $e');
          // If a task fails (likely network), we stop processing the queue 
          // to preserve order and avoid spamming failures.
          break;
        }

        if (success) {
          await StorageService.instance.removeSyncTask(taskId);
          debugPrint('[SyncService] Task completed and removed: $taskId');
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
