import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'remote_service.dart';

/// Actual Firebase implementation of the backend.
/// Usage: swap `MockRemoteService()` with `FirebaseRemoteService()`
/// in `lib/core/providers/repository_providers.dart`.
class FirebaseRemoteService implements RemoteService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';

  @override
  Future<void> saveProfile(Map<dynamic, dynamic> profileMap) async {
    try {
      final data = Map<String, dynamic>.from(profileMap);
      
      // Data Integrity Protection: Prevent non-admins from self-elevating status via client calls.
      data.remove('isAdmin');
      data.remove('isBanned');
      data.remove('subscriptionStatus');
      data.remove('managedGym');

      if (data.containsKey('username')) {
        data['usernameLower'] = (data['username'] as String).toLowerCase();
      }
      await db.collection('users').doc(userId).set(data, SetOptions(merge: true));
      debugPrint('[FirebaseRemote] Saved Profile.');
    } catch (e) {
      debugPrint('[FirebaseRemote] Profile save failed: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final doc = await db.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null) {
        bool needsUpdate = false;
        final updates = <String, dynamic>{};

        // Backfill usernameLower if missing (needed for user search)
        if (data['username'] != null && data['usernameLower'] == null) {
          updates['usernameLower'] = (data['username'] as String).toLowerCase();
          needsUpdate = true;
        }

        // Backfill uid if missing
        if (data['uid'] == null || data['uid'] != userId) {
          updates['uid'] = userId;
          data['uid'] = userId; // update local copy for immediate use
          needsUpdate = true;
        }

        if (needsUpdate) {
          await db.collection('users').doc(userId).update(updates);
          debugPrint('[FirebaseRemote] Backfilled missing data for $userId.');
        }
      }
      return data;
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchProfile failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveSession(Map<dynamic, dynamic> sessionMap) async {
    try {
      final id = sessionMap['id'] as String;
      await db
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(id)
          .set(Map<String, dynamic>.from(sessionMap));
      debugPrint('[FirebaseRemote] Saved Session $id.');
    } catch (e) {
      debugPrint('[FirebaseRemote] Session save failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await db
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      debugPrint('[FirebaseRemote] Deleted Session $sessionId.');
    } catch (e) {
      debugPrint('[FirebaseRemote] Session delete failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveRoutine(Map<dynamic, dynamic> routineMap) async {
    try {
      final id = routineMap['id'] as String;
      await db
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(id)
          .set(Map<String, dynamic>.from(routineMap));
      debugPrint('[FirebaseRemote] Saved Routine $id.');
    } catch (e) {
      debugPrint('[FirebaseRemote] Routine save failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    try {
      await db
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .delete();
      debugPrint('[FirebaseRemote] Deleted Routine $routineId.');
    } catch (e) {
      debugPrint('[FirebaseRemote] Routine delete failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveFeedPost(Map<dynamic, dynamic> postMap) async {
    try {
      final id = postMap['id'] as String;
      // Feed posts go to a global collection
      await db.collection('feed').doc(id).set({
        ...Map<String, dynamic>.from(postMap),
        'userId': userId,
      });
      debugPrint('[FirebaseRemote] Saved FeedPost $id.');
    } catch (e) {
      debugPrint('[FirebaseRemote] FeedPost save failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<dynamic, dynamic>>> fetchGlobalFeed() async {
    try {
      final snapshot = await db
          .collection('feed')
          .orderBy('date', descending: true)
          .limit(50)
          .get();
      debugPrint('[FirebaseRemote] Fetched global feed.');
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('[FirebaseRemote] Feed fetch failed: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      debugPrint('[FirebaseRemote] Fetching leaderboard for ${db.app.options.projectId} as $userId...');
      final snapshot = await db
          .collection('users')
          .orderBy('eloScore', descending: true)
          .limit(100)
          .get();
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'userId': doc.id,
      }).toList();
    } catch (e) {
      debugPrint('[FirebaseRemote] Leaderboard fetch failed: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      debugPrint('[FirebaseRemote] Fetching all user data for $userId...');
      
      // 1. Fetch Profile
      final profileDoc = await db.collection('users').doc(userId).get();
      final profile = profileDoc.exists ? profileDoc.data() : null;

      // 2. Fetch Sessions
      final sessionsSnap = await db
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .get();
      final sessions = sessionsSnap.docs.map((d) => d.data()).toList();

      // 3. Fetch Routines
      final routinesSnap = await db
          .collection('users')
          .doc(userId)
          .collection('routines')
          .get();
      final routines = routinesSnap.docs.map((d) => d.data()).toList();

      debugPrint('[FirebaseRemote] Successfully downloaded profile, ${sessions.length} sessions, ${routines.length} routines.');

      return {
        'profile': profile,
        'sessions': sessions,
        'routines': routines,
      };
    } catch (e) {
      debugPrint('[FirebaseRemote] User data fetch failed: $e');
      return {
        'profile': null,
        'sessions': [],
        'routines': [],
      };
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserSessionsAdmin(String uid) async {
    try {
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .orderBy('date', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchUserSessionsAdmin failed: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserRoutinesAdmin(String uid) async {
    try {
      final snap = await db
          .collection('users')
          .doc(uid)
          .collection('routines')
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchUserRoutinesAdmin failed: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final lower = query.toLowerCase();
      final snapshot = await db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: lower)
          .where('usernameLower', isLessThan: '$lower\uf8ff')
          .limit(20)
          .get();
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'uid': doc.id,
      }).toList();
    } catch (e) {
      debugPrint('[FirebaseRemote] searchUsers failed: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFriendProfiles(List<String> uids) async {
    if (uids.isEmpty) return [];
    try {
      // Firestore 'whereIn' supports up to 30 items
      final batches = <List<String>>[];
      for (var i = 0; i < uids.length; i += 30) {
        batches.add(uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30));
      }
      final results = <Map<String, dynamic>>[];
      for (final batch in batches) {
        final snap = await db.collection('users').where(FieldPath.documentId, whereIn: batch).get();
        results.addAll(snap.docs.map((d) => {...d.data(), 'uid': d.id}));
      }
      return results;
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchFriendProfiles failed: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> fetchAdminStats() async {
    try {
      final usersSnap = await db.collection('users').get();
      int totalUsers = usersSnap.size;
      int totalSessions = 0;
      
      for (var doc in usersSnap.docs) {
        final data = doc.data();
        totalSessions += (data['totalSessions'] as num?)?.toInt() ?? 0;
      }

      return {
        'totalUsers': totalUsers,
        'totalSessions': totalSessions,
        'activeToday': 0, // Would need more tracking for this
      };
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchAdminStats failed: $e');
      return {
        'totalUsers': 0,
        'totalSessions': 0,
        'activeToday': 0,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> fetchAdminAnalytics() async {
    try {
      final usersSnap = await db.collection('users').get();
      final feedSnap = await db.collection('feed').get();
      
      int proCount = 0;
      int trialCount = 0;
      for (var d in usersSnap.docs) {
        final status = d.data()['subscriptionStatus'] as String?;
        if (status == 'pro') proCount++;
        if (status == 'trial') trialCount++;
      }

      return {
        'totalUsers': usersSnap.size,
        'proUsers': proCount,
        'trialUsers': trialCount,
        'totalPosts': feedSnap.size,
        'dau': 0, // Placeholder
      };
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchAdminAnalytics failed: $e');
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final snapshot = await db.collection('users').orderBy('eloScore', descending: true).limit(500).get();
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'uid': doc.id,
      }).toList();
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchAllUsers failed: $e');
      return [];
    }
  }

  @override
  Future<void> updateUserStatus(String uid, {bool? isAdmin, bool? isBanned, String? subStatus, String? managedGym, bool? isGymOwner, bool? isGymTrainer}) async {
    try {
      final updates = <String, dynamic>{};
      if (isAdmin != null) updates['isAdmin'] = isAdmin;
      if (isBanned != null) updates['isBanned'] = isBanned;
      if (subStatus != null) updates['subscriptionStatus'] = subStatus;
      
      if (managedGym != null) {
        if (managedGym.isEmpty) {
          // If clearing gym, wipe ghost privileges
          updates['managedGym'] = null;
          updates['isGymOwner'] = false;
          updates['isGymTrainer'] = false;
        } else {
          updates['managedGym'] = managedGym;
          if (isGymOwner != null) updates['isGymOwner'] = isGymOwner;
          if (isGymTrainer != null) updates['isGymTrainer'] = isGymTrainer;
        }
      } else {
        // Just updating the booleans without touching the gym string
        if (isGymOwner != null) updates['isGymOwner'] = isGymOwner;
        if (isGymTrainer != null) updates['isGymTrainer'] = isGymTrainer;
      }
      
      if (updates.isNotEmpty) {
        await db.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      debugPrint('[FirebaseRemote] updateUserStatus failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFeedPost(String postId) async {
    try {
      await db.collection('feed').doc(postId).delete();
    } catch (e) {
      debugPrint('[FirebaseRemote] deleteFeedPost failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchGyms() async {
    try {
      final snapshot = await db.collection('gyms').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('[FirebaseRemote] fetchGyms failed: $e');
      return [];
    }
  }

  @override
  Future<void> addGym(String name) async {
    try {
      await db.collection('gyms').doc(name).set({
        'name': name,
        'createdAt': FieldValue.serverTimestamp()
      });
    } catch (e) {
      debugPrint('[FirebaseRemote] addGym failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteGym(String name) async {
    try {
      await db.collection('gyms').doc(name).delete();
    } catch (e) {
      debugPrint('[FirebaseRemote] deleteGym failed: $e');
      rethrow;
    }
  }
}
