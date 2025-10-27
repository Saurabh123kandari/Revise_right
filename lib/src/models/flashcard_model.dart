import 'package:cloud_firestore/cloud_firestore.dart';

enum FlashcardDifficulty {
  easy,
  medium,
  hard;
  
  String get name {
    switch (this) {
      case FlashcardDifficulty.easy:
        return 'Easy';
      case FlashcardDifficulty.medium:
        return 'Medium';
      case FlashcardDifficulty.hard:
        return 'Hard';
    }
  }
}

enum FlashcardSource {
  manual,
  aiGenerated;
  
  String get name {
    switch (this) {
      case FlashcardSource.manual:
        return 'Manual';
      case FlashcardSource.aiGenerated:
        return 'AI Generated';
    }
  }
}

class FlashcardModel {
  final String id;
  final String noteId;
  final String question;
  final String answer;
  final String difficulty;
  final DateTime? lastReviewed;
  final int reviewCount;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const FlashcardModel({
    required this.id,
    required this.noteId,
    required this.question,
    required this.answer,
    required this.difficulty,
    this.lastReviewed,
    this.reviewCount = 0,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashcardModel(
      id: doc.id,
      noteId: data['noteId'] ?? '',
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      difficulty: data['difficulty'] ?? 'medium',
      lastReviewed: data['lastReviewed'] != null 
        ? (data['lastReviewed'] as Timestamp).toDate()
        : null,
      reviewCount: data['reviewCount'] ?? 0,
      source: data['source'] ?? 'manual',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'noteId': noteId,
      'question': question,
      'answer': answer,
      'difficulty': difficulty,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReviewed': lastReviewed != null ? Timestamp.fromDate(lastReviewed!) : null,
      'reviewCount': reviewCount,
      'source': source,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  FlashcardModel copyWith({
    String? id,
    String? noteId,
    String? question,
    String? answer,
    String? difficulty,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    String? source,
    DateTime? updatedAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'FlashcardModel(id: $id, difficulty: $difficulty, reviews: $reviewCount)';
  }
}

