import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String topicId;
  final String subjectId;
  final String content; // Rich text JSON from flutter_quill
  final String plainTextContent; // Plain text for AI processing
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  
  const NoteModel({
    required this.id,
    required this.topicId,
    required this.subjectId,
    required this.content,
    required this.plainTextContent,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });
  
  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      topicId: data['topicId'] ?? '',
      subjectId: data['subjectId'] ?? '',
      content: data['content'] ?? '',
      plainTextContent: data['plainTextContent'] ?? '',
      title: data['title'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'topicId': topicId,
      'subjectId': subjectId,
      'content': content,
      'plainTextContent': plainTextContent,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  NoteModel copyWith({
    String? id,
    String? topicId,
    String? subjectId,
    String? content,
    String? plainTextContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
  }) {
    return NoteModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      subjectId: subjectId ?? this.subjectId,
      content: content ?? this.content,
      plainTextContent: plainTextContent ?? this.plainTextContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
    );
  }
  
  @override
  String toString() {
    return 'NoteModel(id: $id, topicId: $topicId, title: $title)';
  }
}

