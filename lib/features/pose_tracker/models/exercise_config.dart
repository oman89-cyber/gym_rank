import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ── Workout Mode ──────────────────────────────────────────────────────────────
enum WorkoutMode {
  beginner,  // +15° leniency, more encouragement
  standard,  // default thresholds
  strict,    // tighter thresholds, maximum feedback
}

extension WorkoutModeX on WorkoutMode {
  String get label {
    switch (this) {
      case WorkoutMode.beginner: return 'Beginner';
      case WorkoutMode.standard: return 'Standard';
      case WorkoutMode.strict:   return 'Strict';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutMode.beginner: return Icons.sentiment_satisfied_rounded;
      case WorkoutMode.standard: return Icons.sports_rounded;
      case WorkoutMode.strict:   return Icons.military_tech_rounded;
    }
  }

  /// Threshold adjustment: degrees added to downAngle and upAngle leniency
  double get thresholdBuffer {
    switch (this) {
      case WorkoutMode.beginner: return 15.0;
      case WorkoutMode.standard: return 5.0;
      case WorkoutMode.strict:   return 0.0;
    }
  }

  /// Hysteresis buffer to prevent false triggers
  double get hysteresisBuffer {
    switch (this) {
      case WorkoutMode.beginner: return 8.0;
      case WorkoutMode.standard: return 5.0;
      case WorkoutMode.strict:   return 3.0;
    }
  }
}

// ── Exercise Type ─────────────────────────────────────────────────────────────
enum ExerciseType {
  bicepCurl,
  squat,
  pushup,
  lunge,
  lateralRaise,
  jumpingJacks,
}

extension ExerciseTypeX on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.bicepCurl:    return 'Bicep Curl';
      case ExerciseType.squat:        return 'Squat';
      case ExerciseType.pushup:       return 'Push-Up';
      case ExerciseType.lunge:        return 'Lunge';
      case ExerciseType.lateralRaise: return 'Lateral Raise';
      case ExerciseType.jumpingJacks: return 'Jumping Jacks';
    }
  }

  String get muscleGroup {
    switch (this) {
      case ExerciseType.bicepCurl:    return 'Arms';
      case ExerciseType.squat:        return 'Legs';
      case ExerciseType.pushup:       return 'Chest';
      case ExerciseType.lunge:        return 'Legs';
      case ExerciseType.lateralRaise: return 'Shoulders';
      case ExerciseType.jumpingJacks: return 'Cardio';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseType.bicepCurl:    return Icons.fitness_center_rounded;
      case ExerciseType.squat:        return Icons.sports_gymnastics_rounded;
      case ExerciseType.pushup:       return Icons.accessibility_new_rounded;
      case ExerciseType.lunge:        return Icons.directions_walk_rounded;
      case ExerciseType.lateralRaise: return Icons.accessibility_rounded;
      case ExerciseType.jumpingJacks: return Icons.auto_awesome_rounded;
    }
  }
}

// ── Exercise Config ───────────────────────────────────────────────────────────
class ExerciseConfig {
  final ExerciseType type;
  final String description;

  // Landmarks defining the angle joint (symmetrical)
  final PoseLandmarkType leftA;
  final PoseLandmarkType leftB;
  final PoseLandmarkType leftC;
  final PoseLandmarkType rightA;
  final PoseLandmarkType rightB;
  final PoseLandmarkType rightC;

  /// Angle at full extension / rest (start position)
  final double downAngle;
  /// Angle at full contraction / target (end position)
  final double upAngle;
  /// true = rep counted when angle DROPS to upAngle (e.g. curl)
  /// false = rep counted when angle RISES to upAngle (e.g. squat standing up)
  final bool repOnLow;

  final String formHint;

  const ExerciseConfig({
    required this.type,
    required this.description,
    required this.leftA,
    required this.leftB,
    required this.leftC,
    required this.rightA,
    required this.rightB,
    required this.rightC,
    required this.downAngle,
    required this.upAngle,
    required this.repOnLow,
    required this.formHint,
  });

