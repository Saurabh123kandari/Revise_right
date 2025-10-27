import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../core/ai_config.dart';
import '../models/flashcard_model.dart';

class AIService {
  // Generate flashcards from note content
  static Future<List<FlashcardModel>> generateFlashcards({
    required String noteContent,
    required String noteId,
    int count = 5,
  }) async {
    if (!AIConfig.isConfigured()) {
      throw Exception('AI service not configured. Please set your API key in settings.');
    }
    
    final provider = AIConfig.selectedProvider;
    
    switch (provider) {
      case AIProvider.openai:
        return _generateFlashcardsOpenAI(noteContent, noteId, count);
      case AIProvider.gemini:
        return _generateFlashcardsGemini(noteContent, noteId, count);
    }
  }
  
  // Generate quiz questions from note content
  static Future<List<QuizQuestion>> generateQuizQuestions({
    required String noteContent,
    int count = 5,
  }) async {
    if (!AIConfig.isConfigured()) {
      throw Exception('AI service not configured. Please set your API key in settings.');
    }
    
    final provider = AIConfig.selectedProvider;
    
    switch (provider) {
      case AIProvider.openai:
        return _generateQuizOpenAI(noteContent, count);
      case AIProvider.gemini:
        return _generateQuizGemini(noteContent, count);
    }
  }
  
  // OpenAI implementation
  static Future<List<FlashcardModel>> _generateFlashcardsOpenAI(
    String noteContent,
    String noteId,
    int count,
  ) async {
    final apiKey = AIConfig.openaiApiKey;
    if (apiKey == null) throw Exception('OpenAI API key not configured');
    
    final prompt = '''
Generate $count educational flashcards from the following study notes. Return the response as a JSON array with the following format:
[
  {
    "question": "Question text",
    "answer": "Answer text"
  }
]

Notes:
$noteContent
''';
    
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        final flashcards = _parseFlashcardsFromJson(content, noteId);
        return flashcards;
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate flashcards: $e');
    }
  }
  
  static Future<List<QuizQuestion>> _generateQuizOpenAI(
    String noteContent,
    int count,
  ) async {
    final apiKey = AIConfig.openaiApiKey;
    if (apiKey == null) throw Exception('OpenAI API key not configured');
    
    final prompt = '''
Generate $count multiple choice quiz questions from the following study notes. Return the response as a JSON array with the following format:
[
  {
    "question": "Question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": 0
  }
]

Notes:
$noteContent
''';
    
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        final questions = _parseQuizQuestionsFromJson(content);
        return questions;
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }
  
  // Gemini implementation
  static Future<List<FlashcardModel>> _generateFlashcardsGemini(
    String noteContent,
    String noteId,
    int count,
  ) async {
    final apiKey = AIConfig.geminiApiKey;
    if (apiKey == null) throw Exception('Gemini API key not configured');
    
    final prompt = '''
Generate $count educational flashcards from the following study notes. Return the response as a JSON array with the following format:
[
  {
    "question": "Question text",
    "answer": "Answer text"
  }
]

Notes:
$noteContent
''';
    
    try {
      // Note: This is a placeholder for Gemini API integration
      // Gemini API structure is different from OpenAI
      throw Exception('Gemini integration not yet implemented');
    } catch (e) {
      throw Exception('Failed to generate flashcards: $e');
    }
  }
  
  static Future<List<QuizQuestion>> _generateQuizGemini(
    String noteContent,
    int count,
  ) async {
    final apiKey = AIConfig.geminiApiKey;
    if (apiKey == null) throw Exception('Gemini API key not configured');
    
    final prompt = '''
Generate $count multiple choice quiz questions from the following study notes. Return the response as a JSON array with the following format:
[
  {
    "question": "Question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": 0
  }
]

Notes:
$noteContent
''';
    
    try {
      // Note: This is a placeholder for Gemini API integration
      throw Exception('Gemini integration not yet implemented');
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }
  
  // Parse JSON responses
  static List<FlashcardModel> _parseFlashcardsFromJson(String jsonString, String noteId) {
    try {
      // Try to extract JSON array from the response
      final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
      final match = jsonRegex.firstMatch(jsonString);
      final jsonContent = match?.group(0) ?? jsonString;
      
      final List<dynamic> data = json.decode(jsonContent);
      final now = DateTime.now();
      
      return data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final question = item['question'] ?? 'Question';
        final answer = item['answer'] ?? 'Answer';
        
        return FlashcardModel(
          id: '${noteId}_${now.millisecondsSinceEpoch}_$index',
          noteId: noteId,
          question: question.toString(),
          answer: answer.toString(),
          difficulty: 'medium',
          lastReviewed: null,
          reviewCount: 0,
          source: 'ai',
          createdAt: now,
          updatedAt: now,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse flashcards: $e');
    }
  }
  
  static List<QuizQuestion> _parseQuizQuestionsFromJson(String jsonString) {
    try {
      // Try to extract JSON array from the response
      final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
      final match = jsonRegex.firstMatch(jsonString);
      final jsonContent = match?.group(0) ?? jsonString;
      
      final List<dynamic> data = json.decode(jsonContent);
      
      return data.map((item) {
        return QuizQuestion(
          question: item['question'] ?? 'Question',
          options: List<String>.from(item['options'] ?? []),
          correctAnswer: item['correctAnswer'] ?? 0,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse quiz questions: $e');
    }
  }
}

// Quiz Question model
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

