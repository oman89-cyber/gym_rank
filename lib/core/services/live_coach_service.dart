import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/workout_session.dart';

class LiveCoachService {
  LiveCoachService._();
  static final LiveCoachService instance = LiveCoachService._();

  static const String _kApiKey = 'AIzaSyAqh6Peqn_DcaD74F_Et3LJrRczZ1A9G78';
  static const String _kBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final _textController = StreamController<String>.broadcast();
  final _statusController = StreamController<bool>.broadcast();

  Stream<String> get responseText => _textController.stream;
  Stream<bool> get connectionStatus => _statusController.stream;

  bool _isConnected = false;

  Future<void> connect(UserProfile profile, List<WorkoutSession> sessions) async {
    _isConnected = true;
    _statusController.add(true);
    _textController.add("--- AI SYNCED (REST MODE) ---");
    _textController.add("Hello! Point the camera at yourself to begin.");
  }

  void sendFrame(Uint8List imageBytes, UserProfile profile, List<WorkoutSession> sessions) async {
    if (!_isConnected) return;

    final url = '$_kBaseUrl?key=$_kApiKey';
    final base64Image = base64Encode(imageBytes);

    final body = {
      "contents": [
        {
          "parts": [
            {"text": _buildPollingSystemPrompt(profile, sessions)},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            },
            {"text": "Analyze this frame and give one ultra-short form correction if needed. If good, say nothing."}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 1,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 20,
        "responseMimeType": "text/plain",
      }
    };

    try {
      _textController.add("📤 Uploading...");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _textController.add("📥 Looked!");
        final data = jsonDecode(response.body);
        final String? feedback = data['candidates']?[0]['content']?['parts']?[0]['text'];
        if (feedback != null && feedback.trim().isNotEmpty) {
          _textController.add(feedback.trim());
        }
      } else {
        _textController.add("⚠️ AI BUSY (${response.statusCode})");
        debugPrint('[LiveCoach] Polling Error: ${response.statusCode}');
      }
    } catch (e) {
      _textController.add("❌ LINK ERROR: $e");
      debugPrint('[LiveCoach] REST Exception: $e');
    }
  }

  void disconnect() {
    _isConnected = false;
    _statusController.add(false);
    _textController.add("--- CONNECTION DISCONTINUED ---");
  }

  String _buildPollingSystemPrompt(UserProfile profile, List<WorkoutSession> sessions) {
    return '''
You are GymAI REST, a high-speed vision coach.
Athlete: ${profile.username} | Goal: ${profile.goal}
You see ONE frame at a time. 
Identify the workout and give one ultra-short feedback (under 10 words).
If the form is fine, reply with an empty string or nothing. 
NEVER use internal monologue. Direct feedback only.
''';
  }
}
