import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_config.dart';
import '../models/rep_result.dart';
import '../models/form_result.dart';
import 'form_analyzer.dart';

// ── Rep Phase ─────────────────────────────────────────────────────────────────
enum RepPhase { idle, down, up }

// ── Rep Counter ───────────────────────────────────────────────────────────────
/// Handles EMA smoothing, hysteresis-based state machine, tempo tracking,
/// and per-rep quality scoring.
class RepCounter {
  RepCounter({
    required this.config,
    required this.mode,
    required this.formAnalyzer,
  });

  final ExerciseConfig config;
  WorkoutMode mode;
  final FormAnalyzer formAnalyzer;

  // ── State ──
  RepPhase _phase = RepPhase.idle;
  int _repCount = 0;
  double _repProgress = 0.0; // 0.0–1.0


  // ── EMA smoothing ──
  static const double _emaAlpha = 0.25; // smaller = smoother, higher = more responsive
  double? _smoothedLeft;
  double? _smoothedRight;

  // ── Tempo tracking ──
  int? _downStartMs;
  double _lastConcentricMs = 0;
  double _lastEccentricMs = 0;
  String _tempoFeedback = '';

  // ── Jitter tracking ──
  final List<double> _recentAngles = [];

  // ── Form tracking during rep ──
  String _currentFormNote = '';
  double _formScore = 1.0;
  double _worstFormScoreInRep = 1.0;
  String _worstFormNoteInRep = '';

  // ── Results ──
  final List<RepResult> completedReps = [];

  // ── Getters ──
  int get repCount => _repCount;
  double get repProgress => _repProgress;
  RepPhase get phase => _phase;
  String get tempoFeedback => _tempoFeedback;

  // ── Derived thresholds with mode adjustments ──
  double get _effectiveDownAngle =>
      config.downAngle - mode.thresholdBuffer;
  double get _effectiveUpAngle =>
      config.repOnLow
          ? config.upAngle + mode.thresholdBuffer
          : config.upAngle - mode.thresholdBuffer;
  double get _hysteresis => mode.hysteresisBuffer;

  // ──────────────────────────────────────────────────────────────────────────
  /// Main entry point. Call once per frame with detected landmarks.
  /// Returns true if a rep was just completed.
  bool process(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 0. Form Analysis
    final formResult = formAnalyzer.analyze(landmarks);
    _currentFormNote = formResult.message;
    _formScore = formResult.isGood ? 1.0 : (formResult.severity == FormSeverity.warning ? 0.7 : 0.4);
    
    if (_formScore < _worstFormScoreInRep) {
      _worstFormScoreInRep = _formScore;
      _worstFormNoteInRep = _currentFormNote;
    }

    // 1. Get raw angles from both sides
    final rawLeft = _rawAngle(landmarks, config.leftA, config.leftB, config.leftC);
    final rawRight = _rawAngle(landmarks, config.rightA, config.rightB, config.rightC);

    // 2. Apply EMA smoothing
    if (rawLeft != null) {
      _smoothedLeft = _ema(rawLeft, _smoothedLeft);
    }
    if (rawRight != null) {
      _smoothedRight = _ema(rawRight, _smoothedRight);
    }

    if (_smoothedLeft == null && _smoothedRight == null) return false;

    // 3. Pick the "more active" side for progress display
    final leftProgress = _calcProgress(_smoothedLeft);
    final rightProgress = _calcProgress(_smoothedRight);
    final bestProgress = math.max(leftProgress, rightProgress);
    final activeAngle = (leftProgress >= rightProgress)
        ? (_smoothedLeft ?? 180)
        : (_smoothedRight ?? 180);

    _repProgress = bestProgress;

    // Track jitter
    _recentAngles.add(activeAngle);
    if (_recentAngles.length > 8) _recentAngles.removeAt(0);

    // 4. State machine with hysteresis using activeAngle
    bool repCompleted = false;

    if (config.repOnLow) {
      switch (_phase) {
        case RepPhase.idle:
        case RepPhase.up:
          if (activeAngle >= _effectiveDownAngle - _hysteresis) {
            if (_phase != RepPhase.down) {
              _phase = RepPhase.down;
              _downStartMs = now;
            }
          }
          break;
        case RepPhase.down:
          if (activeAngle <= _effectiveUpAngle + _hysteresis) {
            _phase = RepPhase.up;
            if (_downStartMs != null) {
              _lastEccentricMs = (now - _downStartMs!).toDouble();
            }
            repCompleted = _finalizeRep(now, activeAngle);
          }
          break;
      }
    } else {
      switch (_phase) {
        case RepPhase.idle:
          if (activeAngle >= _effectiveDownAngle + _hysteresis + 10) {
            _phase = RepPhase.up;
          }
          break;
        case RepPhase.up:
          if (activeAngle <= _effectiveDownAngle - _hysteresis) {
            _phase = RepPhase.down;
            _downStartMs = now;
          }
          break;
        case RepPhase.down:
          if (activeAngle >= _effectiveUpAngle - _hysteresis) {
            if (_downStartMs != null) {
              _lastConcentricMs = (now - _downStartMs!).toDouble();
            }
            repCompleted = _finalizeRep(now, activeAngle);
            _phase = RepPhase.up;
          }
          break;
      }
    }

    return repCompleted;
  }

