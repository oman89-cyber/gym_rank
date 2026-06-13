import 'exercise_set.dart';

/// One exercise entry in a workout session.
class LoggedExercise {
  final String name;
  final String muscleGroup; // For backward compatibility
  final List<String> rawMuscles;
  final List<ExerciseSet> sets;

  const LoggedExercise({
    required this.name,
    required this.muscleGroup,
    this.rawMuscles = const [],
    required this.sets,
  });

  double get totalVolume =>
      sets.fold(0.0, (sum, set) => sum + set.volume);

  int get totalReps =>
      sets.fold(0, (sum, set) => sum + set.reps);

  ExerciseSet? get bestSet =>
      sets.isEmpty ? null : sets.reduce(
        (a, b) => a.volume >= b.volume ? a : b,
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'muscleGroup': muscleGroup,
    'rawMuscles': rawMuscles,
    'sets': sets.map((s) => s.toMap()).toList(),
  };

  factory LoggedExercise.fromMap(Map<dynamic, dynamic> map) => LoggedExercise(
    name: map['name'] as String,
    muscleGroup: map['muscleGroup'] as String,
    rawMuscles: map['rawMuscles'] == null ? [] : (map['rawMuscles'] as List).cast<String>(),
    sets: (map['sets'] as List)
        .map((s) => ExerciseSet.fromMap(s as Map))
        .toList(),
  );
}
