import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/models/workout_session.dart';
import '../../core/models/logged_exercise.dart';
import '../../core/models/exercise_set.dart';
import '../../core/providers/workout_providers.dart';

import 'models/exercise_config.dart';
import 'models/form_result.dart';
import 'services/pose_service.dart';
import 'services/rep_counter.dart';
import 'services/form_analyzer.dart';
import 'services/tts_manager.dart';
import 'services/calibration_service.dart';
import 'services/fatigue_detector.dart';
import 'widgets/skeleton_painter.dart';
import 'widgets/stat_hud.dart';
import 'widgets/calibration_overlay.dart';

// ── Pose Tracker Screen ────────────────────────────────────────────────────────
class PoseTrackerScreen extends ConsumerStatefulWidget {
  final WorkoutSession? routine;
  const PoseTrackerScreen({super.key, this.routine});

  @override
  ConsumerState<PoseTrackerScreen> createState() => _PoseTrackerScreenState();
}

class _PoseTrackerScreenState extends ConsumerState<PoseTrackerScreen>
    with WidgetsBindingObserver {

  // ── Services ──
  final PoseService _poseService = PoseService();
  late RepCounter _repCounter;
  late FormAnalyzer _formAnalyzer;
  final FatigueDetector _fatigueDetector = FatigueDetector();
  final TtsManager _tts = TtsManager();

  // ── State ──
  late ExerciseType _selectedExercise;
  int _routineExerciseIndex = 0;
  final List<LoggedExercise> _completedExercises = [];
  
  WorkoutMode _workoutMode = WorkoutMode.standard;
  bool _isStable = false;
  int _stabilityFrames = 0;
  static const int _stabilityThreshold = 8;

  // ── Calibration ──
  bool _showCalibration = true;

  // ── UI state (rebuilt via setState) ──
  int _repCount = 0;
  double _repProgress = 0.0;
  double _repQuality = 0.0;
  double _avgQuality = 0.0;
  RepPhase _phase = RepPhase.idle;
  FormResult _formResult = FormResult.perfect;
  String _tempoFeedback = '';
  String _cameraGuidance = '';
  bool _isSpeaking = false;

  // ── Session timer ──
  final DateTime _sessionStart = DateTime.now();

  // ── Stream controller to bridge ValueNotifier → Stream for CalibrationOverlay ──
  final StreamController<Pose?> _poseStreamController =
      StreamController<Pose?>.broadcast();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize first exercise
    if (widget.routine != null && widget.routine!.exercises.isNotEmpty) {
      final routineEx = widget.routine!.exercises[0];
      // Map string name to ExerciseType enum
      _selectedExercise = ExerciseType.values.firstWhere(
        (e) => e.displayName == routineEx.name,
        orElse: () => ExerciseType.bicepCurl,
      );
    } else {
      _selectedExercise = ExerciseType.bicepCurl;
    }
    
    _initServices();
  }

  Future<void> _initServices() async {
    // Init dependent services
    _formAnalyzer = FormAnalyzer(
      exerciseType: _selectedExercise,
      mode: _workoutMode,
    );
    _repCounter = RepCounter(
      config: exerciseConfigs[_selectedExercise]!,
      mode: _workoutMode,
      formAnalyzer: _formAnalyzer,
    );

    // Init TTS
    await _tts.init();

    // Init camera — needs context after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _poseService.init(context);

      // Wire pose updates
      _poseService.poseNotifier.addListener(_onPose);
      _poseService.guidanceNotifier.addListener(_onGuidanceUpdate);
    });
  }

  // ── Pose Update ──────────────────────────────────────────────────────────────
  void _onPose() {
    final pose = _poseService.poseNotifier.value;

    // Broadcast for calibration stream
    _poseStreamController.add(pose);

    if (pose == null) {
      if (_isStable) {
        setState(() {
          _isStable = false;
          _stabilityFrames = 0;
        });
      }
      return;
    }

    // ── Stability check ──
    final lms = pose.landmarks;
    final coreTypes = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
    ];
    final coreVisible = coreTypes.every((t) => (lms[t]?.likelihood ?? 0) > 0.6);

    if (coreVisible) {
      _stabilityFrames++;
      if (_stabilityFrames >= _stabilityThreshold && !_isStable) {
        setState(() => _isStable = true);
        _tts.speak('Body stable — let\'s go!', force: true);
      }
    } else {
      _stabilityFrames = 0;
      if (_isStable) setState(() => _isStable = false);
    }

    if (!_isStable || _showCalibration) return;

    // ── Form analysis ──
    final formResult = _formAnalyzer.analyze(lms);

    // ── Rep counting ──
    final repCompleted = _repCounter.process(lms);

    if (repCompleted) {
      HapticFeedback.lightImpact();
      _tts.onRepCounted(_repCounter.repCount);
      
      // Fatigue check
      final fatigueMsg = _fatigueDetector.checkFatigue(_repCounter.completedReps);
      if (fatigueMsg.isNotEmpty) {
        _tts.speak(fatigueMsg);
      }
    }

    // Phase cue
    final phaseLabel = _repCounter.phase == RepPhase.down ? 'Down' : 'Up';
    if (_repCounter.phase != _phase) {
      _tts.onPhaseChange(phaseLabel);
    }

    // Form TTS
    _tts.onFormFeedback(formResult.message, formResult.isGood);

    // Tempo TTS
    if (_repCounter.tempoFeedback.isNotEmpty) {
      _tts.onTempoFeedback(_repCounter.tempoFeedback);
    }

    // Update state
    setState(() {
      _repCount = _repCounter.repCount;
      _repProgress = _repCounter.repProgress;
      _repQuality = _repCounter.lastRepQuality;
      _avgQuality = _repCounter.avgQuality;
      _phase = _repCounter.phase;
      _formResult = formResult;
      _tempoFeedback = _repCounter.tempoFeedback;
      _isSpeaking = _tts.isSpeaking;
    });
  }

  // ── Guidance Update ──────────────────────────────────────────────────────────
  void _onGuidanceUpdate() {
    final guidance = _poseService.guidanceNotifier.value;
    if (guidance != _cameraGuidance) {
      setState(() => _cameraGuidance = guidance);
      _tts.onCameraGuidance(guidance); // voice + visual
    }
  }

  // ── Calibration callback ──────────────────────────────────────────────────────
  void _onCalibrated(Map<PoseLandmarkType, PoseLandmark> baseline) {
    // We can use the single frame as baseline or use CalibrationService if we want more frames.
    // For now, let's create a CalibrationData from the single baseline frame for simplicity
    // or better yet, since the overlay already waited, just calculate it here.
    
    final ls = baseline[PoseLandmarkType.leftShoulder];
    final rs = baseline[PoseLandmarkType.rightShoulder];
    final lh = baseline[PoseLandmarkType.leftHip];
    final rh = baseline[PoseLandmarkType.rightHip];

    final calibration = CalibrationData(
      shoulderWidth: (ls != null && rs != null) ? (rs.x - ls.x).abs() : 0.2,
      hipWidth: (lh != null && rh != null) ? (rh.x - lh.x).abs() : 0.15,
      verticalZ: (ls != null && rs != null && lh != null && rh != null) 
          ? (ls.z + rs.z + lh.z + rh.z) / 4 
          : 0,
    );

    setState(() {
      _showCalibration = false;
      _formAnalyzer = FormAnalyzer(
        exerciseType: _selectedExercise,
        mode: _workoutMode,
        calibration: calibration,
      );
      _repCounter = RepCounter(
        config: exerciseConfigs[_selectedExercise]!,
        mode: _workoutMode,
        formAnalyzer: _formAnalyzer,
      );
    });
    _tts.speak('Calibration complete. Begin your exercise!', force: true);
  }

  // ── Exercise selection ────────────────────────────────────────────────────────
  void _selectExercise(ExerciseType type) {
    setState(() {
      _selectedExercise = type;
      _repCount = 0;
      _repProgress = 0.0;
      _repQuality = 0.0;
      _avgQuality = 0.0;
      _phase = RepPhase.idle;
      _formResult = FormResult.perfect;
      _tempoFeedback = '';
      _showCalibration = true;
      _isStable = false;
      _stabilityFrames = 0;
    });

    _formAnalyzer = FormAnalyzer(
      exerciseType: type,
      mode: _workoutMode,
    );
    _repCounter = RepCounter(
      config: exerciseConfigs[type]!,
      mode: _workoutMode,
      formAnalyzer: _formAnalyzer,
    );
    _tts.resetSessionState();
  }

  // ── Workout mode change ───────────────────────────────────────────────────────
  void _changeMode(WorkoutMode mode) {
    setState(() => _workoutMode = mode);
    _repCounter.mode = mode;
    _tts.speak('Switched to ${mode.label} mode', force: true);
  }

  // ── Reset ────────────────────────────────────────────────────────────────────
  void _reset() {
    _repCounter.reset();
    _tts.resetSessionState();
    setState(() {
      _repCount = 0;
      _repProgress = 0.0;
      _repQuality = 0.0;
      _avgQuality = 0.0;
      _phase = RepPhase.idle;
      _formResult = FormResult.perfect;
      _tempoFeedback = '';
    });
  }

  // ── Save session & exit ───────────────────────────────────────────────────────
  Future<void> _saveAndExit() async {
    // Save current active exercise first
    _packageCurrentExercise();

    if (_completedExercises.isNotEmpty) {
      final totalDuration = DateTime.now().difference(_sessionStart).inSeconds;
      final sessionName = widget.routine != null 
          ? '${widget.routine!.name} (AI)' 
          : '${exerciseConfigs[_selectedExercise]!.name} (AI Session)';

      final session = WorkoutSession(
        id: const Uuid().v4(),
        date: DateTime.now(),
        name: sessionName,
        durationSeconds: totalDuration,
        exercises: List.from(_completedExercises),
      );

      await ref.read(sessionsProvider.notifier).add(session);
    }
    if (mounted) Navigator.pop(context);
  }

  void _packageCurrentExercise() {
    final reps = _repCounter.repCount;
    if (reps > 0) {
      // Build a set with the performance metrics
      final set = ExerciseSet(
        reps: reps,
        weightKg: 0,
        isBodyweight: true,
        isCompleted: true,
        // We could store quality score here if model supported it
      );

      final logged = LoggedExercise(
        name: exerciseConfigs[_selectedExercise]!.name,
        muscleGroup: _selectedExercise.muscleGroup,
        rawMuscles: [_selectedExercise.muscleGroup],
        sets: [set],
      );
      
      _completedExercises.add(logged);
    }
  }

  void _nextExercise() {
    if (widget.routine == null) return;
    
    _packageCurrentExercise();
    
    if (_routineExerciseIndex < widget.routine!.exercises.length - 1) {
      setState(() {
        _routineExerciseIndex++;
        final nextEx = widget.routine!.exercises[_routineExerciseIndex];
        _selectedExercise = ExerciseType.values.firstWhere(
          (e) => e.displayName == nextEx.name,
          orElse: () => ExerciseType.bicepCurl,
        );
        _resetStateForNewExercise();
      });
      _tts.speak('Next exercise: ${_selectedExercise.displayName}', force: true);
    } else {
      _tts.speak('Routine completed!', force: true);
      _saveAndExit();
    }
  }

  void _resetStateForNewExercise() {
    _formAnalyzer = FormAnalyzer(exerciseType: _selectedExercise);
    _repCounter = RepCounter(
      config: exerciseConfigs[_selectedExercise]!,
      mode: _workoutMode,
      formAnalyzer: _formAnalyzer,
    );
    _repCount = 0;
    _repProgress = 0.0;
    _repQuality = 0.0;
    _avgQuality = 0.0;
    _phase = RepPhase.idle;
    _formResult = FormResult.perfect;
    _showCalibration = true;
    _isStable = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Release camera hardware immediately when app goes to background
      _poseService.controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Re-acquire camera hardware without resetting workout or disposing notifiers
      if (mounted) _poseService.init(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poseService.poseNotifier.removeListener(_onPose);
    _poseService.guidanceNotifier.removeListener(_onGuidanceUpdate);
    _poseService.dispose();
    _poseStreamController.close();
    _tts.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final config = exerciseConfigs[_selectedExercise]!;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final cameraReady = _poseService.isInitialized && _poseService.controller != null;
    final cameraError = _poseService.error;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── 1. Camera Preview ───────────────────────────────────────────────
          if (cameraError != null)
            _ErrorView(error: cameraError)
          else if (!cameraReady)
            const Center(child: CircularProgressIndicator(color: AppColors.blue))
          else
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _poseService.controller!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_poseService.controller!),

                    // ── Skeleton ──
                    ValueListenableBuilder<Pose?>(
                      valueListenable: _poseService.poseNotifier,
                      builder: (context, pose, _) {
                        if (pose == null) return const SizedBox.shrink();
                        return ValueListenableBuilder<Size>(
                          valueListenable: _poseService.imageSizeNotifier,
                          builder: (_, imgSize, __) {
                            return CustomPaint(
                              painter: SkeletonPainter(
                                pose: pose,
                                imageSize: imgSize,
                                config: config,
                                isMirroring: _poseService.controller?.description.lensDirection ==
                                    CameraLensDirection.front,
                                progress: _repProgress,
                                jointColors: _formResult.jointColors,
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // ── Stability overlay ──
                    if (!_isStable && !_showCalibration)
                      const _StabilityOverlay(),


                    // ── Scanline ──
                    if (_isStable) const _ScanlineEffect(),
                  ],
                ),
              ),
            ),

          // ── 2. Top & bottom gradient vignettes ──────────────────────────────
          Positioned(top: 0, left: 0, right: 0, height: 170,
            child: _buildGradient(begin: Alignment.topCenter)),
          Positioned(bottom: 0, left: 0, right: 0, height: 300,
            child: _buildGradient(begin: Alignment.bottomCenter)),

          // ── Calibration overlay (Moved to outer stack to receive taps) ──
          if (_showCalibration && cameraReady)
            Positioned.fill(
              child: CalibrationOverlay(
                poseStream: _poseStreamController.stream,
                onCalibrated: _onCalibrated,
                onSkip: () => setState(() => _showCalibration = false),
              ),
            ),

          // ── 3. Top Bar ──────────────────────────────────────────────────────
          Positioned(
            top: topPad + 8, left: 16, right: 16,
            child: _TopBar(
              isStable: _isStable,
              isSpeaking: _isSpeaking,
              isMuted: _tts.isMuted,
              isSilent: _tts.isSilentMode,
              workoutMode: _workoutMode,
              routineName: widget.routine?.name,
              routineIndex: widget.routine != null ? _routineExerciseIndex + 1 : null,
              routineTotal: widget.routine?.exercises.length,
              onBack: _saveAndExit,
              onNext: widget.routine != null ? _nextExercise : null,
              onToggleMute: () => setState(() => _tts.toggleMute()),
              onReset: _reset,
              onModeChange: _changeMode,
            ),
          ),

          // ── 4. Exercise selector (Only shown in free-form mode) ──
          if (widget.routine == null)
            Positioned(
              top: topPad + 110, left: 0, right: 0,
              child: _ExerciseSelector(
                selected: _selectedExercise,
                onSelect: _selectExercise,
              ),
            ),

          // ── 5. Bottom HUD ────────────────────────────────────────────────────
          if (!_showCalibration)
            Positioned(
              bottom: botPad + 20, left: 16, right: 16,
              child: StatHud(
                repCount: _repCount,
                repProgress: _repProgress,
                repQuality: _repQuality,
                avgQuality: _avgQuality,
                phase: _phase,
                formFeedback: _formResult.message,
                goodForm: _formResult.isGood,
                tempoFeedback: _tempoFeedback,
                cameraGuidance: _cameraGuidance,
                workoutMode: _workoutMode,
                exerciseType: _selectedExercise,
                targetReps: (widget.routine != null && widget.routine!.exercises[_routineExerciseIndex].sets.isNotEmpty)
                    ? widget.routine!.exercises[_routineExerciseIndex].sets[0].reps
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradient({required Alignment begin}) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: begin == Alignment.topCenter ? Alignment.bottomCenter : Alignment.topCenter,
        colors: [Colors.black.withOpacity(0.85), Colors.transparent],
      ),
    ),
  );
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isStable;
  final bool isSpeaking;
  final bool isMuted;
  final bool isSilent;
  final WorkoutMode workoutMode;
  final String? routineName;
  final int? routineIndex;
  final int? routineTotal;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final VoidCallback onToggleMute;
  final VoidCallback onReset;
  final void Function(WorkoutMode) onModeChange;

  const _TopBar({
    required this.isStable,
    required this.isSpeaking,
    required this.isMuted,
    required this.isSilent,
    required this.workoutMode,
    this.routineName,
    this.routineIndex,
    this.routineTotal,
    required this.onBack,
    this.onNext,
    required this.onToggleMute,
    required this.onReset,
    required this.onModeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: Back | Title/Status | Mute | Speaking | Reset ──
        Row(
          children: [
            // Back
            _CircleBtn(icon: Icons.arrow_back_ios_rounded, onTap: onBack),
            const SizedBox(width: 10),

            // Title + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(routineName != null 
                    ? '$routineName • $routineIndex/$routineTotal'
                    : 'GYM RANK AI',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.blueLight,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isStable ? AppColors.green : Colors.orangeAccent,
                          boxShadow: isStable
                              ? [BoxShadow(color: AppColors.green.withOpacity(0.6), blurRadius: 6)]
                              : [],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isStable ? 'SYSTEM READY' : 'CALIBRATING...',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Speaking indicator
            AnimatedOpacity(
              opacity: isSpeaking ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 30, height: 30,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue.withOpacity(0.2),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 2, height: 10, color: AppColors.blue),
                      const SizedBox(width: 2),
                      Container(width: 2, height: 16, color: AppColors.blue),
                      const SizedBox(width: 2),
                      Container(width: 2, height: 8, color: AppColors.blue),
                    ],
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(duration: 400.ms,
                          begin: const Offset(1, 0.5),
                          end: const Offset(1, 1.2)),
                ),
              ),
            ),

            // Mute
            _CircleBtn(
              icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              onTap: onToggleMute,
              borderColor: isMuted ? Colors.redAccent.withOpacity(0.5) : Colors.white24,
              iconColor: isMuted ? Colors.redAccent : Colors.white,
            ),
            const SizedBox(width: 8),

            // Next (If routine)
            if (onNext != null) ...[
              const SizedBox(width: 8),
              _CircleBtn(
                icon: Icons.skip_next_rounded,
                onTap: onNext!,
                borderColor: AppColors.blue.withOpacity(0.5),
                iconColor: AppColors.blueLight,
              ),
            ],
            const SizedBox(width: 8),

            // Reset
            _CircleBtn(icon: Icons.refresh_rounded, onTap: onReset),
          ],
        ),

        const SizedBox(height: 8),

        // ── Row 2: Workout Mode Toggle ──
        _WorkoutModeToggle(
          current: workoutMode,
          onChanged: onModeChange,
        ),
      ],
    );
  }
}

