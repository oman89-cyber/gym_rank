import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_challenge.dart';
import '../constants/exclusive_challenges.dart';
import '../services/challenges_service.dart';
import 'repository_providers.dart';
import 'workout_providers.dart';
import 'profile_provider.dart';

/// A provider to track which Exclusive Challenges are active, their progress, and expiration.
class JoinedChallengesNotifier extends StateNotifier<Map<String, UserChallenge>> {
  final Ref _ref;
  final String _userId;

  JoinedChallengesNotifier(this._ref, this._userId) : super({}) {
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('challenges')
          .get();
      
      final Map<String, UserChallenge> loaded = {};
      for (var doc in snapshot.docs) {
        final challenge = UserChallenge.fromMap(doc.data());
        // Check for expiration on load
        final definition = exclusiveChallenges.firstWhere((c) => c.id == challenge.challengeId, orElse: () => exclusiveChallenges.first);
        final isNowExpired = ChallengesService.instance.isExpired(challenge.joinDate, definition.duration);
        
        if (isNowExpired && !challenge.isCompleted && !challenge.isExpired) {
          final expiredChallenge = challenge.copyWith(isExpired: true);
          loaded[challenge.challengeId] = expiredChallenge;
          _saveToFirestore(expiredChallenge);
        } else {
          loaded[challenge.challengeId] = challenge;
        }
      }
      state = loaded;
    } catch (e) {
      // Error loading challenges
    }
  }

  Future<void> join(String id) async {
    if (state.containsKey(id)) return;
    
    final newUserChallenge = UserChallenge(
      challengeId: id,
      joinDate: DateTime.now(),
    );
    
    state = {...state, id: newUserChallenge};
    await _saveToFirestore(newUserChallenge);
  }

  Future<void> leave(String id) async {
    if (!state.containsKey(id)) return;
    
    final newState = {...state};
    newState.remove(id);
    state = newState;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('challenges')
          .doc(id)
          .delete();
    } catch (e) {
      // Error deleting challenge
    }
  }

  /// Syncs progress for all active challenges based on the latest workout sessions.
  void syncProgress() {
    final sessions = _ref.read(sessionsProvider);
    final joinedIds = state.values.where((c) => !c.isCompleted && !c.isExpired).map((c) => c.challengeId).toList();
    final joinDates = {for (var c in state.values) c.challengeId: c.joinDate};
    
    final progressMap = ChallengesService.instance.computeExclusiveProgress(sessions, joinedIds, joinDates);
    
    bool changed = false;
    final newState = {...state};
    
    for (final id in progressMap.keys) {
      final currentProgress = progressMap[id]!;
      final challenge = newState[id]!;
      final definition = exclusiveChallenges.firstWhere((c) => c.id == id);
      
      // Check for completion
      bool isCompleted = currentProgress >= definition.goalValue;
      
      // Check for expiration
      bool isExpired = ChallengesService.instance.isExpired(challenge.joinDate, definition.duration);
      
      if (challenge.currentValue != currentProgress || challenge.isCompleted != isCompleted || challenge.isExpired != isExpired) {
        final updated = challenge.copyWith(
          currentValue: currentProgress,
          isCompleted: isCompleted,
          isExpired: isExpired,
        );
        newState[id] = updated;
        _saveToFirestore(updated);
        changed = true;
        
        // Award ELO on first completion
        if (isCompleted && !challenge.isCompleted) {
          _ref.read(profileProvider.notifier).updateElo(_ref.read(profileProvider).eloScore + definition.eloReward);
        }
      }
    }
    
    if (changed) {
      state = newState;
    }
  }

  Future<void> _saveToFirestore(UserChallenge challenge) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('challenges')
          .doc(challenge.challengeId)
          .set(challenge.toMap());
    } catch (e) {
      // Error saving challenge
    }
  }

  bool isJoined(String id) => state.containsKey(id);
  UserChallenge? getChallenge(String id) => state[id];
}

final joinedChallengesProvider = StateNotifierProvider<JoinedChallengesNotifier, Map<String, UserChallenge>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  final userId = authState?.uid ?? 'anonymous_user';
  
  final notifier = JoinedChallengesNotifier(ref, userId);
  
  // Auto-sync when sessions change
  ref.listen(sessionsProvider, (prev, next) {
    notifier.syncProgress();
  });
  
  return notifier;
});
