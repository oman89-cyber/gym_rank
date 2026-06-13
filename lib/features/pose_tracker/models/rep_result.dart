// ── Rep Phase State ───────────────────────────────────────────────────────────
enum RepPhase { idle, down, up }

// ── Rep Result (per-rep quality score) ───────────────────────────────────────
class RepResult {
  final int repNumber;
  final double qualityScore;    // 0.0–1.0
  final double rangeScore;      // how close angle reached ideal target
  final double smoothnessScore; // low jitter = high score
  final double tempoScore;      // consistency with ideal 2s/3s timings
  final double formScore;       // real-time form checks (0.0–1.0)
  final double concentricMs;    // milliseconds for concentric (up) phase
  final double eccentricMs;     // milliseconds for eccentric (down) phase
  final String formNote;        // best form feedback captured during rep

  const RepResult({
    required this.repNumber,
    required this.qualityScore,
    required this.rangeScore,
    required this.smoothnessScore,
    required this.tempoScore,
    required this.formScore,
    required this.concentricMs,
    required this.eccentricMs,
    required this.formNote,
  });

  /// Grade label based on score
  String get grade {
    if (qualityScore >= 0.85) return '★ Excellent';
    if (qualityScore >= 0.70) return '✓ Good';
    if (qualityScore >= 0.55) return '~ Fair';
    return '⚠ Needs Work';
  }

  /// Colour hint for UI (green → yellow → red)
  double get colorT => qualityScore; // 0=red, 1=green (lerp in UI)

  Map<String, dynamic> toMap() => {
    'repNumber': repNumber,
    'qualityScore': qualityScore,
    'formScore': formScore,
    'concentricMs': concentricMs,
    'eccentricMs': eccentricMs,
    'formNote': formNote,
  };
}
