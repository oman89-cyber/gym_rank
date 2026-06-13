import 'package:hive_flutter/hive_flutter.dart';
import '../../features/pose_tracker/models/rep_result.dart';

class PersistenceService {
  static const String _workoutBoxName = 'workout_history';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_workoutBoxName);
  }

  Future<void> saveWorkout({
    required String exerciseType,
    required List<RepResult> reps,
    required double avgQuality,
    required DateTime timestamp,
  }) async {
    final box = Hive.box(_workoutBoxName);
    final workoutData = {
      'exerciseType': exerciseType,
      'reps': reps.map((r) => r.toMap()).toList(),
      'avgQuality': avgQuality,
      'timestamp': timestamp.toIso8601String(),
    };
    await box.add(workoutData);
  }

  List<dynamic> getHistory() {
    final box = Hive.box(_workoutBoxName);
    return box.values.toList();
  }
}
