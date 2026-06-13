import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_service.dart';
import 'repository_providers.dart';

// ── Friend Profile Model ──────────────────────────────────────────────────────
class FriendProfile {
  final String uid;
  final String username;
  final double eloScore;
  final String? gym;

  const FriendProfile({
    required this.uid,
    required this.username,
    required this.eloScore,
    this.gym,
  });

  String get rank {
    if (eloScore >= 700) return 'SS';
    if (eloScore >= 500) return 'S';
    if (eloScore >= 400) return 'A';
    if (eloScore >= 300) return 'B';
    if (eloScore >= 200) return 'C';
    if (eloScore >= 100) return 'D';
    if (eloScore >= 50)  return 'E';
    return 'F';
  }

  String get initials =>
      username.isNotEmpty ? username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase() : 'GR';

  factory FriendProfile.fromMap(Map<dynamic, dynamic> map) => FriendProfile(
    uid: map['uid'] as String? ?? '',
    username: map['username'] as String? ?? 'Lifter',
    eloScore: (map['eloScore'] as num?)?.toDouble() ?? 0,
    gym: map['gym'] as String?,
  );
}

// ── User Search Result State ──────────────────────────────────────────────────
class UserSearchState {
  final List<FriendProfile> results;
  final bool isLoading;
  final String query;

  const UserSearchState({
    this.results = const [],
    this.isLoading = false,
    this.query = '',
  });

  UserSearchState copyWith({List<FriendProfile>? results, bool? isLoading, String? query}) =>
    UserSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
    );
}

// ── Friends Provider ──────────────────────────────────────────────────────────
/// Loads and caches the full profiles for the user's friend UIDs.
final friendProfilesProvider = FutureProvider.family<List<FriendProfile>, List<String>>((ref, uids) async {
  if (uids.isEmpty) return [];
  final remote = ref.read(remoteServiceProvider);
  final maps = await remote.fetchFriendProfiles(uids);
  return maps.map(FriendProfile.fromMap).toList();
});

// ── User Search Provider ──────────────────────────────────────────────────────
final userSearchProvider = StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  return UserSearchNotifier(ref.watch(remoteServiceProvider));
});

class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final RemoteService _remote;
  UserSearchNotifier(this._remote) : super(const UserSearchState());

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = const UserSearchState();
      return;
    }
    state = state.copyWith(isLoading: true, query: q);
    try {
      final maps = await _remote.searchUsers(q);
      state = state.copyWith(
        isLoading: false,
        results: maps.map(FriendProfile.fromMap).toList(),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, results: []);
    }
  }

  void clear() => state = const UserSearchState();
}
