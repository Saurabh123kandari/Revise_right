import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/schedule_model.dart';
import '../models/topic_model.dart';
import '../models/subject_model.dart';
import '../services/scheduler_service.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

// Today's schedule provider
final todaysScheduleProvider = StreamProvider<ScheduleModel?>((ref) {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    return FirebaseService.watchSchedule(firebaseUser.uid, DateTime.now());
  }
  return Stream.value(null);
});

// Schedule controller provider
final scheduleControllerProvider = Provider<ScheduleController>((ref) {
  return ScheduleController();
});

class ScheduleController {
  // Generate new schedule
  Future<ScheduleModel> generateSchedule({
    required String userId,
    required DateTime date,
    required List<TopicModel> topics,
    required List<SubjectModel> subjects,
    required int maxStudyMinutes,
  }) async {
    try {
      // Convert TopicModel to Topic for scheduler service
      final schedulerTopics = topics.map((topic) => Topic(
        id: topic.id,
        name: topic.name,
        difficulty: topic.priority.toDouble(),
        dueDate: date.add(Duration(days: 7)), // Default due date
        revisionNeeded: false,
        lastStudied: DateTime.now().subtract(Duration(days: 1)),
        isCompleted: topic.isCompleted,
      )).toList();
      
      final availablePerDay = {date: maxStudyMinutes};
      final scheduleEntries = SchedulerService.generateSchedule(
        topics: schedulerTopics,
        start: date,
        availablePerDay: availablePerDay,
      );
      
      // Convert ScheduleEntry to ScheduleModel
      final tasks = scheduleEntries.map((entry) => ScheduleTask(
        topicId: entry.topic.id,
        topicName: entry.topic.name,
        subjectId: subjects.isNotEmpty ? subjects.first.id : '',
        subjectName: subjects.isNotEmpty ? subjects.first.name : '',
        durationMinutes: entry.durationMinutes,
        startTime: entry.startTime,
        endTime: entry.endTime,
        isCompleted: false,
      )).toList();
      
      return ScheduleModel(
        id: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        userId: userId,
        date: date,
        tasks: tasks,
        totalMinutes: tasks.fold(0, (sum, task) => sum + task.durationMinutes),
        completedMinutes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Create schedule
  Future<void> createSchedule({
    required String userId,
    required ScheduleModel schedule,
  }) async {
    try {
      await FirebaseService.writeSchedule(userId, schedule);
    } catch (e) {
      rethrow;
    }
  }
  
  // Mark task as completed
  Future<void> markTaskCompleted({
    required String userId,
    required DateTime date,
    required String topicId,
    required bool isCompleted,
  }) async {
    try {
      await FirebaseService.updateScheduleTask(userId, date, topicId, isCompleted);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get study progress
  double getStudyProgress(ScheduleModel schedule) {
    if (schedule.totalMinutes == 0) return 0.0;
    return schedule.completedMinutes / schedule.totalMinutes;
  }
  
  // Get remaining study time
  int getRemainingMinutes(ScheduleModel schedule) {
    return schedule.totalMinutes - schedule.completedMinutes;
  }
  
  // Get next task
  ScheduleTask? getNextTask(ScheduleModel schedule) {
    try {
      return schedule.tasks.firstWhere((task) => !task.isCompleted);
    } catch (e) {
      return schedule.tasks.isNotEmpty ? schedule.tasks.first : null;
    }
  }
}