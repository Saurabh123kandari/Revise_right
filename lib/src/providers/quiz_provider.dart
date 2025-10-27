import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/quiz_model.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';

/// Stream provider for quizzes by note
final quizzesByNoteProvider = StreamProvider.family<List<QuizModel>, String>((ref, noteId) {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) return Stream.value([]);
  return FirebaseService.watchQuizzesByNote(firebaseUser.uid, noteId);
});

/// Quiz controller provider
final quizControllerProvider = Provider<QuizController>((ref) => QuizController());

class QuizController {
  /// Generate and save a quiz from note content
  Future<QuizModel> generateAndSaveQuiz({
    required String uid,
    required String noteId,
    required String subjectId,
    required String topicId,
    required String noteContent,
    required String noteTitle,
    int questionCount = 5,
  }) async {
    // Generate quiz using Gemini
    final questions = await GeminiService.generateQuiz(
      noteContent: noteContent,
      questionCount: questionCount,
    );
    
    // Create quiz model
    final quiz = QuizModel(
      id: const Uuid().v4(),
      noteId: noteId,
      subjectId: subjectId,
      topicId: topicId,
      title: 'Quiz: $noteTitle',
      questions: questions,
      createdAt: DateTime.now(),
      source: 'ai',
    );
    
    // Save to Firestore
    await FirebaseService.saveQuiz(uid, quiz);
    
    return quiz;
  }
  
  /// Save quiz result after completion
  Future<void> saveQuizResult({
    required String uid,
    required QuizModel quiz,
    required List<int?> userAnswers,
  }) async {
    int score = 0;
    for (int i = 0; i < quiz.questions.length; i++) {
      if (userAnswers[i] == quiz.questions[i].correctAnswer) {
        score++;
      }
    }
    
    final result = QuizResultModel(
      id: const Uuid().v4(),
      quizId: quiz.id,
      userId: uid,
      score: score,
      totalQuestions: quiz.questions.length,
      completedAt: DateTime.now(),
      userAnswers: userAnswers,
    );
    
    await FirebaseService.saveQuizResult(uid, result);
  }
}

