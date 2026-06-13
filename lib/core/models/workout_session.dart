import 'logged_exercise.dart';

/// A completed workout session.
class WorkoutSession {
  final String id;
  final DateTime date;
  final String name;
  final List<LoggedExercise> exercises;
  final int durationSeconds;

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.name,
    required this.exercises,
    required this.durationSeconds,
  });

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    String? name,
    List<LoggedExercise>? exercises,
    int? durationSeconds,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  double get totalVolume =>
      exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);

  int get totalSets =>
      exercises.fold(0, (sum, ex) => sum + ex.sets.length);

  /// Aggregates activation by muscle group (0.0–1.0).
  Map<String, double> get muscleActivation {
    final totals = <String, double>{};
    for (final ex in exercises) {
      final muscles = ex.rawMuscles.isNotEmpty ? ex.rawMuscles : [ex.muscleGroup];
      for (final m in muscles) {
        totals[m] = (totals[m] ?? 0) + ex.sets.length.toDouble();
      }
    }
    if (totals.isEmpty) return {};
    final maxSets = totals.values.reduce((a, b) => a > b ? a : b);
    return totals.map((k, v) => MapEntry(k, v / maxSets));
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'name': name,
    'exercises': exercises.map((e) => e.toMap()).toList(),
    'durationSeconds': durationSeconds,
  };

  factory WorkoutSession.fromMap(Map<dynamic, dynamic> map) => WorkoutSession(
    id: map['id'] as String,
    date: DateTime.parse(map['date'] as String),
    name: map['name'] as String,
    exercises: (map['exercises'] as List)
        .map((e) => LoggedExercise.fromMap(e as Map))
        .toList(),
    durationSeconds: (map['durationSeconds'] as num).toInt(),
  );
}
