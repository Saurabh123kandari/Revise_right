import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String userId;
  final DateTime date;
  final List<ScheduleTask> tasks;
  final int totalMinutes;
  final int completedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const ScheduleModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.tasks,
    required this.totalMinutes,
    required this.completedMinutes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Add fromFirestore method
  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel.fromMap(data);
  }
  
  // Add toFirestore method
  Map<String, dynamic> toFirestore() {
    return toMap();
  }
  
  // Validation: Total minutes must be non-negative, completed minutes cannot exceed total
  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    // Validate total minutes
    final totalMinutes = map['totalMinutes'] ?? 0;
    if (totalMinutes < 0) {
      throw ArgumentError('Total minutes cannot be negative, got: $totalMinutes');
    }
    
    // Validate completed minutes
    final completedMinutes = map['completedMinutes'] ?? 0;
    if (completedMinutes < 0) {
      throw ArgumentError('Completed minutes cannot be negative, got: $completedMinutes');
    }
    
    if (completedMinutes > totalMinutes) {
      throw ArgumentError('Completed minutes ($completedMinutes) cannot exceed total minutes ($totalMinutes)');
    }
    
    return ScheduleModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: map['date'] != null 
        ? (map['date'] as Timestamp).toDate()
        : DateTime.now(),
      tasks: (map['tasks'] as List<dynamic>?)
          ?.map((task) => ScheduleTask.fromMap(task))
          .toList() ?? [],
      totalMinutes: totalMinutes,
      completedMinutes: completedMinutes,
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
        ? (map['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'totalMinutes': totalMinutes,
      'completedMinutes': completedMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  // Validation: Ensure completed minutes don't exceed total
  ScheduleModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<ScheduleTask>? tasks,
    int? totalMinutes,
    int? completedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Validate completed minutes if provided
    if (completedMinutes != null) {
      final newTotal = totalMinutes ?? this.totalMinutes;
      if (completedMinutes < 0) {
        throw ArgumentError('Completed minutes cannot be negative, got: $completedMinutes');
      }
      if (completedMinutes > newTotal) {
        throw ArgumentError('Completed minutes ($completedMinutes) cannot exceed total minutes ($newTotal)');
      }
    }
    
    return ScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'ScheduleModel(id: $id, date: $date, tasks: ${tasks.length}, completed: $completedMinutes/$totalMinutes)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleModel && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

class ScheduleTask {
  final String topicId;
  final String topicName;
  final String subjectId;
  final String subjectName;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;
  final DateTime? completedAt;
  
  const ScheduleTask({
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.subjectName,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.isCompleted,
    this.completedAt,
  });
  
  // Validation: Duration must be positive, end time must be after start time
  factory ScheduleTask.fromMap(Map<String, dynamic> map) {
    // Validate duration
    final durationMinutes = map['durationMinutes'] ?? 30;
    if (durationMinutes <= 0) {
      throw ArgumentError('Duration minutes must be positive, got: $durationMinutes');
    }
    
    // Validate time relationship
    final startTime = (map['startTime'] as Timestamp).toDate();
    final endTime = (map['endTime'] as Timestamp).toDate();
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('End time cannot be before start time');
    }
    
    return ScheduleTask(
      topicId: map['topicId'] ?? '',
      topicName: map['topicName'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      durationMinutes: durationMinutes,
      startTime: startTime,
      endTime: endTime,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
        ? (map['completedAt'] as Timestamp).toDate() 
        : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'durationMinutes': durationMinutes,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isCompleted': isCompleted,
      'completedAt': completedAt != null 
        ? Timestamp.fromDate(completedAt!) 
        : null,
    };
  }
  
  // Validation: Ensure duration is positive and time relationship is valid
  ScheduleTask copyWith({
    String? topicId,
    String? topicName,
    String? subjectId,
    String? subjectName,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    // Validate duration if provided
    if (durationMinutes != null && durationMinutes <= 0) {
      throw ArgumentError('Duration minutes must be positive, got: $durationMinutes');
    }
    
    // Validate time relationship if both times are provided
    if (startTime != null && endTime != null && endTime.isBefore(startTime)) {
      throw ArgumentError('End time cannot be before start time');
    }
    
    return ScheduleTask(
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
  
  @override
  String toString() {
    return 'ScheduleTask(topic: $topicName, duration: ${durationMinutes}m, completed: $isCompleted)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleTask && other.topicId == topicId;
  }
  
  @override
  int get hashCode => topicId.hashCode;
}