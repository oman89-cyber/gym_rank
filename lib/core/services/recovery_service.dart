import '../models/workout_session.dart';

/// Computes muscle recovery percentage based on time since last training.
///
/// Recovery model:
/// - 0–24 h after training  → 0–60%
/// - 24–48 h               → 60–90%
/// - 48–72 h               → 90–100%
/// - 72 h+                 → 100% (fully recovered)
class RecoveryService {
  RecoveryService._();
  static final RecoveryService instance = RecoveryService._();

  static const List<String> allMuscles = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'quads', 'hamstrings', 'glutes', 'calves', 'abs',
  ];

  /// Returns recovery % (0–100) for each muscle group.
  Map<String, double> compute(List<WorkoutSession> sessions) {
    final now = DateTime.now();

    // Find the most recent session that trained each muscle
    final lastTrained = <String, DateTime>{};

    for (final session in sessions) {
      for (final ex in session.exercises) {
        final muscle = ex.muscleGroup;
        final existing = lastTrained[muscle];
        if (existing == null || session.date.isAfter(existing)) {
          lastTrained[muscle] = session.date;
        }
      }
    }

    return {
      for (final muscle in allMuscles)
        muscle: _recovery(now, lastTrained[muscle]),
    };
  }

  double _recovery(DateTime now, DateTime? lastDate) {
    if (lastDate == null) return 100.0; // never trained = fully ready

    final hoursAgo = now.difference(lastDate).inHours;

    if (hoursAgo >= 72) return 100.0;
    if (hoursAgo >= 48) return 90 + (hoursAgo - 48) / 24 * 10;
    if (hoursAgo >= 24) return 60 + (hoursAgo - 24) / 24 * 30;
    return (hoursAgo / 24 * 60).clamp(0, 60);
  }
}
