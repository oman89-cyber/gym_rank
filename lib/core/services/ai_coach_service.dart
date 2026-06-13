import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';

// ─── PASTE YOUR GEMINI API KEY HERE ───────────────────────────────────────────
// WARNING: Do not commit this key to version control in a production app.
const String _kApiKey = 'AIzaSyAqh6Peqn_DcaD74F_Et3LJrRczZ1A9G78';
// ──────────────────────────────────────────────────────────────────────────────

class AiCoachService {
  AiCoachService._();
  static final AiCoachService instance = AiCoachService._();

  late String _systemPrompt;
  late GenerativeModel _model;
  ChatSession? _session;

  bool get isConfigured => _kApiKey != 'YOUR_GEMINI_API_KEY';

  /// Call this once when the user's profile + sessions are known.
  void initialize(UserProfile profile, List<WorkoutSession> recentSessions) {
    final nextPrompt = _buildSystemPrompt(profile, recentSessions);

    // Skip re-initialization if the prompt hasn't changed meaningfully
    if (_session != null && _systemPrompt == nextPrompt) {
      debugPrint('[AiCoach] Skipping re-initialization, prompt identical.');
      return;
    }

    _systemPrompt = nextPrompt;
    _model = GenerativeModel(
      model: 'models/gemma-4-31b-it',
      apiKey: _kApiKey,
    );
    // Inject the system prompt as the first user/model exchange in history.
    _session = _model.startChat(history: [
      Content.text(_systemPrompt),
      Content.model([
        TextPart(
            'Understood! I am GymAI, your personal fitness and nutrition coach. How can I help you today?')
      ]),
    ]);
    debugPrint(
        '[AiCoach] Initialized/Updated with profile: ${profile.username} (${profile.rankLabel})');
  }

  /// Send a user message and get the response as a stream.
  Stream<String> sendMessage(String text) async* {
    if (_session == null) {
      yield "Please initialize the AI Coach first by opening this screen after signing in.";
      return;
    }
    if (!isConfigured) {
      yield "⚠️ API key not set. Open `lib/core/services/ai_coach_service.dart` and paste your Gemini API key in `_kApiKey`.";
      return;
    }

    bool hasContent = false;
    try {
      final response = _session!.sendMessageStream(Content.text(text));
      await for (final chunk in response) {
        String? chunkText = chunk.text;
        if (chunkText != null && chunkText.isNotEmpty) {
          // Strip internal thinking tags if they leak through
          chunkText = _filterThoughts(chunkText);
          if (chunkText.isEmpty) continue;
          
          hasContent = true;
          yield chunkText;
        }
      }
    } catch (e) {
      debugPrint('[AiCoach] Error: $e');
      // Only show the error if absolutely nothing was received.
      if (!hasContent) {
        yield "Sorry, I couldn't connect right now. Check your API key and internet connection.\n(Error: $e)";
      }
    }
  }

