import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../core/constants.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User references
  static DocumentReference getUserRef(String uid) {
    return _firestore.collection(AppConstants.usersCollection).doc(uid);
  }
  
  static CollectionReference getUserSchedulesRef(String uid) {
    return getUserRef(uid).collection(AppConstants.schedulesCollection);
  }
  
  static DocumentReference getScheduleRef(String uid, String date) {
    return getUserSchedulesRef(uid).doc(date);
  }
  
  // User operations
  static Future<void> createUser(UserModel user) async {
    await getUserRef(user.uid).set(user.toFirestore());
  }
  
  static Future<UserModel?> getUser(String uid) async {
    final doc = await getUserRef(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }
  
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await getUserRef(uid).update(data);
  }
  
  // Schedule operations
  static Future<void> writeSchedule(String uid, ScheduleModel schedule) async {
    final dateKey = _formatDateKey(schedule.date);
    await getScheduleRef(uid, dateKey).set(schedule.toFirestore());
  }
  
  static Future<ScheduleModel?> getSchedule(String uid, DateTime date) async {
    final dateKey = _formatDateKey(date);
    final doc = await getScheduleRef(uid, dateKey).get();
    if (doc.exists) {
      return ScheduleModel.fromFirestore(doc);
    }
    return null;
  }
  
  static Future<void> updateScheduleTask(
    String uid, 
    DateTime date, 
    String topicId, 
    bool isCompleted
  ) async {
    final dateKey = _formatDateKey(date);
    final scheduleRef = getScheduleRef(uid, dateKey);
    
    await _firestore.runTransaction((transaction) async {
      final scheduleDoc = await transaction.get(scheduleRef);
      if (!scheduleDoc.exists) return;
      
      final schedule = ScheduleModel.fromFirestore(scheduleDoc);
      final updatedTasks = schedule.tasks.map((task) {
        if (task.topicId == topicId) {
          return task.copyWith(
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
          );
        }
        return task;
      }).toList();
      
      final completedMinutes = updatedTasks
          .where((task) => task.isCompleted)
          .fold(0, (sum, task) => sum + task.durationMinutes);
      
      final updatedSchedule = schedule.copyWith(
        tasks: updatedTasks,
        completedMinutes: completedMinutes,
        updatedAt: DateTime.now(),
      );
      
      transaction.set(scheduleRef, updatedSchedule.toFirestore());
    });
  }
  
  static Stream<ScheduleModel?> watchSchedule(String uid, DateTime date) {
    final dateKey = _formatDateKey(date);
    return getScheduleRef(uid, dateKey)
        .snapshots()
        .map((doc) => doc.exists ? ScheduleModel.fromFirestore(doc) : null);
  }
  
  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}