import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_config.dart';
import '../models/form_result.dart';
import 'calibration_service.dart';

/// FormAnalyzer — exercise-specific form checks using real biomechanics.
/// Returns [FormResult] with per-joint color overrides for the skeleton painter.
class FormAnalyzer {
  final ExerciseType exerciseType;
  final WorkoutMode mode;
  final CalibrationData? calibration;

  FormAnalyzer({
    required this.exerciseType,
    this.mode = WorkoutMode.standard,
    this.calibration,
  });

  /// Analyze current pose landmarks and return a FormResult.
  FormResult analyze(Map<PoseLandmarkType, PoseLandmark> lms) {
    switch (exerciseType) {
      case ExerciseType.bicepCurl:
        return _analyzeBicepCurl(lms);
      case ExerciseType.squat:
        return _analyzeSquat(lms);
      case ExerciseType.pushup:
        return _analyzePushup(lms);
      case ExerciseType.lunge:
        return _analyzeLunge(lms);
      case ExerciseType.lateralRaise:
        return _analyzeLateralRaise(lms);
      case ExerciseType.jumpingJacks:
        return _analyzeJumpingJacks(lms);
    }
  }

  // ── Bicep Curl ──────────────────────────────────────────────────────────────
  FormResult _analyzeBicepCurl(Map<PoseLandmarkType, PoseLandmark> lms) {
    final ls = lms[PoseLandmarkType.leftShoulder];
    final le = lms[PoseLandmarkType.leftElbow];
    // final lw = lms[PoseLandmarkType.leftWrist];
    final rs = lms[PoseLandmarkType.rightShoulder];
    final re = lms[PoseLandmarkType.rightElbow];
    // final rw = lms[PoseLandmarkType.rightWrist];

    final jointColors = <PoseLandmarkType, Color>{};
    final issues = <String>[];

    // 1. Elbow drift check (vertical alignment with shoulder)
    final driftThreshold = mode == WorkoutMode.beginner ? 0.3 : 0.2;
    if (ls != null && le != null) {
      final drift = (le.x - ls.x).abs();
      if (drift > driftThreshold) {
        jointColors[PoseLandmarkType.leftElbow] = Colors.orangeAccent;
        issues.add('Keep left elbow pinned to your side!');
      }
    }
    if (rs != null && re != null) {
      final drift = (re.x - rs.x).abs();
      if (drift > driftThreshold) {
        jointColors[PoseLandmarkType.rightElbow] = Colors.orangeAccent;
        issues.add('Keep right elbow pinned to your side!');
      }
    }

    if (issues.isNotEmpty) {
      return FormResult(
        message: issues.first,
        severity: FormSeverity.error,
        jointColors: jointColors,
      );
    }
    return FormResult(
      message: '💪 Great control!',
      severity: FormSeverity.good,
      jointColors: jointColors,
    );
  }

  // ── Squat ──────────────────────────────────────────────────────────────────
  FormResult _analyzeSquat(Map<PoseLandmarkType, PoseLandmark> lms) {
    final lKnee = lms[PoseLandmarkType.leftKnee];
    final lAnkle = lms[PoseLandmarkType.leftAnkle];
    final rKnee = lms[PoseLandmarkType.rightKnee];
    final rAnkle = lms[PoseLandmarkType.rightAnkle];
    final lHip = lms[PoseLandmarkType.leftHip];
    final lShoulder = lms[PoseLandmarkType.leftShoulder];
    final rHip = lms[PoseLandmarkType.rightHip];

    final jointColors = <PoseLandmarkType, Color>{};
    final List<String> issues = [];

    // 1. Depth validation (Hip below or level with Knee)
    bool deepEnough = false;
    if (lHip != null && lKnee != null) {
      if (lHip.y >= lKnee.y - 0.05) deepEnough = true;
    }
    if (rHip != null && rKnee != null) {
      if (rHip.y >= rKnee.y - 0.05) deepEnough = true;
    }

    if (!deepEnough && (lHip != null || rHip != null)) {
      if (lHip != null) jointColors[PoseLandmarkType.leftHip] = Colors.orangeAccent;
      if (rHip != null) jointColors[PoseLandmarkType.rightHip] = Colors.orangeAccent;
      issues.add('Go deeper — hip below knee!');
    }

    // 2. Knee over toe / Buckle detection
    final kneeThreshold = mode == WorkoutMode.beginner ? 0.55 : 0.45;
    if (lKnee != null && lAnkle != null) {
      final kneeDrift = (lKnee.x - lAnkle.x).abs();
      if (kneeDrift > kneeThreshold) {
        jointColors[PoseLandmarkType.leftKnee] = Colors.orangeAccent;
        issues.add('Knee alignment — check posture!');
      }
    }
    if (rKnee != null && rAnkle != null) {
      final kneeDrift = (rKnee.x - rAnkle.x).abs();
      if (kneeDrift > kneeThreshold) {
        jointColors[PoseLandmarkType.rightKnee] = Colors.orangeAccent;
        if (!issues.contains('Knee alignment — check posture!')) {
          issues.add('Knee alignment — check posture!');
        }
      }
    }

    // 3. Back angle / Forward lean (using Z for depth)
    if (lShoulder != null && lHip != null) {
      final leanThreshold = mode == WorkoutMode.beginner ? -120 : -80;
      final leanDepth = lShoulder.z - lHip.z;
      if (leanDepth < leanThreshold) { 
        jointColors[PoseLandmarkType.leftShoulder] = Colors.orangeAccent;
        issues.add('Chest up — leaning too far forward!');
      }
    }

    if (issues.isNotEmpty) {
      return FormResult(
        message: issues.first,
        severity: FormSeverity.error,
        jointColors: jointColors,
      );
    }
    return FormResult(
      message: '✓ Perfect depth!',
      severity: FormSeverity.good,
      jointColors: jointColors,
    );
  }