// ── Workout Mode Toggle Pills ─────────────────────────────────────────────────
class _WorkoutModeToggle extends StatelessWidget {
  final WorkoutMode current;
  final void Function(WorkoutMode) onChanged;

  const _WorkoutModeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: WorkoutMode.values.map((mode) {
          final selected = mode == current;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mode.icon,
                    size: 13,
                    color: selected ? Colors.white : Colors.white54),
                  const SizedBox(width: 4),
                  Text(mode.label,
                    style: GoogleFonts.inter(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Exercise Selector ─────────────────────────────────────────────────────────
class _ExerciseSelector extends StatelessWidget {
  final ExerciseType selected;
  final void Function(ExerciseType) onSelect;

  const _ExerciseSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ExerciseType.values.map((type) {
          final cfg = exerciseConfigs[type]!;
          final isSelected = type == selected;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue.withOpacity(0.9) : Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.blue : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cfg.icon, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(cfg.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Stability Overlay ─────────────────────────────────────────────────────────
class _StabilityOverlay extends StatelessWidget {
  const _StabilityOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_rounded, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text('FINDING BODY...',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                )),
              const SizedBox(height: 8),
              Text('Step back until full body is visible',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ── Circle Button Helper ──────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color borderColor;
  final Color iconColor;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.borderColor = Colors.white24,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black45,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

// ── Scanline Effect ───────────────────────────────────────────────────────────
class _ScanlineEffect extends StatefulWidget {
  const _ScanlineEffect();
  @override
  State<_ScanlineEffect> createState() => _ScanlineEffectState();
}

class _ScanlineEffectState extends State<_ScanlineEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Positioned(
        top: MediaQuery.of(context).size.height * _ctrl.value,
        left: 0, right: 0,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              AppColors.blue.withOpacity(0.2),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    );
  }
}