  bool _finalizeRep(int nowMs, double activeAngle) {
    _repCount++;

    double concentric = _lastConcentricMs;
    double eccentric = _lastEccentricMs;

    _tempoFeedback = _evalTempo(concentric, eccentric);

    final range = _calcRangeScore(activeAngle);
    final smooth = _calcSmoothnessScore();
    final tempo = _calcTempoScore(concentric, eccentric);
    final form = _worstFormScoreInRep;
    
    final quality = (range * 0.30 + smooth * 0.20 + tempo * 0.20 + form * 0.30).clamp(0.0, 1.0);

    completedReps.add(RepResult(
      repNumber: _repCount,
      qualityScore: quality,
      rangeScore: range,
      smoothnessScore: smooth,
      tempoScore: tempo,
      formScore: form,
      concentricMs: concentric,
      eccentricMs: eccentric,
      formNote: _worstFormNoteInRep,
    ));

    _worstFormScoreInRep = 1.0;
    _worstFormNoteInRep = '';

    return true;
  }

  double _calcProgress(double? angle) {
    if (angle == null) return 0.0;
    double p;
    if (config.repOnLow) {
      p = (config.downAngle - angle) / (config.downAngle - config.upAngle);
    } else {
      p = (config.upAngle - angle) / (config.upAngle - config.downAngle);
    }
    return p.clamp(0.0, 1.0);
  }

  double _ema(double raw, double? prev) {
    if (prev == null) return raw;
    return _emaAlpha * raw + (1 - _emaAlpha) * prev;
  }

  double? _rawAngle(
    Map<PoseLandmarkType, PoseLandmark> lms,
    PoseLandmarkType a,
    PoseLandmarkType b,
    PoseLandmarkType c,
  ) {
    final lmA = lms[a];
    final lmB = lms[b];
    final lmC = lms[c];
    if (lmA == null || lmB == null || lmC == null) return null;
    if (lmA.likelihood < 0.65 || lmB.likelihood < 0.65 || lmC.likelihood < 0.65) return null;

    final radians = math.atan2(lmC.y - lmB.y, lmC.x - lmB.x) -
        math.atan2(lmA.y - lmB.y, lmA.x - lmB.x);
    double angle = radians.abs() * (180 / math.pi);
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  double _calcRangeScore(double activeAngle) {
    final target = config.repOnLow ? config.upAngle : config.downAngle;
    final baseline = config.repOnLow ? config.downAngle : config.upAngle;
    final totalRange = (baseline - target).abs();
    final achieved = (activeAngle - target).abs();
    return (1.0 - (achieved / totalRange).clamp(0.0, 1.0));
  }

  double _calcSmoothnessScore() {
    if (_recentAngles.length < 3) return 0.7;
    final mean = _recentAngles.reduce((a, b) => a + b) / _recentAngles.length;
    final variance = _recentAngles
        .map((a) => (a - mean) * (a - mean))
        .reduce((a, b) => a + b) / _recentAngles.length;
    final stdDev = math.sqrt(variance);
    return (1.0 - (stdDev / 15).clamp(0.0, 1.0));
  }

  double _calcTempoScore(double concentric, double eccentric) {
    if (concentric == 0 && eccentric == 0) return 0.5;
    const idealConMin = 1500.0;
    const idealConMax = 2500.0;
    const idealEccMin = 2000.0;
    const idealEccMax = 3500.0;

    double score = 1.0;
    if (concentric > 0) {
      if (concentric < 800) score -= 0.3;
      else if (concentric < idealConMin) score -= 0.1;
      else if (concentric > idealConMax) score -= 0.1;
    }
    if (eccentric > 0) {
      if (eccentric < 800) score -= 0.3;
      else if (eccentric < idealEccMin) score -= 0.1;
      else if (eccentric > idealEccMax) score -= 0.1;
    }
    return score.clamp(0.0, 1.0);
  }

  String _evalTempo(double concentric, double eccentric) {
    if (concentric > 0 && concentric < 700) return '⚡ Too fast — control it!';
    if (eccentric > 0 && eccentric < 700) return '⚡ Too fast on the way down!';
    if (concentric > 4000) return '🐢 Slow down on the push';
    return '';
  }

  void reset() {
    _phase = RepPhase.idle;
    _repCount = 0;
    _repProgress = 0.0;
    _smoothedLeft = null;
    _smoothedRight = null;
    _recentAngles.clear();
    completedReps.clear();
    _downStartMs = null;
    _lastConcentricMs = 0;
    _lastEccentricMs = 0;
    _tempoFeedback = '';
    _worstFormScoreInRep = 1.0;
    _worstFormNoteInRep = '';
  }

  double get avgQuality {
    if (completedReps.isEmpty) return 0;
    return completedReps.map((r) => r.qualityScore).reduce((a, b) => a + b) /
        completedReps.length;
  }

  double get lastRepQuality =>
      completedReps.isEmpty ? 0 : completedReps.last.qualityScore;
}
