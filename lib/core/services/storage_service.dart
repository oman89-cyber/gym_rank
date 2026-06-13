import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_session.dart';
import '../models/user_profile.dart';

/// Keys for Hive boxes.
class _Keys {
  static const String sessions  = 'sessions';
  static const String routines  = 'routines';
  static const String profile   = 'profile';
  static const String feed      = 'feed';
  static const String syncQueue = 'syncQueue';
}

/// Manages all Hive I/O for workouts and user profile.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late final Box<dynamic> _sessionsBox;
  late final Box<dynamic> _routinesBox;
  late final Box<dynamic> _profileBox;
  late final Box<dynamic> _feedBox;
  late final Box<dynamic> _syncQueueBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _sessionsBox = await Hive.openBox<dynamic>(_Keys.sessions);
    _routinesBox = await Hive.openBox<dynamic>(_Keys.routines);
    _profileBox  = await Hive.openBox<dynamic>(_Keys.profile);
    _feedBox     = await Hive.openBox<dynamic>(_Keys.feed);
    _syncQueueBox = await Hive.openBox<dynamic>(_Keys.syncQueue);
  }

  // ── Profile ────────────────────────────────────────────────────────
  UserProfile getProfile() {
    final raw = _profileBox.get('user');
    if (raw == null) return UserProfile.initial();
    return UserProfile.fromMap(raw as Map);
  }

  Future<void> saveProfile(UserProfile profile) =>
      _profileBox.put('user', profile.toMap());

  bool get isGuestMode => _profileBox.get('guest_mode', defaultValue: false) as bool;
  Future<void> setGuestMode(bool isGuest) => _profileBox.put('guest_mode', isGuest);

  String? get lastUid => _profileBox.get('last_uid') as String?;
  Future<void> setLastUid(String? uid) {
    if (uid == null) {
      return _profileBox.delete('last_uid');
    }
    return _profileBox.put('last_uid', uid);
  }

  // ── Sessions ───────────────────────────────────────────────────────
  List<WorkoutSession> getSessions() {
    return _sessionsBox.values
        .map((v) => WorkoutSession.fromMap(v as Map))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first
  }

  Future<void> saveSession(WorkoutSession session) =>
      _sessionsBox.put(session.id, session.toMap());

  Future<void> deleteSession(String id) =>
      _sessionsBox.delete(id);

  /// Sessions from the past [days] days.
  List<WorkoutSession> recentSessions({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return getSessions().where((s) => s.date.isAfter(cutoff)).toList();
  }

  // ── Routines ───────────────────────────────────────────────────────
  List<WorkoutSession> getRoutines() {
    return _routinesBox.values
        .map((v) => WorkoutSession.fromMap(v as Map))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveRoutine(WorkoutSession routine) =>
      _routinesBox.put(routine.id, routine.toMap());

  Future<void> deleteRoutine(String id) =>
      _routinesBox.delete(id);

  // ── Feed posts (serialized WorkoutSession ids + metadata) ──────────
  List<Map<dynamic, dynamic>> getFeedPosts() {
    return _feedBox.values
        .cast<Map<dynamic, dynamic>>()
        .toList()
      ..sort((a, b) {
        final da = DateTime.parse(a['date'] as String);
        final db = DateTime.parse(b['date'] as String);
        return db.compareTo(da);
      });
  }

  Future<void> addFeedPost(Map<String, dynamic> post) =>
      _feedBox.put(post['id'], post);

  // ── Sync Queue ─────────────────────────────────────────────────────
  List<Map<dynamic, dynamic>> getSyncTasks() {
    return _syncQueueBox.values.cast<Map<dynamic, dynamic>>().toList();
  }

  Future<void> enqueueSyncTask(Map<String, dynamic> task) {
    if (!task.containsKey('taskId')) {
      throw Exception('Sync task must have a taskId parameter');
    }
    return _syncQueueBox.put(task['taskId'], task);
  }

  Future<void> removeSyncTask(String taskId) =>
      _syncQueueBox.delete(taskId);

  Future<void> clearSyncQueue() => _syncQueueBox.clear();

  /// Directly injects downloaded cloud data into local storage.
  /// Bypasses the sync queue completely since data is already in the cloud.
  Future<void> restoreUserData(Map<String, dynamic> data) async {
    // We assume clearAll() was called prior if this is a new sign in.
    
    final profileData = data['profile'];
    if (profileData != null) {
      await _profileBox.put('user', profileData);
    }

    final List<dynamic> sessions = data['sessions'] ?? [];
    for (final s in sessions) {
      if (s is Map && s['id'] != null) {
        await _sessionsBox.put(s['id'], s);
      }
    }

    final List<dynamic> routines = data['routines'] ?? [];
    for (final r in routines) {
      if (r is Map && r['id'] != null) {
        await _routinesBox.put(r['id'], r);
      }
    }

    debugPrint('[StorageService] Restored profile, ${sessions.length} sessions, ${routines.length} routines.');
  }

  /// Clears all local caches. Useful when signing out or switching users.
  Future<void> clearAll() async {
    await _sessionsBox.clear();
    await _routinesBox.clear();
    await _profileBox.clear();
    await _feedBox.clear();
    await _syncQueueBox.clear();
  }
}
