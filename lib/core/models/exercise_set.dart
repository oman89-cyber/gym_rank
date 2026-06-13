import 'package:uuid/uuid.dart';

/// A single set within an exercise (reps, weight, bodyweight flag).
class ExerciseSet {
  final String id;
  final int reps;
  final double weightKg;
  final bool isBodyweight;
  final bool isCompleted;

  ExerciseSet({
    String? id,
    required this.reps,
    required this.weightKg,
    this.isBodyweight = false,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  double get volume => isBodyweight ? 0 : reps * weightKg;

  Map<String, dynamic> toMap() => {
    'id': id,
    'reps': reps,
    'weightKg': weightKg,
    'isBodyweight': isBodyweight,
    'isCompleted': isCompleted,
  };

  factory ExerciseSet.fromMap(Map<dynamic, dynamic> map) => ExerciseSet(
    id: map['id'] as String?,
    reps: (map['reps'] as num).toInt(),
    weightKg: (map['weightKg'] as num).toDouble(),
    isBodyweight: map['isBodyweight'] as bool? ?? false,
    isCompleted: map['isCompleted'] as bool? ?? false,
  );

  ExerciseSet copyWith({
    String? id,
    int? reps,
    double? weightKg,
    bool? isBodyweight,
    bool? isCompleted,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      isBodyweight: isBodyweight ?? this.isBodyweight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
