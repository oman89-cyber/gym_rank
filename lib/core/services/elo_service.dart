import '../models/workout_session.dart';

/// Calculates ELO-style rank score from workout history.
///
/// Formula: each session contributes points based on volume and frequency.
/// Score is capped at 999 and increases logarithmically to prevent inflation.
class EloService {
  EloService._();
  static final EloService instance = EloService._();

  /// Muscle group multipliers — compound lifts are worth more.
  static const Map<String, double> _multipliers = {
    'chest':      1.3,
    'back':       1.4,
    'quads':      1.5,
    'hamstrings': 1.3,
    'glutes':     1.2,
    'shoulders':  1.1,
    'biceps':     0.9,
    'triceps':    0.9,
    'calves':     0.7,
    'abs':        0.8,
  };

  /// Recalculates ELO from all sessions.
  /// Returns a score between 0 and 2000+.
  double calculate(List<WorkoutSession> sessions, {double baseElo = 0}) {
    double raw = 0;

    for (final session in sessions) {
      for (final ex in session.exercises) {
        final mult = _multipliers[ex.muscleGroup] ?? 1.0;
        // Each set contributes: best set volume * multiplier
        final best = ex.bestSet;
        if (best == null) continue;
        if (best.isBodyweight) {
          // Bodyweight: count reps * 0.5 per set
          raw += ex.sets.length * best.reps * 0.5;
        } else {
          raw += best.volume * mult * 0.01;
        }
      }
    }

    // Log-scale compression so early gains are fast, later gains are slower
    // Maps ~0–50000 raw → 0–2999 elo
    const double k = 5000;
    final elo = 2999 * (1 - (1 / (1 + raw / k)));
    return (elo + baseElo).clamp(0, 3000);
  }

  /// Calculates per-muscle radar scores (0–100).
  Map<String, double> radarScores(List<WorkoutSession> sessions) {
    const muscles = ['chest', 'back', 'shoulders', 'biceps', 'triceps',
                     'quads', 'hamstrings', 'glutes', 'calves', 'abs'];
    final raw = <String, double>{};

    for (final session in sessions) {
      for (final ex in session.exercises) {
        final volume = ex.bestSet?.isBodyweight == true
            ? ex.sets.length * (ex.bestSet?.reps ?? 0) * 0.5
            : ex.totalVolume * 0.01;
        raw[ex.muscleGroup] = (raw[ex.muscleGroup] ?? 0) + volume;
      }
    }

    if (raw.isEmpty) return {for (final m in muscles) m: 0};

    final maxVal = raw.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return {for (final m in muscles) m: 0};

    return {
      for (final m in muscles)
        m: ((raw[m] ?? 0) / maxVal * 100).clamp(0, 100),
    };
  }
}
