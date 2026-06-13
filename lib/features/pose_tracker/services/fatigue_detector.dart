import '../models/rep_result.dart';

/// FatigueDetector — analyzes rep trends to detect performance decay.
class FatigueDetector {
  static const int _windowSize = 3;
  static const double _velocityThreshold = 0.7; // 30% drop in speed
  static const double _qualityThreshold = 0.8;  // 20% drop in quality

  String checkFatigue(List<RepResult> history) {
    if (history.length < _windowSize + 1) return '';

    final recent = history.sublist(history.length - _windowSize);
    final previous = history[history.length - _windowSize - 1];

    // Analyze speed (concentric velocity)
    double avgRecentConcentric = 0;
    double avgRecentQuality = 0;
    for (var rep in recent) {
      avgRecentConcentric += rep.concentricMs;
      avgRecentQuality += rep.qualityScore;
    }
    avgRecentConcentric /= _windowSize;
    avgRecentQuality /= _windowSize;

    // Detection: Speed drop
    // If concentricMs INCREASES significantly (slower movement)
    if (avgRecentConcentric > previous.concentricMs * (1 / _velocityThreshold)) {
      return 'Velocity dropping — fatigue detected. Form focus!';
    }

    // Detection: Quality drop
    if (avgRecentQuality < previous.qualityScore * _qualityThreshold) {
      return 'Quality slipping — keep your core tight!';
    }

    return '';
  }
}
