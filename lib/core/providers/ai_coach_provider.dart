import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise_set.dart';
import '../models/logged_exercise.dart';
import '../models/workout_session.dart';
import '../services/ai_coach_service.dart';
import 'profile_provider.dart';
import 'workout_providers.dart';

// ── Wizard State Model ──────────────────────────────────────────────────────────

class AiCoachWizardState {
  final int currentStep;
  final int frequency;
  final String? split;
  final List<String> equipment;
  final String? style;
  final String customNotes;
  final String generatedProgram;
  final bool isGenerating;
  final bool routinesAdded;

  const AiCoachWizardState({
    this.currentStep = 0,
    this.frequency = 3,
    this.split,
    this.equipment = const [],
    this.style,
    this.customNotes = '',
    this.generatedProgram = '',
    this.isGenerating = false,
    this.routinesAdded = false,
  });

  AiCoachWizardState copyWith({
    int? currentStep,
    int? frequency,
    String? split,
    List<String>? equipment,
    String? style,
    String? customNotes,
    String? generatedProgram,
    bool? isGenerating,
    bool? routinesAdded,
  }) {
    return AiCoachWizardState(
      currentStep: currentStep ?? this.currentStep,
      frequency: frequency ?? this.frequency,
      split: split ?? this.split,
      equipment: equipment ?? this.equipment,
      style: style ?? this.style,
      customNotes: customNotes ?? this.customNotes,
      generatedProgram: generatedProgram ?? this.generatedProgram,
      isGenerating: isGenerating ?? this.isGenerating,
      routinesAdded: routinesAdded ?? this.routinesAdded,
    );
  }
}

// ── AI Service Provider ────────────────────────────────────────────────────────

final aiCoachServiceProvider = Provider<AiCoachService>((ref) {
  final service = AiCoachService.instance;
  
  // Listen to changes rather than watching (which would rebuild the provider)
  // This keeps the singleton instance updated without triggering downstream rebuilds
  // of any widgets or other providers watching this provider during a sync.
  ref.listen(profileProvider, (prev, next) {
    final sessions = ref.read(sessionsProvider);
    service.initialize(next, sessions);
  }, fireImmediately: true);

  ref.listen(sessionsProvider, (prev, next) {
    final profile = ref.read(profileProvider);
    service.initialize(profile, next);
  }, fireImmediately: true);

  return service;
});

// ── Wizard Notifier ─────────────────────────────────────────────────────────────

class AiCoachWizardNotifier extends StateNotifier<AiCoachWizardState> {
  final AiCoachService _service;
  final Ref _ref;

  AiCoachWizardNotifier(this._service, this._ref) : super(const AiCoachWizardState());

  void setStep(int step) => state = state.copyWith(currentStep: step);
  void setFrequency(int freq) => state = state.copyWith(frequency: freq);
  void setSplit(String split) => state = state.copyWith(split: split);
  void setStyle(String style) => state = state.copyWith(style: style);
  void setCustomNotes(String notes) => state = state.copyWith(customNotes: notes);
  
  void toggleEquipment(String item) {
    final list = [...state.equipment];
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    state = state.copyWith(equipment: list);
  }

  Future<void> generateProgram() async {
    if (state.isGenerating) return;
    
    // Ensure the service has the latest data before starting
    final profile = _ref.read(profileProvider);
    final sessions = _ref.read(sessionsProvider);
    _service.initialize(profile, sessions);

    state = state.copyWith(isGenerating: true, generatedProgram: '');

    final prompt = _buildStructuredPrompt();
    final buffer = StringBuffer();

    try {
      await for (final chunk in _service.sendMessage(prompt)) {
        buffer.write(chunk);
        state = state.copyWith(generatedProgram: buffer.toString());
      }
    } finally {
      state = state.copyWith(isGenerating: false);
      _parseAndSaveRoutines(buffer.toString());
    }
  }