  String get name => type.displayName;
  IconData get icon => type.icon;
}

// ── Exercise Config Map ───────────────────────────────────────────────────────
const Map<ExerciseType, ExerciseConfig> exerciseConfigs = {
  ExerciseType.bicepCurl: ExerciseConfig(
    type: ExerciseType.bicepCurl,
    description: 'Curl either arm — full range, elbow pinned',
    leftA: PoseLandmarkType.leftShoulder,
    leftB: PoseLandmarkType.leftElbow,
    leftC: PoseLandmarkType.leftWrist,
    rightA: PoseLandmarkType.rightShoulder,
    rightB: PoseLandmarkType.rightElbow,
    rightC: PoseLandmarkType.rightWrist,
    downAngle: 160,
    upAngle: 40,
    repOnLow: true,
    formHint: 'Keep elbow pinned to your side!',
  ),
  ExerciseType.squat: ExerciseConfig(
    type: ExerciseType.squat,
    description: 'Squat until thighs parallel — chest up',
    leftA: PoseLandmarkType.leftHip,
    leftB: PoseLandmarkType.leftKnee,
    leftC: PoseLandmarkType.leftAnkle,
    rightA: PoseLandmarkType.rightHip,
    rightB: PoseLandmarkType.rightKnee,
    rightC: PoseLandmarkType.rightAnkle,
    downAngle: 90,
    upAngle: 160,
    repOnLow: false,
    formHint: 'Keep knees tracking over toes!',
  ),
  ExerciseType.pushup: ExerciseConfig(
    type: ExerciseType.pushup,
    description: 'Full lockout at top — body straight throughout',
    leftA: PoseLandmarkType.leftShoulder,
    leftB: PoseLandmarkType.leftElbow,
    leftC: PoseLandmarkType.leftWrist,
    rightA: PoseLandmarkType.rightShoulder,
    rightB: PoseLandmarkType.rightElbow,
    rightC: PoseLandmarkType.rightWrist,
    downAngle: 80,
    upAngle: 150,
    repOnLow: false,
    formHint: 'Keep core braced and body straight!',
  ),
  ExerciseType.lunge: ExerciseConfig(
    type: ExerciseType.lunge,
    description: 'Step forward, lower back knee, return',
    leftA: PoseLandmarkType.leftHip,
    leftB: PoseLandmarkType.leftKnee,
    leftC: PoseLandmarkType.leftAnkle,
    rightA: PoseLandmarkType.rightHip,
    rightB: PoseLandmarkType.rightKnee,
    rightC: PoseLandmarkType.rightAnkle,
    downAngle: 100,
    upAngle: 160,
    repOnLow: false,
    formHint: 'Front knee stays behind your toes!',
  ),
  ExerciseType.lateralRaise: ExerciseConfig(
    type: ExerciseType.lateralRaise,
    description: 'Raise arms to shoulder height on each side',
    leftA: PoseLandmarkType.leftHip,
    leftB: PoseLandmarkType.leftShoulder,
    leftC: PoseLandmarkType.leftWrist,
    rightA: PoseLandmarkType.rightHip,
    rightB: PoseLandmarkType.rightShoulder,
    rightC: PoseLandmarkType.rightWrist,
    downAngle: 30,
    upAngle: 85,
    repOnLow: false,
    formHint: 'Stop at shoulder height — no higher!',
  ),
  ExerciseType.jumpingJacks: ExerciseConfig(
    type: ExerciseType.jumpingJacks,
    description: 'Full arm extension overhead with each jump',
    leftA: PoseLandmarkType.leftHip,
    leftB: PoseLandmarkType.leftShoulder,
    leftC: PoseLandmarkType.leftWrist,
    rightA: PoseLandmarkType.rightHip,
    rightB: PoseLandmarkType.rightShoulder,
    rightC: PoseLandmarkType.rightWrist,
    downAngle: 45,
    upAngle: 150,
    repOnLow: false,
    formHint: 'Full arm extension — clap overhead!',
  ),
};
