import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String noteId;
  final String subjectId;
  final String topicId;
  final String title;
  final List<QuizQuestionModel> questions;
  final DateTime createdAt;
  final String source; // 'ai' or 'manual'
  
  QuizModel({
    required this.id,
    required this.noteId,
    required this.subjectId,
    required this.topicId,
    required this.title,
    required this.questions,
    required this.createdAt,
    this.source = 'ai',
  });
  
  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return QuizModel(
      id: doc.id,
      noteId: data['noteId'] ?? '',
      subjectId: data['subjectId'] ?? '',
      topicId: data['topicId'] ?? '',
      title: data['title'] ?? '',
      questions: (data['questions'] as List?)
          ?.map((q) => QuizQuestionModel.fromMap(q as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: data['source'] ?? 'ai',
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'noteId': noteId,
      'subjectId': subjectId,
      'topicId': topicId,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'source': source,
    };
  }
}

class QuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String? explanation;
  
  QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
  
  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      explanation: map['explanation'],
    );
  }
}

class QuizResultModel {
  final String id;
  final String quizId;
  final String userId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final List<int?> userAnswers;
  
  QuizResultModel({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.userAnswers,
  });
  
  factory QuizResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return QuizResultModel(
      id: doc.id,
      quizId: data['quizId'] ?? '',
      userId: data['userId'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userAnswers: List<int?>.from(data['userAnswers'] ?? []),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': Timestamp.fromDate(completedAt),
      'userAnswers': userAnswers,
    };
  }
}

