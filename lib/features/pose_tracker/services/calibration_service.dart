import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/calibration_data.dart';

export '../models/calibration_data.dart';

class CalibrationService {
  bool isCalibrating = false;
  int _calibrationFrames = 0;
  final List<Map<PoseLandmarkType, PoseLandmark>> _capturedPoses = [];
  
  CalibrationData? _data;
  CalibrationData? get data => _data;

  void startCalibration() {
    isCalibrating = true;
    _calibrationFrames = 0;
    _capturedPoses.clear();
  }

  /// Process frame during calibration. Returns true if calibration is complete.
  bool processFrame(Map<PoseLandmarkType, PoseLandmark> lms) {
    if (!isCalibrating) return false;

    _capturedPoses.add(lms);
    _calibrationFrames++;

    // Assume 10-15 FPS, so 20-30 frames for 2 seconds
    if (_calibrationFrames >= 25) {
      _finalizeCalibration();
      isCalibrating = false;
      return true;
    }
    return false;
  }

  void _finalizeCalibration() {
    if (_capturedPoses.isEmpty) return;

    double sumShoulderWidth = 0;
    double sumHipWidth = 0;
    double sumZ = 0;

    for (final pose in _capturedPoses) {
      final ls = pose[PoseLandmarkType.leftShoulder];
      final rs = pose[PoseLandmarkType.rightShoulder];
      final lh = pose[PoseLandmarkType.leftHip];
      final rh = pose[PoseLandmarkType.rightHip];

      if (ls != null && rs != null) {
        sumShoulderWidth += (rs.x - ls.x).abs();
      }
      if (lh != null && rh != null) {
        sumHipWidth += (rh.x - lh.x).abs();
      }
      if (lh != null && rh != null && ls != null && rs != null) {
        sumZ += (lh.z + rh.z + ls.z + rs.z) / 4;
      }
    }

    _data = CalibrationData(
      shoulderWidth: sumShoulderWidth / _capturedPoses.length,
      hipWidth: sumHipWidth / _capturedPoses.length,
      verticalZ: sumZ / _capturedPoses.length,
    );
  }
}
