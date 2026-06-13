import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/theme/app_colors.dart';

/// CalibrationOverlay — shown at session start.
/// Asks user to stand straight for 2 seconds, then fires [onCalibrated]
/// with the captured pose landmark map.
class CalibrationOverlay extends StatefulWidget {
  final Stream<Pose?> poseStream;
  final VoidCallback onSkip;
  final void Function(Map<PoseLandmarkType, PoseLandmark> baseline) onCalibrated;

  const CalibrationOverlay({
    super.key,
    required this.poseStream,
    required this.onSkip,
    required this.onCalibrated,
  });

  @override
  State<CalibrationOverlay> createState() => _CalibrationOverlayState();
}

class _CalibrationOverlayState extends State<CalibrationOverlay>
    with SingleTickerProviderStateMixin {
  static const int _targetFrames = 20; // ~2 seconds at 10fps
  int _stableFrames = 0;
  late AnimationController _progressCtrl;
  StreamSubscription<Pose?>? _sub;
  bool _calibrated = false;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _sub = widget.poseStream.listen(_onPose);
  }

  void _onPose(Pose? pose) {
    if (_calibrated) return;
    if (pose == null) {
      if (!mounted) return;
      setState(() => _stableFrames = 0);
      _progressCtrl.stop();
      _progressCtrl.reset();
      return;
    }

    // Check all core landmarks are visible
    final needed = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
    ];
    final allVisible = needed.every((t) => (pose.landmarks[t]?.likelihood ?? 0) > 0.7);

    if (!allVisible) {
      if (!mounted) return;
      setState(() => _stableFrames = 0);
      _progressCtrl.stop();
      _progressCtrl.reset();
      return;
    }

    if (!mounted) return;
    setState(() => _stableFrames++);

    if (_stableFrames == 1) {
      _progressCtrl.forward();
    }

    if (_stableFrames >= _targetFrames) {
      _calibrated = true;
      widget.onCalibrated(pose.landmarks);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.82),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blueMuted,
                      border: Border.all(color: AppColors.blue, width: 2),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppColors.blue, size: 50),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'CALIBRATING',
                    style: GoogleFonts.inter(
                      color: AppColors.blueLight,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Stand straight\nfacing the camera',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Arms relaxed at sides · Full body visible',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (_, __) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _stableFrames / _targetFrames,
                              minHeight: 8,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _stableFrames > 0 ? AppColors.blue : Colors.white24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _stableFrames == 0
                                ? 'Waiting for body...'
                                : _stableFrames >= _targetFrames
                                    ? '✓ Calibrated!'
                                    : 'Hold still...',
                            style: GoogleFonts.inter(
                              color: _stableFrames >= _targetFrames
                                  ? AppColors.green
                                  : Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  'Skip Calibration',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
