import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/quiz_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const String _apiKeyStorageKey = 'gemini_api_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static GenerativeModel? _model;
  
  /// Get API key from multiple sources (priority order)
  static Future<String> _getApiKey() async {
    // 1. Try secure storage first (user entered via Settings)
    final storedKey = await _secureStorage.read(key: _apiKeyStorageKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }
    
    // 2. Try environment variable (.env file)
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // 3. If neither found, throw error
    throw Exception('Gemini API key not configured.\n\nPlease add it either:\n1. In Settings → AI Integration → Gemini API Key\n2. Or create a .env file with GEMINI_API_KEY=your_key');
  }
  
  /// Get or create the GenerativeModel instance
  static Future<GenerativeModel> _getModel() async {
    final apiKey = await _getApiKey();
    
    
    _model ??= GenerativeModel(
      model: 'gemini-pro', // Stable Gemini model
      apiKey: apiKey,
    );
    return _model!;
  }
  
  /// Set the API key
  static Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
    _model = null; // Reset model to reload with new key
  }
  
  /// Check if API key is configured
  static Future<bool> isConfigured() async {
    final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  /// Generate quiz questions from note content
  static Future<List<QuizQuestionModel>> generateQuiz({
    required String noteContent,
    int questionCount = 5,
  }) async {
    try {
      final model = await _getModel();
      
      final prompt = '''
Generate $questionCount multiple-choice quiz questions from the following study notes.
Return ONLY a valid JSON array without any markdown formatting or explanation.

Format:
[
  {
    "question": "Clear question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": 0,
    "explanation": "Brief explanation of correct answer"
  }
]

Study Notes:
$noteContent

Requirements:
- Questions should test understanding, not just memorization
- Each question must have exactly 4 options
- correctAnswer is the index (0-3) of the correct option
- Include brief explanations for each correct answer
- Make questions challenging but fair
''';
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      // Parse JSON response
      final questions = _parseQuestions(text);
      
      if (questions.isEmpty) {
        throw Exception('No questions generated. Please try again.');
      }
      
      return questions;
    } catch (e) {
      print('Gemini API failed: $e');
      print('Falling back to mock quiz generation...');
      
      // Fallback to mock quiz generation
      return _generateMockQuiz(noteContent, questionCount);
    }
  }
  
  /// Generate mock quiz questions as fallback
  static List<QuizQuestionModel> _generateMockQuiz(String noteContent, int questionCount) {
    final mockQuestions = <QuizQuestionModel>[];
    
    // Extract key terms from note content
    final words = noteContent.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toSet()
        .take(10)
        .toList();
    
    for (int i = 0; i < questionCount && i < words.length; i++) {
      final term = words[i];
      final capitalizedTerm = term[0].toUpperCase() + term.substring(1);
      
      mockQuestions.add(QuizQuestionModel(
        question: 'What is the main concept related to "$capitalizedTerm" in the study material?',
        options: [
          'A key principle discussed in the notes',
          'An unrelated topic from another subject',
          'A historical event',
          'A mathematical formula'
        ],
        correctAnswer: 0,
        explanation: 'This question tests your understanding of the key concepts discussed in the study material.',
      ));
    }
    
    // If we don't have enough words, add generic questions
    while (mockQuestions.length < questionCount) {
      final index = mockQuestions.length + 1;
      mockQuestions.add(QuizQuestionModel(
        question: 'Question $index: What is the main topic discussed in this study material?',
        options: [
          'The primary subject matter covered in the notes',
          'A completely different topic',
          'Historical events',
          'Mathematical equations'
        ],
        correctAnswer: 0,
        explanation: 'This question tests your comprehension of the main topic covered in the study material.',
      ));
    }
    
    return mockQuestions;
  }
  
  /// Parse questions from AI response
  static List<QuizQuestionModel> _parseQuestions(String responseText) {
    try {
      // Extract JSON from response (handle markdown code blocks if present)
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();
      
      final List<dynamic> data = json.decode(jsonText);
      return data.map((item) {
        return QuizQuestionModel(
          question: item['question']?.toString() ?? '',
          options: List<String>.from(item['options'] ?? []),
          correctAnswer: item['correctAnswer'] ?? 0,
          explanation: item['explanation']?.toString(),
        );
      }).toList();
    } catch (e) {
      // Try to extract just the array part if JSON parsing fails
      try {
        final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(responseText);
        if (jsonMatch != null) {
          final List<dynamic> data = json.decode(jsonMatch.group(0)!);
          return data.map((item) {
            return QuizQuestionModel(
              question: item['question']?.toString() ?? '',
              options: List<String>.from(item['options'] ?? []),
              correctAnswer: item['correctAnswer'] ?? 0,
              explanation: item['explanation']?.toString(),
            );
          }).toList();
        }
      } catch (_) {
        // Fall through to rethrow original error
      }
      throw Exception('Failed to parse quiz questions: $e');
    }
  }
}

