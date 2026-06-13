import 'dart:async';
import 'package:flutter/foundation.dart';

/// Defines the backend operations (Firebase, REST API, etc.)
abstract class RemoteService {
  Future<void> saveProfile(Map<dynamic, dynamic> profileMap);
  Future<Map<String, dynamic>?> fetchProfile();
  Future<void> saveSession(Map<dynamic, dynamic> sessionMap);
  Future<void> deleteSession(String sessionId);
  Future<void> saveRoutine(Map<dynamic, dynamic> routineMap);
  Future<void> deleteRoutine(String routineId);
  Future<void> saveFeedPost(Map<dynamic, dynamic> postMap);
  
  Future<List<Map<dynamic, dynamic>>> fetchGlobalFeed();
  Future<List<Map<String, dynamic>>> fetchLeaderboard();
  Future<List<String>> fetchGyms();

  /// Fetches all user data (profile, sessions, routines) from the backend.
  Future<Map<String, dynamic>> fetchUserData();

  /// Search users by username prefix.
  Future<List<Map<String, dynamic>>> searchUsers(String query);

  /// Fetches profile snapshots for a list of UIDs.
  Future<List<Map<String, dynamic>>> fetchFriendProfiles(List<String> uids);

  // ── Admin Specific ────────────────────────────────────────────────
  /// Fetches a summary of global stats (Total users, etc.)
  Future<Map<String, dynamic>> fetchAdminStats();

  /// Fetches all users (limited to 500 for now) for dashboard management.
  Future<List<Map<String, dynamic>>> fetchAllUsers();

  /// Updates a user's status or role.
  Future<void> updateUserStatus(String uid, {bool? isAdmin, bool? isBanned, String? subStatus, String? managedGym, bool? isGymOwner, bool? isGymTrainer});

  /// Deletes a feed post for moderation.
  Future<void> deleteFeedPost(String postId);

  /// Fetches a collection of useful analytics for the admin panel.
  Future<Map<String, dynamic>> fetchAdminAnalytics();

  /// Fetches workout sessions for a specific user (Gym Owner/Admin only)
  Future<List<Map<String, dynamic>>> fetchUserSessionsAdmin(String uid);

  /// Fetches saved routines for a specific user (Gym Owner/Admin only)
  Future<List<Map<String, dynamic>>> fetchUserRoutinesAdmin(String uid);

  Future<void> addGym(String name);
  Future<void> deleteGym(String name);
}

/// A simulated backend that demonstrates the architecture without Firebase setup.
/// In production, swap this with `FirebaseRemoteService`.
class MockRemoteService implements RemoteService {
  
  // Simulates network latency
  Future<void> _networkDelay() => Future.delayed(const Duration(milliseconds: 600));

  @override
  Future<Map<String, dynamic>> fetchAdminStats() async {
    await _networkDelay();
    return {
      'totalUsers': 1,
      'totalSessions': 10,
      'totalVolume': 50000.0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    await _networkDelay();
    return [];
  }

  @override
  Future<void> saveProfile(Map<dynamic, dynamic> profileMap) async {
    await _networkDelay();
    debugPrint('[MockRemote] Saved Profile to backend.');
  }

  @override
  Future<void> updateUserStatus(String uid, {bool? isAdmin, bool? isBanned, String? subStatus, String? managedGym, bool? isGymOwner, bool? isGymTrainer}) async {
    await _networkDelay();
    debugPrint('[MockRemote] Updated user $uid.');
  }

  @override
  Future<void> deleteFeedPost(String postId) async {
    await _networkDelay();
    debugPrint('[MockRemote] Deleted feed post $postId.');
  }

  @override
  Future<Map<String, dynamic>> fetchAdminAnalytics() async {
    await _networkDelay();
    return {
      'newUsers': [10, 15, 8, 22, 30, 45, 50],
      'revenue': 2500.0,
      'proUsers': 120,
      'freeUsers': 880,
      'dau': 340,
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchProfile() async {
    await _networkDelay();
    return null;
  }

  @override
  Future<void> saveSession(Map<dynamic, dynamic> sessionMap) async {
    await _networkDelay();
    debugPrint('[MockRemote] Saved Session ${sessionMap['id']} to backend.');
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _networkDelay();
    debugPrint('[MockRemote] Deleted Session $sessionId from backend.');
  }

  @override
  Future<void> saveRoutine(Map<dynamic, dynamic> routineMap) async {
    await _networkDelay();
    debugPrint('[MockRemote] Saved Routine ${routineMap['id']} to backend.');
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await _networkDelay();
    debugPrint('[MockRemote] Deleted Routine $routineId from backend.');
  }

  @override
  Future<void> saveFeedPost(Map<dynamic, dynamic> postMap) async {
    await _networkDelay();
    debugPrint('[MockRemote] Saved FeedPost ${postMap['id']} to backend.');
  }

  @override
  Future<List<Map<dynamic, dynamic>>> fetchGlobalFeed() async {
    await _networkDelay();
    debugPrint('[MockRemote] Fetched global feed from backend.');
    return []; // Return empty for mock as local hive handles UI immediately
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    await _networkDelay();
    return [];
  }

  @override
  Future<List<String>> fetchGyms() async {
    await _networkDelay();
    return ['Gold\'s Gym', 'Iron Temple', 'The Forge'];
  }

  @override
  Future<Map<String, dynamic>> fetchUserData() async {
    await _networkDelay();
    debugPrint('[MockRemote] Fetched user data.');
    return {
      'profile': null,
      'sessions': [],
      'routines': [],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    await _networkDelay();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserSessionsAdmin(String uid) async {
    await _networkDelay();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserRoutinesAdmin(String uid) async {
    await _networkDelay();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFriendProfiles(List<String> uids) async {
    await _networkDelay();
    return [];
  }

  @override
  Future<void> addGym(String name) async {
    await _networkDelay();
  }

  @override
  Future<void> deleteGym(String name) async {
    await _networkDelay();
  }
}
