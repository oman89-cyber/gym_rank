import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/theme/app_colors.dart';
import '../models/exercise_config.dart';

/// Enhanced skeleton painter with:
/// - Green joints = correct form
/// - Red joints = form error  
/// - Blue glowing joints = active tracking joints
/// - Progress-driven glow intensity
class SkeletonPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final ExerciseConfig config;
  final bool isMirroring;
  final double progress;
  /// Per-joint color overrides from FormAnalyzer (green/red/orange)
  final Map<PoseLandmarkType, Color> jointColors;

  const SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.config,
    required this.isMirroring,
    this.progress = 0,
    this.jointColors = const {},
  });

  static const _connections = [
    // Arms
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow,     PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow,    PoseLandmarkType.rightWrist],
    // Torso
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftHip,       PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    // Legs
    [PoseLandmarkType.leftHip,       PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee,      PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip,      PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee,     PoseLandmarkType.rightAnkle],
  ];

  Offset _scale(PoseLandmark lm, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    double x = lm.x;
    if (isMirroring) x = imageSize.width - lm.x;
    return Offset(x * scaleX, lm.y * scaleY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final poses = pose;
    if (poses == null) return;

    final activeJoints = {
      config.leftA,  config.leftB,  config.leftC,
      config.rightA, config.rightB, config.rightC,
    };

    final defaultLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final activeLinePaint = Paint()
      ..color = AppColors.blue.withOpacity(0.85)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final errorLinePaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // ── Draw connections ──
    for (final conn in _connections) {
      final lmA = poses.landmarks[conn[0]];
      final lmB = poses.landmarks[conn[1]];
      if (lmA == null || lmB == null) continue;
      if (lmA.likelihood < 0.4 || lmB.likelihood < 0.4) continue;

      final isActive = activeJoints.contains(conn[0]) && activeJoints.contains(conn[1]);
      final aColor = jointColors[conn[0]];
      final bColor = jointColors[conn[1]];
      final hasError = aColor == Colors.redAccent || bColor == Colors.redAccent;

      Paint linePaint;
      if (isActive && hasError) {
        linePaint = errorLinePaint;
      } else if (isActive) {
        linePaint = activeLinePaint;
      } else {
        linePaint = defaultLinePaint;
      }

      canvas.drawLine(_scale(lmA, size), _scale(lmB, size), linePaint);
    }

    // ── Draw landmark dots ──
    for (final entry in poses.landmarks.entries) {
      final lmType = entry.key;
      final lm = entry.value;

      if (_isFaceOrDetail(lmType)) continue;
      if (lm.likelihood < 0.4) continue;

      final pt = _scale(lm, size);
      final isActive = activeJoints.contains(lmType);
      final overrideColor = jointColors[lmType];

      final Color dotColor;
      final double radius;

      if (overrideColor != null) {
        dotColor = overrideColor;
        radius = isActive ? 8.0 : 5.0;
      } else if (isActive) {
        dotColor = Colors.greenAccent; // Green for correct active joints
        radius = 7.0 + (progress * 4.0);
      } else {
        dotColor = Colors.white.withOpacity(0.8);
        radius = 4.5;
      }

      // Glow for active or error joints
      if (isActive || overrideColor != null) {
        final glowColor = overrideColor ?? AppColors.blue;
        final glowAlpha = overrideColor != null ? 0.4 : (0.3 * progress);
        canvas.drawCircle(
          pt, radius + 5,
          Paint()
            ..color = glowColor.withOpacity(glowAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      canvas.drawCircle(pt, radius, Paint()..color = dotColor..style = PaintingStyle.fill);
      canvas.drawCircle(pt, radius,
          Paint()
            ..color = Colors.black.withOpacity(0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  bool _isFaceOrDetail(PoseLandmarkType t) =>
    t == PoseLandmarkType.nose ||
    t == PoseLandmarkType.leftEyeInner || t == PoseLandmarkType.leftEye ||
    t == PoseLandmarkType.leftEyeOuter || t == PoseLandmarkType.rightEyeInner ||
    t == PoseLandmarkType.rightEye || t == PoseLandmarkType.rightEyeOuter ||
    t == PoseLandmarkType.leftEar || t == PoseLandmarkType.rightEar ||
    t == PoseLandmarkType.leftMouth || t == PoseLandmarkType.rightMouth ||
    t == PoseLandmarkType.leftPinky || t == PoseLandmarkType.rightPinky ||
    t == PoseLandmarkType.leftIndex || t == PoseLandmarkType.rightIndex ||
    t == PoseLandmarkType.leftThumb || t == PoseLandmarkType.rightThumb ||
    t == PoseLandmarkType.leftHeel || t == PoseLandmarkType.rightHeel ||
    t == PoseLandmarkType.leftFootIndex || t == PoseLandmarkType.rightFootIndex;

  @override
  bool shouldRepaint(SkeletonPainter old) =>
      old.pose != pose ||
      old.progress != progress ||
      old.jointColors != jointColors;
}
