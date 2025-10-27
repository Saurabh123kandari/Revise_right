import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class StudyStat {
  final DateTime date;
  final int minutesStudied;
  final int tasksCompleted;
  final int flashcardsReviewed;
  
  const StudyStat({
    required this.date,
    required this.minutesStudied,
    required this.tasksCompleted,
    required this.flashcardsReviewed,
  });
}

class SubjectStats {
  final String subjectId;
  final String subjectName;
  final int totalMinutes;
  final int totalNotes;
  final int totalFlashcards;
  final double completionRate;
  
  const SubjectStats({
    required this.subjectId,
    required this.subjectName,
    required this.totalMinutes,
    required this.totalNotes,
    required this.totalFlashcards,
    required this.completionRate,
  });
}

// Progress Controller Provider
final progressControllerProvider = Provider<ProgressController>((ref) {
  return ProgressController();
});

class ProgressController {
  // Get weekly study stats
  Future<List<StudyStat>> getWeeklyStats() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return [];
      }
      
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      // This is a placeholder - in full implementation, we would:
      // 1. Query study sessions from Firestore
      // 2. Aggregate data by day
      // 3. Return list of StudyStat objects
      
      // For now, return mock data for demonstration
      return List.generate(7, (index) {
        return StudyStat(
          date: weekStart.add(Duration(days: index)),
          minutesStudied: (30 + (index * 15)).clamp(0, 120),
          tasksCompleted: (2 + index).clamp(0, 5),
          flashcardsReviewed: (10 + (index * 5)).clamp(0, 50),
        );
      });
    } catch (e) {
      rethrow;
    }
  }
  
  // Get subject distribution stats
  Future<List<SubjectStats>> getSubjectStats() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return [];
      }
      
      // This is a placeholder - in full implementation, we would:
      // 1. Get all subjects
      // 2. Calculate time spent per subject
      // 3. Get notes and flashcards count per subject
      // 4. Calculate completion rates
      
      // For now, return mock data
      return [
        SubjectStats(
          subjectId: 'math',
          subjectName: 'Mathematics',
          totalMinutes: 240,
          totalNotes: 8,
          totalFlashcards: 24,
          completionRate: 0.75,
        ),
        SubjectStats(
          subjectId: 'physics',
          subjectName: 'Physics',
          totalMinutes: 180,
          totalNotes: 5,
          totalFlashcards: 18,
          completionRate: 0.65,
        ),
        SubjectStats(
          subjectId: 'chemistry',
          subjectName: 'Chemistry',
          totalMinutes: 150,
          totalNotes: 6,
          totalFlashcards: 15,
          completionRate: 0.60,
        ),
      ];
    } catch (e) {
      rethrow;
    }
  }
  
  // Calculate current streak
  int calculateStreak(List<StudyStat> stats) {
    if (stats.isEmpty) return 0;
    
    int streak = 0;
    final now = DateTime.now();
    
    // Check each day going backwards from today
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStat = stats.firstWhere(
        (stat) => _isSameDay(stat.date, date),
        orElse: () => StudyStat(
          date: date,
          minutesStudied: 0,
          tasksCompleted: 0,
          flashcardsReviewed: 0,
        ),
      );
      
      if (dayStat.minutesStudied > 0) {
        streak++;
      } else if (i < 6) {
        // Only break streak if it's not today (today might still be ongoing)
        break;
      }
    }
    
    return streak;
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // Get total study time (in minutes)
  int getTotalMinutes(List<StudyStat> stats) {
    return stats.fold(0, (sum, stat) => sum + stat.minutesStudied);
  }
  
  // Get completion rate
  double getCompletionRate(List<StudyStat> stats) {
    if (stats.isEmpty) return 0.0;
    
    final completed = stats.where((stat) => stat.tasksCompleted > 0).length;
    return completed / stats.length;
  }
  
  // Get average study time
  double getAverageMinutes(List<StudyStat> stats) {
    if (stats.isEmpty) return 0.0;
    return getTotalMinutes(stats) / stats.length;
  }
}

