import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'repository_providers.dart';

/// Fetches general statistics for the admin dashboard.
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final remote = ref.read(remoteServiceProvider);
  return remote.fetchAdminStats();
});

/// Fetched all users registered in the system.
final allUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final remote = ref.read(remoteServiceProvider);
  final maps = await remote.fetchAllUsers();
  return maps.map((m) => UserProfile.fromMap(m)).toList();
});

/// Provider for searching users within the admin panel.
final adminSearchProvider = StateProvider<String>((ref) => '');

/// Filtered users based on search query (Name, Email, or UID).
final filteredUsersProvider = Provider<AsyncValue<List<UserProfile>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final query = ref.watch(adminSearchProvider).trim().toLowerCase();

  return usersAsync.when(
    data: (users) {
      if (query.isEmpty) return AsyncValue.data(users);
      final filtered = users.where((u) {
        final nameMatch = u.username.toLowerCase().contains(query);
        final emailMatch = u.email?.toLowerCase().contains(query) ?? false;
        final idMatch = u.uid?.toLowerCase().contains(query) ?? false;
        return nameMatch || emailMatch || idMatch;
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});


/// Detailed analytics for the admin dashboard.
final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final remote = ref.read(remoteServiceProvider);
  return remote.fetchAdminAnalytics();
});

/// Fetches active trainers employed at a specific gym.
final gymTrainersProvider = FutureProvider.family<List<UserProfile>, String>((ref, gymName) async {
  final allUsersAsync = ref.watch(allUsersProvider);
  return allUsersAsync.when(
    data: (users) => users.where((u) => u.managedGym == gymName && u.isGymTrainer).toList(),
    loading: () => [],
    error: (e, st) => [],
  );
});

/// Fetches users for a specific gym (Owner View).
final gymUsersProvider = FutureProvider.family<List<UserProfile>, String>((ref, gymName) async {
  final allUsersAsync = ref.watch(allUsersProvider);
  return allUsersAsync.when(
    data: (users) => users.where((u) => u.gym == gymName).toList(),
    loading: () => [],
    error: (e, st) => [],
  );
});

/// Computes simplified stats for a specific gym.
final gymStatsProvider = Provider.family<AsyncValue<Map<String, dynamic>>, String>((ref, gymName) {
  final usersAsync = ref.watch(gymUsersProvider(gymName));
  return usersAsync.when(
    data: (users) {
      final proCount = users.where((u) => u.subscriptionStatus != 'free').length;
      final avgElo = users.isEmpty ? 0.0 : users.map((u) => u.eloScore).reduce((a, b) => a + b) / users.length;
      return AsyncValue.data({
        'totalMembers': users.length,
        'proMembers': proCount,
        'averageElo': avgElo,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Fetches the workout session history for a specific member profile.
final memberSessionsProvider = FutureProvider.family<List<dynamic>, String>((ref, uid) async {
  final remote = ref.read(remoteServiceProvider);
  final sessionMaps = await remote.fetchUserSessionsAdmin(uid);
  return sessionMaps;
});

/// Fetches the routine templates for a specific member profile.
final memberRoutinesProvider = FutureProvider.family<List<dynamic>, String>((ref, uid) async {
  final remote = ref.read(remoteServiceProvider);
  return remote.fetchUserRoutinesAdmin(uid);
});

