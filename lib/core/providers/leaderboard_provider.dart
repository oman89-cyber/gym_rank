import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../constants/mock_data.dart'; // For LeaderboardUser

final leaderboardProvider = FutureProvider<List<LeaderboardUser>>((ref) async {
  final remote = ref.read(remoteServiceProvider);
  final data = await remote.fetchLeaderboard();
  debugPrint('[leaderboardProvider] Fetched ${data.length} records.');
  
  if (data.isEmpty) return [];

  return data.asMap().entries.map((e) {
    final doc = e.value;
    final id = doc['userId'] as String? ?? '';
    final name = doc['username'] as String? ?? doc['displayName'] as String? ?? 'Lifter';
    final elo = (doc['eloScore'] as num?)?.toDouble() ?? 100.0;
    final gym = doc['gym'] as String? ?? 'Global';
    
    // Quick local recalculation so we don't have to duplicate logic
    String getRank(double score) {
      if (score >= 700) return 'SS';
      if (score >= 500) return 'S';
      if (score >= 400) return 'A';
      if (score >= 300) return 'B';
      if (score >= 200) return 'C';
      if (score >= 100) return 'D';
      if (score >= 50)  return 'E';
      return 'F';
    }

    return LeaderboardUser(
      position: e.key + 1,
      userId: id,
      name: name,
      score: elo,
      rank: getRank(elo),
      gym: gym,
      avatarInitials: name.isNotEmpty ? name[0].toUpperCase() : 'G',
    );
  }).toList();
});
