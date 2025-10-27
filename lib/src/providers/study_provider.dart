import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard_model.dart';
import '../services/firebase_service.dart';

// Study Session State
class StudySession {
  final DateTime startTime;
  final String topicId;
  final String subjectId;
  final String topicName;
  final String subjectName;
  final int durationMinutes;
  
  const StudySession({
    required this.startTime,
    required this.topicId,
    required this.subjectId,
    required this.topicName,
    required this.subjectName,
    required this.durationMinutes,
  });
}

// Active Study Session Provider
final activeStudySessionProvider = StateProvider<StudySession?>((ref) => null);

// Study Controller Provider
final studyControllerProvider = Provider<StudyController>((ref) {
  return StudyController();
});

class StudyController {
  // Save study session
  Future<void> saveStudySession({
    required DateTime startTime,
    required DateTime endTime,
    required String topicId,
    required String subjectId,
    int flashcardsReviewed = 0,
    int quizScore = 0,
  }) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Note: In a full implementation, we would save this to a study_sessions collection
      // For now, this is a placeholder
      print('Study session saved: ${endTime.difference(startTime).inMinutes} minutes');
    } catch (e) {
      rethrow;
    }
  }
  
  // Update flashcard review
  Future<void> updateFlashcardReview({
    required String flashcardId,
    required String difficulty,
  }) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Update flashcard with new review data
      // This would be handled by the firebase service
      final now = DateTime.now();
      // Placeholder - would need to implement in FirebaseService
      print('Flashcard $flashcardId reviewed with difficulty: $difficulty');
    } catch (e) {
      rethrow;
    }
  }
  
  // Calculate review interval based on difficulty
  Duration getReviewInterval(String difficulty, int reviewCount) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Duration(days: 7 * (reviewCount + 1));
      case 'hard':
        return Duration(days: 3 * (reviewCount + 1));
      default: // medium
        return Duration(days: 5 * (reviewCount + 1));
    }
  }
}

