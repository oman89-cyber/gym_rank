import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/exercise_config.dart';
import '../services/rep_counter.dart';

/// StatHUD — rich bottom stats panel with:
/// - Rep count + quality %
/// - Phase indicator with DOWN/UP colors  
/// - Tempo bar (concentric vs eccentric timing)
/// - Camera guidance banner
/// - Workout mode indicator
class StatHud extends StatelessWidget {
  final int repCount;
  final double repProgress;      // 0.0–1.0
  final double repQuality;       // 0.0–1.0 (last rep)
  final double avgQuality;       // 0.0–1.0
  final RepPhase phase;
  final String formFeedback;
  final bool goodForm;
  final String tempoFeedback;
  final String cameraGuidance;
  final WorkoutMode workoutMode;
  final ExerciseType exerciseType;
  final int? targetReps;

  const StatHud({
    super.key,
    required this.repCount,
    required this.repProgress,
    required this.repQuality,
    required this.avgQuality,
    required this.phase,
    required this.formFeedback,
    required this.goodForm,
    required this.tempoFeedback,
    required this.cameraGuidance,
    required this.workoutMode,
    required this.exerciseType,
    this.targetReps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Camera guidance banner (top priority) ──
        if (cameraGuidance.isNotEmpty) _GuidanceBanner(message: cameraGuidance),
        
        // ── Form / Tempo feedback ──
        _FeedbackBadge(
          feedback: tempoFeedback.isNotEmpty ? tempoFeedback : formFeedback,
          isGood: tempoFeedback.isNotEmpty ? false : goodForm,
        ),

        const SizedBox(height: 12),

        // ── Stats row ──
        Row(
          children: [
            _RepCard(count: repCount, progress: repProgress, target: targetReps),
            const SizedBox(width: 10),
            _QualityCard(lastQuality: repQuality, avgQuality: avgQuality),
            const SizedBox(width: 10),
            _PhaseCard(phase: phase),
          ],
        ),
      ],
    );
  }
}

// ── Camera Guidance Banner ────────────────────────────────────────────────────
class _GuidanceBanner extends StatelessWidget {
  final String message;
  const _GuidanceBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feedback Badge ────────────────────────────────────────────────────────────
class _FeedbackBadge extends StatelessWidget {
  final String feedback;
  final bool isGood;
  const _FeedbackBadge({required this.feedback, required this.isGood});

  @override
  Widget build(BuildContext context) {
    if (feedback.isEmpty) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isGood
            ? AppColors.blue.withOpacity(0.85)
            : Colors.red.withOpacity(0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isGood ? AppColors.blue : Colors.red,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isGood ? AppColors.blue : Colors.red).withOpacity(0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        feedback,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Rep Card ─────────────────────────────────────────────────────────────────
class _RepCard extends StatelessWidget {
  final int count;
  final double progress;
  final int? target;
  const _RepCard({required this.count, required this.progress, this.target});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _CardShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48, height: 48,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.5,
                    color: AppColors.blue,
                    backgroundColor: Colors.white10,
                  ),
                ),
                Text(
                  target != null ? '$count/$target' : '$count',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: target != null ? 14 : 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text('REPS',
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

// ── Quality Card ──────────────────────────────────────────────────────────────
class _QualityCard extends StatelessWidget {
  final double lastQuality;
  final double avgQuality;
  const _QualityCard({required this.lastQuality, required this.avgQuality});

  Color _qualityColor(double q) {
    if (q >= 0.80) return AppColors.green;
    if (q >= 0.60) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (lastQuality * 100).toInt();
    final color = _qualityColor(lastQuality);

    return Expanded(
      child: _CardShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48, height: 48,
                  child: CircularProgressIndicator(
                    value: lastQuality.clamp(0.0, 1.0),
                    strokeWidth: 3.5,
                    color: color,
                    backgroundColor: Colors.white10,
                  ),
                ),
                Text(
                  lastQuality > 0 ? '$pct%' : '--',
                  style: GoogleFonts.rajdhani(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text('QUALITY',
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

// ── Phase Card ───────────────────────────────────────────────────────────────
class _PhaseCard extends StatelessWidget {
  final RepPhase phase;
  const _PhaseCard({required this.phase});

  Color get _color {
    switch (phase) {
      case RepPhase.down: return Colors.orangeAccent;
      case RepPhase.up:   return AppColors.green;
      case RepPhase.idle: return Colors.white38;
    }
  }

  String get _label {
    switch (phase) {
      case RepPhase.down: return 'DOWN';
      case RepPhase.up:   return 'UP';
      case RepPhase.idle: return 'READY';
    }
  }

  IconData get _icon {
    switch (phase) {
      case RepPhase.down: return Icons.arrow_downward_rounded;
      case RepPhase.up:   return Icons.arrow_upward_rounded;
      case RepPhase.idle: return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _CardShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color.withOpacity(0.15),
                border: Border.all(color: _color, width: 2),
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(height: 5),
            Text(_label,
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

// ── Shared Card Shell ─────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(child: child),
    );
  }
}