  void _parseAndSaveRoutines(String fullText) {
    try {
      final jsonMatch = RegExp(r'---JSON---([\s\S]*?)---END---').firstMatch(fullText);
      if (jsonMatch == null) return;
      
      final jsonStr = jsonMatch.group(1)?.trim();
      if (jsonStr == null) return;

      final List<dynamic> days = json.decode(jsonStr);
      for (final day in days) {
        final exercises = (day['exercises'] as List).map((ex) {
          // Robust parsing helper
          int parseInt(dynamic v, int d) {
            if (v == null) return d;
            if (v is num) return v.toInt();
            if (v is String) return int.tryParse(v) ?? d;
            return d;
          }
          double parseDouble(dynamic v, double d) {
            if (v == null) return d;
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? d;
            return d;
          }

          final int setSCount = parseInt(ex['sets'], 3);
          final int reps = parseInt(ex['reps'], 10);
          final double rawWeight = parseDouble(ex['weight'], 0.0);
          
          final useKg = _ref.read(profileProvider).useKg;
          // Store internally as KG, convert from LBS if needed
          final weightKg = useKg ? rawWeight : rawWeight / 2.20462;
          
          final muscle = (ex['muscle'] as String? ?? 'chest').toLowerCase();
          final isBw = rawWeight == 0 || ex['name'].toString().toLowerCase().contains('bodyweight') || ex['name'].toString().toLowerCase().contains('push up') || ex['name'].toString().toLowerCase().contains('pull up');

          return LoggedExercise(
            name: ex['name'] as String,
            muscleGroup: muscle,
            rawMuscles: [muscle],
            sets: List.generate(
              setSCount,
              (_) => ExerciseSet(
                reps: reps, 
                weightKg: weightKg,
                isBodyweight: isBw,
              ),
            ),
          );
        }).toList();

        final session = WorkoutSession(
          id: const Uuid().v4(),
          date: DateTime.now(),
          name: '[AI] ${state.split ?? "Plan"} - ${day['name']}',
          exercises: exercises,
          durationSeconds: 0,
        );

        _ref.read(routinesProvider.notifier).save(session);
      }
      state = state.copyWith(routinesAdded: true);
    } catch (e) {
      debugPrint('Failed to parse AI routines: $e');
    }
  }

  String _buildStructuredPrompt() {
    final useKg = _ref.read(profileProvider).useKg;
    final unit = useKg ? 'KG' : 'LBS';

    return '''
Create a detailed, high-impact workout program for me based on these specific preferences:

- **Frequency:** ${state.frequency} times per week
- **Program Split:** ${state.split ?? 'Any suitable split'}
- **Equipment Available:** ${state.equipment.isEmpty ? 'Bodyweight only' : state.equipment.join(', ')}
- **Training Style:** ${state.style ?? 'Balanced'}
- **Additional Preferences/Notes:** ${state.customNotes.isEmpty ? 'None' : state.customNotes}

Please format the response as a professional-grade training plan.
Include:
1. An overview of the split.
2. A detailed breakdown of every training day in the weekly cycle.
3. Progression tips for "ranking up".

## Output Format
First, provide a beautiful Markdown training plan for me to read.
Then, at the very end of your response, you MUST provide a JSON block enclosed in `---JSON---` and `---END---` markers.
The JSON must be a list of workout days, following this exact schema:
[
  {
    "name": "Day 1: Chest & Triceps",
    "exercises": [
      {
        "name": "Bench Press", 
        "muscle": "chest",
        "sets": 3,
        "reps": 10,
        "weight": 60
      },
      {
        "name": "Tricep Pushdown", 
        "muscle": "triceps",
        "sets": 3,
        "reps": 12,
        "weight": 20
      }
    ]
  }
]
Use only these muscle groups for the "muscle" field: chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, abs.
For "weight", provide a reasonable starting weight in $unit based on my experience level. If the exercise is bodyweight, use 0.

Use Markdown formatting for a clean look.
''';
  }

  void reset() {
    state = const AiCoachWizardState();
  }
}

final aiCoachWizardProvider = StateNotifierProvider<AiCoachWizardNotifier, AiCoachWizardState>((ref) {
  final service = ref.watch(aiCoachServiceProvider);
  return AiCoachWizardNotifier(service, ref);
});

// Keep ChatMessage for legacy support if needed, or remove if fully migrating
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  const ChatMessage({required this.text, required this.isUser, this.isLoading = false});
}
