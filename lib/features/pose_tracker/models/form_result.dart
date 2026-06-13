import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ── Form Severity ─────────────────────────────────────────────────────────────
enum FormSeverity { good, warning, error }

// ── Form Result ───────────────────────────────────────────────────────────────
class FormResult {
  final String message;
  final FormSeverity severity;
  /// Per-joint override colors. Joints NOT in this map use default skeleton color.
  final Map<PoseLandmarkType, Color> jointColors;

  const FormResult({
    required this.message,
    required this.severity,
    this.jointColors = const {},
  });

  bool get isGood => severity == FormSeverity.good;

  static const FormResult perfect = FormResult(
    message: '',
    severity: FormSeverity.good,
  );
}
