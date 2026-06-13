import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../repositories/workout_repository.dart';
import '../services/auth_service.dart';
import '../services/elo_service.dart';
import 'repository_providers.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  final notifier = ProfileNotifier(
    ref.watch(profileRepositoryProvider),
    ref.watch(workoutRepositoryProvider),
    ref.watch(authServiceProvider),
  );
  final sub = ref.watch(authServiceProvider).onDataRestored.listen((_) {
    notifier.refresh();
  });
  ref.onDispose(() => sub.cancel());
  return notifier;
});

/// Fetches the latest user profile from the remote service.
/// Used by AuthWrapper to verify account status (e.g. isBanned).
final latestProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.read(authStateProvider).value;
  if (authState == null) return null;

  final repo = ref.read(profileRepositoryProvider);
  // Perform a mandatory remote sync to check ban status
  return await repo.syncRemoteProfile();
});

class ProfileNotifier extends StateNotifier<UserProfile> {
  final ProfileRepository _repo;
  final WorkoutRepository _workoutRepo;
  final AuthService _auth;
  ProfileNotifier(this._repo, this._workoutRepo, this._auth) : super(_repo.getProfile());

  void refresh() => state = _repo.getProfile();

  Future<void> syncFromRemote() async {
    final updated = await _repo.syncRemoteProfile();
    if (updated != null) {
      state = updated;
    }
  }

  Future<void> updateProfile(UserProfile profile) => _save(profile);

  Future<void> setUsername(String name) =>
      _save(state.copyWith(username: name));

  Future<void> toggleUnit() =>
      _save(state.copyWith(useKg: !state.useKg));

  Future<void> setWeight(double w) =>
      _save(state.copyWith(bodyWeight: w));

  Future<void> setHeight(double h) =>
      _save(state.copyWith(height: h));

  Future<void> setGoal(String g) =>
      _save(state.copyWith(goal: g));

  Future<void> updateElo(double elo) =>
      _save(state.copyWith(eloScore: elo));

  Future<void> setGym(String gymName) =>
      _save(state.copyWith(gym: gymName));

  Future<void> incrementSessions() =>
      _save(state.copyWith(
        totalSessions: state.totalSessions + 1,
      ));

  /// Forces a complete recalculation of ELO from the user's session history.
  /// Used to ensure data integrity and fix any manual 'fake' score adjustments.
  Future<void> auditEloFromHistory() async {
    final sessions = _workoutRepo.getSessions();
    final elo = EloService.instance.calculate(sessions, baseElo: state.baseElo);
    await _save(state.copyWith(eloScore: elo));
  }

  Future<void> addFriend(String uid) {
    final currentUid = _auth.currentUser?.uid;
    if (uid == currentUid) return Future.value();
    if (state.friends.contains(uid)) return Future.value();
    return _save(state.copyWith(friends: [...state.friends, uid]));
  }

  Future<void> removeFriend(String uid) =>
      _save(state.copyWith(friends: state.friends.where((f) => f != uid).toList()));

  Future<void> _save(UserProfile updated) async {
    state = updated;
    await _repo.saveProfile(updated);
  }
}