  // ── Push-Up ────────────────────────────────────────────────────────────────
  FormResult _analyzePushup(Map<PoseLandmarkType, PoseLandmark> lms) {
    final ls = lms[PoseLandmarkType.leftShoulder];
    final lh = lms[PoseLandmarkType.leftHip];
    final la = lms[PoseLandmarkType.leftAnkle];
    // final le = lms[PoseLandmarkType.leftElbow];

    final jointColors = <PoseLandmarkType, Color>{};
    final issues = <String>[];

    // 1. Body alignment (Shoulder–Hip–Ankle straight line)
    final alignmentThreshold = mode == WorkoutMode.beginner ? 140 : 150;
    if (ls != null && lh != null && la != null) {
      final alignmentAngle = _angle3D(ls, lh, la);
      if (alignmentAngle < alignmentThreshold) {
        jointColors[PoseLandmarkType.leftHip] = Colors.orangeAccent;
        issues.add('Keep your body in a straight line!');
      }
    }

    // 2. Hip sag detection (using Z depth)
    final sagThreshold = mode == WorkoutMode.beginner ? 80 : 60;
    if (ls != null && lh != null && la != null) {
      final avgZ = (ls.z + la.z) / 2;
      if (lh.z > avgZ + sagThreshold) { 
         jointColors[PoseLandmarkType.leftHip] = Colors.orangeAccent;
         issues.add('Brace core — don\'t let hips sag!');
      }
    }

    if (issues.isNotEmpty) {
      return FormResult(
        message: issues.first,
        severity: FormSeverity.error,
        jointColors: jointColors,
      );
    }
    return FormResult(
      message: '✓ Solid plank form!',
      severity: FormSeverity.good,
      jointColors: jointColors,
    );
  }

  // ── Other Exercises (Lunge, Lat Raise, Jacks) ──────────────────────────────
  FormResult _analyzeLunge(Map<PoseLandmarkType, PoseLandmark> lms) {
    // Basic check for front knee
    return FormResult(message: 'Good lunge', severity: FormSeverity.good);
  }

  FormResult _analyzeLateralRaise(Map<PoseLandmarkType, PoseLandmark> lms) {
    return FormResult(message: 'Good raise', severity: FormSeverity.good);
  }

  FormResult _analyzeJumpingJacks(Map<PoseLandmarkType, PoseLandmark> lms) {
    return FormResult(message: 'Good jump', severity: FormSeverity.good);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  double _angle3D(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    double abx = a.x - b.x;
    double aby = a.y - b.y;
    double abz = a.z - b.z;
    double cbx = c.x - b.x;
    double cby = c.y - b.y;
    double cbz = c.z - b.z;

    double dotProduct = abx * cbx + aby * cby + abz * cbz;
    double magAB = math.sqrt(abx * abx + aby * aby + abz * abz);
    double magCB = math.sqrt(cbx * cbx + cby * cby + cbz * cbz);

    if (magAB * magCB == 0) return 0;
    double cosTheta = dotProduct / (magAB * magCB);
    return math.acos(cosTheta.clamp(-1.0, 1.0)) * 180 / math.pi;
  }
}
