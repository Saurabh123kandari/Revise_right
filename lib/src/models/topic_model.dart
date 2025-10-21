import 'package:cloud_firestore/cloud_firestore.dart';

class TopicModel {
  final String id;
  final String subjectId;
  final String name;
  final String? description;
  final int priority; // 1-3 (low, medium, high)
  final int estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final DateTime? completedAt;
  
  const TopicModel({
    required this.id,
    required this.subjectId,
    required this.name,
    this.description,
    required this.priority,
    required this.estimatedMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.isCompleted,
    this.completedAt,
  });
  
  // Validation: Priority must be between 1-3, estimatedMinutes must be positive
  factory TopicModel.fromMap(Map<String, dynamic> map) {
    // Validate priority
    final priority = map['priority'] ?? 1;
    if (priority < 1 || priority > 3) {
      throw ArgumentError('Priority must be between 1 and 3, got: $priority');
    }
    
    // Validate estimated minutes
    final estimatedMinutes = map['estimatedMinutes'] ?? 30;
    if (estimatedMinutes <= 0) {
      throw ArgumentError('Estimated minutes must be positive, got: $estimatedMinutes');
    }
    
    return TopicModel(
      id: map['id'] ?? '',
      subjectId: map['subjectId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
        ? (map['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
        ? (map['completedAt'] as Timestamp).toDate() 
        : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'description': description,
      'priority': priority,
      'estimatedMinutes': estimatedMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isCompleted': isCompleted,
      'completedAt': completedAt != null 
        ? Timestamp.fromDate(completedAt!) 
        : null,
    };
  }
  
  // Validation: Ensure priority is within valid range
  TopicModel copyWith({
    String? id,
    String? subjectId,
    String? name,
    String? description,
    int? priority,
    int? estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    // Validate priority if provided
    if (priority != null && (priority < 1 || priority > 3)) {
      throw ArgumentError('Priority must be between 1 and 3, got: $priority');
    }
    
    // Validate estimated minutes if provided
    if (estimatedMinutes != null && estimatedMinutes <= 0) {
      throw ArgumentError('Estimated minutes must be positive, got: $estimatedMinutes');
    }
    
    return TopicModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
  
  @override
  String toString() {
    return 'TopicModel(id: $id, name: $name, priority: $priority, isCompleted: $isCompleted)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopicModel && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}