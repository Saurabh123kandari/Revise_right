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
      
      // Fetch actual schedule data from Firestore
      final stats = <StudyStat>[];
      
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        try {
          final schedule = await FirebaseService.getSchedule(firebaseUser.uid, date);
          
          if (schedule != null) {
            final completedTasks = schedule.tasks.where((task) => task.isCompleted).length;
            stats.add(StudyStat(
              date: date,
              minutesStudied: schedule.completedMinutes,
              tasksCompleted: completedTasks,
              flashcardsReviewed: 0, // TODO: Implement flashcard tracking
            ));
          } else {
            // No schedule for this day
            stats.add(StudyStat(
              date: date,
              minutesStudied: 0,
              tasksCompleted: 0,
              flashcardsReviewed: 0,
            ));
          }
        } catch (e) {
          print('Error loading schedule for ${date}: $e');
          // Add empty stat for this day
          stats.add(StudyStat(
            date: date,
            minutesStudied: 0,
            tasksCompleted: 0,
            flashcardsReviewed: 0,
          ));
        }
      }
      
      return stats;
    } catch (e) {
      print('Error in getWeeklyStats: $e');
      // Return empty stats on error
      return List.generate(7, (index) {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return StudyStat(
          date: weekStart.add(Duration(days: index)),
          minutesStudied: 0,
          tasksCompleted: 0,
          flashcardsReviewed: 0,
        );
      });
    }
  }
  
  // Get subject distribution stats
  Future<List<SubjectStats>> getSubjectStats() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return [];
      }
      
      // Fetch actual subjects from Firestore
      final subjectsStream = FirebaseService.watchSubjects(firebaseUser.uid);
      final subjects = await subjectsStream.first;
      
      if (subjects.isEmpty) {
        return [];
      }
      
      // Fetch weekly schedules to calculate time per subject
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final stats = <SubjectStats>[];
      
      for (final subject in subjects) {
        int totalMinutes = 0;
        int totalNotes = 0;
        int completedTasks = 0;
        int totalTasks = 0;
        
        // Calculate time spent on this subject this week
        for (int i = 0; i < 7; i++) {
          final date = weekStart.add(Duration(days: i));
          try {
            final schedule = await FirebaseService.getSchedule(firebaseUser.uid, date);
            if (schedule != null) {
              // Filter tasks for this subject
              final subjectTasks = schedule.tasks.where((task) => task.subjectId == subject.id).toList();
              totalTasks += subjectTasks.length;
              completedTasks += subjectTasks.where((task) => task.isCompleted).length;
              
              // Add completed time from this subject's tasks
              for (final task in subjectTasks) {
                if (task.isCompleted) {
                  totalMinutes += task.durationMinutes;
                }
              }
            }
          } catch (e) {
            // Skip this day
          }
        }
        
        // Get notes count for this subject
        try {
          final notes = await FirebaseService.getNotesBySubject(firebaseUser.uid, subject.id);
          totalNotes = notes.length;
        } catch (e) {
          // No notes or error
        }
        
        final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
        
        stats.add(SubjectStats(
          subjectId: subject.id,
          subjectName: subject.name,
          totalMinutes: totalMinutes,
          totalNotes: totalNotes,
          totalFlashcards: 0, // TODO: Implement flashcard count
          completionRate: completionRate,
        ));
      }
      
      return stats;
    } catch (e) {
      print('Error in getSubjectStats: $e');
      return [];
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

