import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// PoseService — owns the camera + ML Kit pipeline.
/// Exposes [poseNotifier] for UI consumption.
/// Call [init] once, [dispose] on cleanup.
class PoseService {
  // ── Config ──
  static const int _targetFps = 12; // process at ~12 fps
  static const int _frameIntervalMs = 1000 ~/ _targetFps; // ~83ms

  // ── Camera ──
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initialized = false;
  String? _error;

  // ── ML Kit ──
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  bool _isProcessing = false;
  int _lastFrameMs = 0;

  // ── Outputs ──
  final ValueNotifier<Pose?> poseNotifier = ValueNotifier(null);
  final ValueNotifier<Size> imageSizeNotifier = ValueNotifier(Size.zero);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);
  final ValueNotifier<bool> readyNotifier = ValueNotifier(false);

  // ── Body guidance ──
  final ValueNotifier<String> guidanceNotifier = ValueNotifier('');

  bool get isInitialized => _initialized;
  CameraController? get controller => _controller;
  String? get error => _error;

  // ── Removed _orientationMap as it is no longer used ──

  Future<void> init(BuildContext context) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError('No cameras found on this device.');
        return;
      }

      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final ctrl = CameraController(
        back,
        ResolutionPreset.low, // fastest for real-time ML on mobile
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await ctrl.initialize();

      if (!context.mounted) return;

      _controller = ctrl;
      _initialized = true;
      readyNotifier.value = true;

      ctrl.startImageStream((image) => _onFrame(image, context));
    } catch (e) {
      _setError('Camera error: $e');
    }
  }

  void _setError(String msg) {
    _error = msg;
    errorNotifier.value = msg;
  }

  void _onFrame(CameraImage image, BuildContext context) {
    // ── FPS limiter ──
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFrameMs < _frameIntervalMs) return;
    if (_isProcessing) return;

    _lastFrameMs = now;
    _isProcessing = true;

    final inputImage = _convertImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    // Update image size for painter
    final rotation = inputImage.metadata?.rotation;
    final isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    imageSizeNotifier.value = isRotated
        ? Size(image.height.toDouble(), image.width.toDouble())
        : Size(image.width.toDouble(), image.height.toDouble());

    _detector.processImage(inputImage).then((poses) {
      if (poses.isNotEmpty) {
        final pose = poses.first;
        poseNotifier.value = pose;
        _updateGuidance(pose, imageSizeNotifier.value);
      } else {
        poseNotifier.value = null;
        guidanceNotifier.value = 'Move into view — full body needed';
      }
    }).catchError((_) {}).whenComplete(() => _isProcessing = false);
  }

  /// Camera guidance based on body bounding box + centering
  void _updateGuidance(Pose pose, Size frameSize) {
    final lms = pose.landmarks;
    final corePoints = [
      lms[PoseLandmarkType.leftShoulder],
      lms[PoseLandmarkType.rightShoulder],
      lms[PoseLandmarkType.leftHip],
      lms[PoseLandmarkType.rightHip],
      lms[PoseLandmarkType.leftAnkle],
      lms[PoseLandmarkType.rightAnkle],
    ].whereType<PoseLandmark>().where((l) => l.likelihood > 0.5).toList();

    if (corePoints.length < 4) {
      guidanceNotifier.value = 'Full body not visible — step back';
      return;
    }

    final xs = corePoints.map((l) => l.x).toList();
    final ys = corePoints.map((l) => l.y).toList();
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);

    final bodyW = maxX - minX;
    final bodyH = maxY - minY;
    final frameArea = frameSize.width * frameSize.height;
    final bodyArea = bodyW * bodyH;
    final coverage = bodyArea / frameArea;

    if (coverage < 0.18) {
      guidanceNotifier.value = 'Move closer — body too small in frame';
      return;
    }
    if (coverage > 0.90) {
      guidanceNotifier.value = 'Move back — you\'re too close';
      return;
    }

    final bodyCenterX = (minX + maxX) / 2;
    final frameCenterX = frameSize.width / 2;
    final offsetRatio = (bodyCenterX - frameCenterX) / frameSize.width;

    if (offsetRatio < -0.20) {
      guidanceNotifier.value = 'Move right — center yourself';
      return;
    }
    if (offsetRatio > 0.20) {
      guidanceNotifier.value = 'Move left — center yourself';
      return;
    }

    guidanceNotifier.value = ''; // all good
  }

  InputImage? _convertImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      // Use a safe default for orientation if context isn't available
      // or just use the sensor's native orientation for the preview.
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // HIGH PERFORMANCE: Direct byte concatenation without List<int> overhead
    final allBytes = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      allBytes.add(plane.bytes);
    }
    final bytes = allBytes.takeBytes();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    await _detector.close();
    poseNotifier.dispose();
    imageSizeNotifier.dispose();
    errorNotifier.dispose();
    readyNotifier.dispose();
    guidanceNotifier.dispose();
  }
}
