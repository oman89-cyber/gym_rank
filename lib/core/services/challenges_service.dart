import '../models/workout_session.dart';
import '../models/challenge.dart';
import '../constants/exclusive_challenges.dart';

/// A single quest the user can complete.
class Quest {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'daily' or 'weekly'
  final int target;
  final int current;
  final String unit; // 'sets', 'sessions', 'kg'

  const Quest({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.target,
    required this.current,
    required this.unit,
  });

  double get progress => (current / target).clamp(0.0, 1.0);
  bool get isComplete => current >= target;
}

/// Computes live quest progress from real session data.
class ChallengesService {
  ChallengesService._();
  static final ChallengesService instance = ChallengesService._();

  List<Quest> compute(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final todaySessions  = sessions.where((s) => s.date.isAfter(todayStart.subtract(const Duration(seconds: 1)))).toList();
    final weekSessions   = sessions.where((s) => s.date.isAfter(weekStart.subtract(const Duration(seconds: 1)))).toList();

    // ── Daily ──────────────────────────────────────────────────────────────────
    final setsToday = todaySessions.fold<int>(0, (sum, s) => sum + s.totalSets);
    final volumeToday = todaySessions.fold<double>(0, (sum, s) => sum + s.totalVolume);
    final chestSetsToday = _setsForMuscle(todaySessions, 'chest');
    final legSetsToday   = _setsForMuscle(todaySessions, 'quads') + _setsForMuscle(todaySessions, 'hamstrings');

    // ── Weekly ─────────────────────────────────────────────────────────────────
    final sessionDaysThisWeek = weekSessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .length;
    final volumeThisWeek = weekSessions.fold<double>(0, (sum, s) => sum + s.totalVolume);
    final totalSetsThisWeek = weekSessions.fold<int>(0, (sum, s) => sum + s.totalSets);

    return [
      // Daily quests
      Quest(id: 'daily_sets_15', title: 'Set Machine',  subtitle: 'Log 15 sets today', type: 'daily',  target: 15,   current: setsToday,          unit: 'sets'),
      Quest(id: 'daily_vol_200', title: 'Volume Hunter', subtitle: 'Move 200 kg today', type: 'daily',  target: 200,  current: volumeToday.toInt(), unit: 'kg'),
      Quest(id: 'daily_chest',   title: 'Chest Day',    subtitle: 'Log 5 chest sets',   type: 'daily',  target: 5,    current: chestSetsToday,      unit: 'sets'),
      Quest(id: 'daily_legs',    title: 'Leg Day',      subtitle: 'Log 6 leg sets',      type: 'daily',  target: 6,    current: legSetsToday,        unit: 'sets'),
      // Weekly quests
      Quest(id: 'week_days_4',   title: 'Consistent',  subtitle: 'Train 4 different days this week', type: 'weekly', target: 4,    current: sessionDaysThisWeek,   unit: 'days'),
      Quest(id: 'week_vol_1000', title: 'Titan',        subtitle: 'Move 1000 kg this week',          type: 'weekly', target: 1000, current: volumeThisWeek.toInt(), unit: 'kg'),
      Quest(id: 'week_sets_50',  title: 'Volume King',  subtitle: 'Log 50 sets this week',           type: 'weekly', target: 50,   current: totalSetsThisWeek,      unit: 'sets'),
      Quest(id: 'week_days_6',   title: 'No Rest Days', subtitle: 'Train 6 days this week',          type: 'weekly', target: 6,    current: sessionDaysThisWeek,    unit: 'days'),
    ];
  }

  int _setsForMuscle(List<WorkoutSession> sessions, String muscle) {
    return sessions.fold<int>(0, (sum, s) =>
        sum + s.exercises.where((ex) => ex.muscleGroup == muscle).fold<int>(0, (s2, ex) => s2 + ex.sets.length));
  }

  /// Calculates progress for joined exclusive challenges.
  Map<String, int> computeExclusiveProgress(List<WorkoutSession> sessions, List<String> joinedIds, Map<String, DateTime> joinDates) {
    final results = <String, int>{};
    
    for (final id in joinedIds) {
      final challenge = exclusiveChallenges.firstWhere((c) => c.id == id, orElse: () => exclusiveChallenges.first);
      final joinDate = joinDates[id] ?? DateTime.now();
      
      // Filter sessions since joining
      final relevantSessions = sessions.where((s) => s.date.isAfter(joinDate)).toList();
      
      int progress = 0;
      switch (challenge.goalType) {
        case ChallengeGoalType.sets:
          if (challenge.targetMuscle != null) {
            progress = _setsForMuscle(relevantSessions, challenge.targetMuscle!);
          } else {
            progress = relevantSessions.fold<int>(0, (sum, s) => sum + s.totalSets);
          }
          break;
        case ChallengeGoalType.volume:
          progress = relevantSessions.fold<double>(0, (sum, s) => sum + s.totalVolume).toInt();
          break;
        case ChallengeGoalType.sessions:
          progress = relevantSessions.length;
          break;
      }
      results[id] = progress;
    }
    
    return results;
  }

  /// Checks if a challenge has expired based on its duration string (e.g. '7d', '21d').
  bool isExpired(DateTime joinDate, String durationStr) {
    final days = int.tryParse(durationStr.replaceAll('d', '')) ?? 0;
    if (days == 0) return false;
    
    final expiryDate = joinDate.add(Duration(days: days));
    return DateTime.now().isAfter(expiryDate);
  }
}
