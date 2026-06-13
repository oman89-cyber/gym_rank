import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/services/live_coach_service.dart';

class LiveCoachScreen extends ConsumerStatefulWidget {
  const LiveCoachScreen({super.key});

  @override
  ConsumerState<LiveCoachScreen> createState() => _LiveCoachScreenState();
}

class _LiveCoachScreenState extends ConsumerState<LiveCoachScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  
  bool _isLive = false;
  bool _isInitializing = true;
  final List<String> _liveLogs = [];
  final ScrollController _logScrollController = ScrollController();

  Timer? _frameTimer;
  StreamSubscription? _textSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initHardware();
    
    _textSubscription = LiveCoachService.instance.responseText.listen((text) {
      setState(() {
        _liveLogs.add(text);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initHardware() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint('[LiveCoach] Hardware Init Error: $e');
    }
  }

  Future<void> _toggleLive() async {
    if (_isLive) {
      _stopLive();
    } else {
      await _startLive();
    }
  }

  Future<void> _startLive() async {
    final profile = ref.read(profileProvider);
    final sessions = ref.read(sessionsProvider);

    await LiveCoachService.instance.connect(profile, sessions);
    
    setState(() {
      _isLive = true;
      _liveLogs.add("--- CONNECTION ESTABLISHED ---");
    });

    // Removed Timer.periodic to avoid overlaps
    _safeCaptureLoop();
  }

  Future<void> _safeCaptureLoop() async {
    while (_isLive) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          final profile = ref.read(profileProvider);
          final sessions = ref.read(sessionsProvider);
          debugPrint('[LiveCoach] Taking picture...');
          final image = await _cameraController!.takePicture();
          final bytes = await image.readAsBytes();
          debugPrint('[LiveCoach] Image size: ${bytes.length} bytes');
          LiveCoachService.instance.sendFrame(bytes, profile, sessions);
        } catch (e) {
          debugPrint('[LiveCoach] Capture loop skip: $e');
        }
      }
      // Wait at least 3 seconds between frames for absolute safety
      await Future.delayed(const Duration(milliseconds: 3000));
    }
  }

  void _stopLive() {
    _frameTimer?.cancel();
    LiveCoachService.instance.disconnect();
    setState(() {
      _isLive = false;
      _liveLogs.add("--- SESSION ENDED ---");
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isLive = false; // This will break the _safeCaptureLoop
    _cameraController?.dispose();
    _textSubscription?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),

          // HUD Overlay
          Positioned.fill(child: _buildHudOverlay()),

          // Live Logs (Bottom)
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            height: 150,
            child: _buildLiveLogArea(),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),

          // Exit Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HudPainter(isLive: _isLive),
      ),
    );
  }

  Widget _buildLiveLogArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: ListView.builder(
        controller: _logScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _liveLogs.length,
        itemBuilder: (context, index) {
          final isSystem = _liveLogs[index].startsWith('---');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _liveLogs[index],
              style: GoogleFonts.robotoMono(
                color: isSystem ? AppColors.gold : Colors.white,
                fontSize: 12,
                fontWeight: isSystem ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Center(
      child: GestureDetector(
        onTap: _toggleLive,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: _isLive ? AppColors.red.withValues(alpha: 0.8) : AppColors.blue.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (_isLive ? AppColors.red : AppColors.blue).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLive ? Icons.stop_rounded : Icons.sensors_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                _isLive ? 'END SESSION' : 'GO LIVE',
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudPainter extends CustomPainter {
  final bool isLive;
  _HudPainter({required this.isLive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isLive ? AppColors.blueLight : Colors.white).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Corner brackets
    const bracketSize = 40.0;
    const padding = 30.0;

    // Top Left
    canvas.drawPath(Path()
      ..moveTo(padding, padding + bracketSize)
      ..lineTo(padding, padding)
      ..lineTo(padding + bracketSize, padding), paint);

    // Top Right
    canvas.drawPath(Path()
      ..moveTo(size.width - padding - bracketSize, padding)
      ..lineTo(size.width - padding, padding)
      ..lineTo(size.width - padding, padding + bracketSize), paint);

    // Bottom Left
    canvas.drawPath(Path()
      ..moveTo(padding, size.height - padding - bracketSize)
      ..lineTo(padding, size.height - padding)
      ..lineTo(padding + bracketSize, size.height - padding), paint);

    // Bottom Right
    canvas.drawPath(Path()
      ..moveTo(size.width - padding - bracketSize, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding)
      ..lineTo(size.width - padding, size.height - padding - bracketSize), paint);

    if (isLive) {
      // Scanning line simulation or "Live" indicator
      final dotPaint = Paint()..color = AppColors.red..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width - padding - 15, padding + 15), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudPainter oldDelegate) => oldDelegate.isLive != isLive;
}
