import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

/// TTSManager — smart voice coaching with milestone-only speech
/// and debounced bad-form corrections.
class TtsManager {
  final FlutterTts _tts = FlutterTts();
  bool _isMuted = false;
  bool _isSilentMode = false;

  // ── Debounce ──
  DateTime _lastSpeakTime = DateTime.now().subtract(const Duration(seconds: 5));
  static const int _debounceMs = 2000;

  // ── Form correction debounce ──
  int _consecutiveBadFormFrames = 0;
  static const int _badFormFrameThreshold = 20; // ~2 seconds at 10fps
  String _lastBadFormMsg = '';

  // ── Phase cue debounce (say "Up!" once, not every frame) ──
  String _lastPhraseSaid = '';

  bool get isMuted => _isMuted;
  bool get isSilentMode => _isSilentMode;

  // Notifier for speaking state — caller can listen
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.05);
      await _tts.setSpeechRate(0.52);
      await _tts.setVolume(1.0);
      if (Platform.isIOS) await _tts.setSharedInstance(true);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((_) => _isSpeaking = false);

      await speak('Coach online. Let\'s go!', force: true);
    } catch (e) {
      // Non-fatal
    }
  }

  // ── Core speak ──────────────────────────────────────────────────────────────
  Future<void> speak(String text, {bool force = false}) async {
    if (_isMuted || _isSilentMode) return;
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastSpeakTime).inMilliseconds < _debounceMs) return;
    _lastSpeakTime = now;
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  // ── Rep counted speech (milestones only) ─────────────────────────────────
  Future<void> onRepCounted(int repCount) async {
    if (_isMuted || _isSilentMode) return;

    // Speak rep number at milestones and key markers
    if (repCount == 1) {
      await speak('First rep!', force: true);
    } else if (repCount % 10 == 0) {
      await speak('$repCount reps — incredible!', force: true);
    } else if (repCount % 5 == 0) {
      final phrases = ['${repCount}! Keep going!', 'Nice — $repCount!', '$repCount reps. Push!'];
      await speak(phrases[repCount ~/ 5 % phrases.length], force: true);
    }
    // ALL other reps are silent — no speech clutter
  }

  // ── Phase cue (deduplicated) ───────────────────────────────────────────────
  Future<void> onPhaseChange(String cue) async {
    if (cue == _lastPhraseSaid) return; // don't repeat
    _lastPhraseSaid = cue;
    await speak(cue);
  }

  // ── Form correction (only after sustained bad form) ───────────────────────
  Future<void> onFormFeedback(String message, bool isGood) async {
    if (isGood) {
      _consecutiveBadFormFrames = 0;
      _lastBadFormMsg = '';
      return;
    }
    if (message == _lastBadFormMsg) {
      _consecutiveBadFormFrames++;
    } else {
      _consecutiveBadFormFrames = 1;
      _lastBadFormMsg = message;
    }

    // Only speak after threshold consecutive bad frames
    if (_consecutiveBadFormFrames == _badFormFrameThreshold) {
      await speak(message, force: true);
    }
  }

  // ── Tempo feedback ────────────────────────────────────────────────────────
  Future<void> onTempoFeedback(String feedback) async {
    if (feedback.isEmpty) return;
    await speak(feedback);
  }

  // ── Camera guidance ────────────────────────────────────────────────────────
  String _lastGuidance = '';
  Future<void> onCameraGuidance(String guidance) async {
    if (guidance.isEmpty || guidance == _lastGuidance) return;
    _lastGuidance = guidance;
    await speak(guidance);
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  void toggleMute() => _isMuted = !_isMuted;
  void toggleSilentMode() => _isSilentMode = !_isSilentMode;
  void setMuted(bool muted) => _isMuted = muted;

  void resetSessionState() {
    _consecutiveBadFormFrames = 0;
    _lastBadFormMsg = '';
    _lastPhraseSaid = '';
    _lastGuidance = '';
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