  /// Analyze a food image and return nutrient estimates.
  Stream<String> analyzeFoodImage(Uint8List imageBytes) async* {
    if (!isConfigured) {
      yield "⚠️ API key not set.";
      return;
    }

    final prompt = TextPart('''
Analyze this food image. Provide ONLY:
1. A 1-sentence description.
2. A simple Markdown table with Calories, Protein, Carbs, Fats.
NO intro, NO outro, no internal reasoning. Keep it ultra-short.
''');

    try {
      final content = [
        Content.multi([
          prompt,
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = _model.generateContentStream(content);
      await for (final chunk in response) {
        if (chunk.text != null) {
          final filtered = _filterThoughts(chunk.text!);
          if (filtered.isNotEmpty) yield filtered;
        }
      }
    } catch (e) {
      yield "Failed to analyze image: $e";
    }
  }

  /// Removes <thought>...</thought> blocks or similar internal reasoning tags.
  /// Also handles unclosed tags during streaming.
  String _filterThoughts(String text) {
    return text
        .replaceAll(RegExp(r'<thought>.*?</thought>', dotAll: true), '')
        .replaceAll(RegExp(r'<thought>.*$', dotAll: true), '') 
        .replaceAll(RegExp(r'\[THOUGHT\].*?\[/THOUGHT\]', dotAll: true, caseSensitive: false), '')
        .replaceAll(RegExp(r'\[THOUGHT\].*$', dotAll: true, caseSensitive: false), '')
        .replaceAll(RegExp(r'Thinking:.*$', dotAll: true, caseSensitive: false), '')
        .replaceAll(RegExp(r'Thought:.*$', dotAll: true, caseSensitive: false), '')
        .trim();
  }

  String _buildSystemPrompt(
      UserProfile profile, List<WorkoutSession> sessions) {
    final sessionSummary = sessions.isEmpty
        ? 'No sessions logged yet.'
        : sessions.take(5).map((s) {
            final vol = s.totalVolume.toStringAsFixed(0);
            final duration = (s.durationSeconds / 60).round();
            return '- ${s.name}: ${s.totalSets} sets, $vol kg total volume, $duration min';
          }).join('\n');

    final weightStr = profile.bodyWeight != null
        ? '${profile.bodyWeight!.toStringAsFixed(1)} ${profile.useKg ? "kg" : "lbs"}'
        : 'unknown';
    final heightStr = profile.height != null
        ? '${profile.height!.toStringAsFixed(0)} cm'
        : 'unknown';
    final goal = profile.goal ?? 'general fitness';

    return '''
### CRITICAL INSTRUCTION: NO THINKING DISCLOSURE
- NEVER output your internal reasoning, "thought" tags, "THINKING:" blocks, or meta-comments about your process.
- Start your response IMMEDIATELY with the coaching advice.
- Failure to hide your internal monologue will result in a system error.

You are GymAI, an elite personal fitness and nutrition coach inside the Gym Rank app. You have deep expertise in strength training, hypertrophy, fat loss, sports nutrition, and recovery — like a world-class coach and registered dietitian combined.

## Your Athlete's Profile
- **Name:** ${profile.username}
- **Rank:** ${profile.rankLabel} (ELO: ${profile.eloScore.toStringAsFixed(0)})
- **Total Sessions:** ${profile.totalSessions}
- **Body Weight:** $weightStr
- **Height:** $heightStr
- **Primary Goal:** $goal

## Recent Workout History (last 5)
$sessionSummary

## Your Areas of Expertise
1. **Training** – workout splits, progressive overload, exercise selection, form tips, deload weeks.
2. **Nutrition & Diet** – meal plans, macro targets (protein/carbs/fats), calorie estimates based on the athlete's weight and goal, meal timing, pre/post workout nutrition, supplement basics (creatine, protein powder, etc.).
3. **Recovery** – sleep, active recovery, stretching, mobility work.
4. **Rank Progression** – how to increase ELO faster, consistency strategies, weekly session planning.

## Your Coaching Style
- **ULTRA-CONCISE**: Your maximum response length is 2–3 sentences. Never waffle.
- **NO THINKING**: Never output your internal reasoning, "thought" tags, or "THINKING:" blocks. Start directly with the coaching advice.
- When providing a diet or macro plan, **calculate based on the athlete's body weight ($weightStr) and goal ($goal)** using standard formulas (e.g., 1.6–2.2g protein per kg of bodyweight for muscle gain).
- Reference the athlete's rank, ELO, and recent sessions when giving training advice.
- Use motivational language that fits the RPG/gamified theme of the app — frame improvements as "leveling up" or "ranking up".
- Call the athlete by their name: "${profile.username}".
- Format multi-step advice with numbered lists or bullet points (but still keep it short).
- Never give medical advice. For injuries or health conditions, always refer to a doctor.

## Strict Topic Boundary
You ONLY answer questions related to: gym training, fitness, body composition, sports nutrition, diet plans, macros, supplements, recovery, and workout motivation.
If the user asks about anything unrelated to fitness or nutrition (e.g., coding, politics, general knowledge), politely decline and redirect:
"I'm only trained to coach you on fitness and nutrition! Ask me something about your workouts or diet instead. 💪"

Reply only in the language the user writes in.
''';
  }
}
