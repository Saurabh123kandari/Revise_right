import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../models/note_model.dart';
import '../models/flashcard_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/quiz_model.dart';
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
  
  static Future<void> updateUserPreferences(String uid, Map<String, dynamic> preferences) async {
    await getUserRef(uid).update({'preferences': preferences});
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
  
  static Future<void> addTaskToSchedule(
    String uid,
    DateTime date,
    ScheduleTask task,
  ) async {
    final dateKey = _formatDateKey(date);
    final scheduleRef = getScheduleRef(uid, dateKey);
    
    await _firestore.runTransaction((transaction) async {
      final scheduleDoc = await transaction.get(scheduleRef);
      ScheduleModel schedule;
      
      if (scheduleDoc.exists) {
        schedule = ScheduleModel.fromFirestore(scheduleDoc);
        final updatedTasks = [...schedule.tasks, task];
        final totalMinutes = updatedTasks.fold(0, (sum, t) => sum + t.durationMinutes);
        
        schedule = schedule.copyWith(
          tasks: updatedTasks,
          totalMinutes: totalMinutes,
          updatedAt: DateTime.now(),
        );
      } else {
        // Create new schedule if it doesn't exist
        schedule = ScheduleModel(
          id: dateKey,
          userId: uid,
          date: date,
          tasks: [task],
          totalMinutes: task.durationMinutes,
          completedMinutes: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      transaction.set(scheduleRef, schedule.toFirestore());
    });
  }
  
  static Stream<ScheduleModel?> watchSchedule(String uid, DateTime date) {
    final dateKey = _formatDateKey(date);
    return getScheduleRef(uid, dateKey)
        .snapshots()
        .map((doc) => doc.exists ? ScheduleModel.fromFirestore(doc) : null);
  }
  
  // Notes operations
  static CollectionReference getNotesRef(String uid) {
    return getUserRef(uid).collection('notes');
  }
  
  static DocumentReference getNoteRef(String uid, String noteId) {
    return getNotesRef(uid).doc(noteId);
  }
  
  static Future<void> saveNote(String uid, NoteModel note) async {
    await getNoteRef(uid, note.id).set(note.toFirestore());
  }
  
  static Future<NoteModel?> getNote(String uid, String noteId) async {
    final doc = await getNoteRef(uid, noteId).get();
    if (doc.exists) {
      return NoteModel.fromFirestore(doc);
    }
    return null;
  }
  
  static Future<List<NoteModel>> getNotesByTopic(String uid, String topicId) async {
    final snapshot = await getNotesRef(uid)
        .where('topicId', isEqualTo: topicId)
        .get();
    
    return snapshot.docs
        .map((doc) => NoteModel.fromFirestore(doc))
        .toList();
  }
  
  static Future<List<NoteModel>> getNotesBySubject(String uid, String subjectId) async {
    final snapshot = await getNotesRef(uid)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    
    return snapshot.docs
        .map((doc) => NoteModel.fromFirestore(doc))
        .toList();
  }
  
  static Stream<List<NoteModel>> watchNotesByTopic(String uid, String topicId) {
    return getNotesRef(uid)
        .where('topicId', isEqualTo: topicId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromFirestore(doc))
            .toList());
  }
  
  static Stream<List<NoteModel>> watchNotesBySubject(String uid, String subjectId) {
    return getNotesRef(uid)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromFirestore(doc))
            .toList());
  }
  
  static Stream<List<NoteModel>> watchAllNotes(String uid) {
    return getNotesRef(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromFirestore(doc))
            .toList());
  }
  
  static Future<void> deleteNote(String uid, String noteId) async {
    await getNoteRef(uid, noteId).delete();
  }
  
  // Flashcards operations
  static CollectionReference getFlashcardsRef(String uid) {
    return getUserRef(uid).collection('flashcards');
  }
  
  static DocumentReference getFlashcardRef(String uid, String flashcardId) {
    return getFlashcardsRef(uid).doc(flashcardId);
  }
  
  static Future<void> saveFlashcard(String uid, FlashcardModel flashcard) async {
    await getFlashcardRef(uid, flashcard.id).set(flashcard.toFirestore());
  }
  
  static Future<List<FlashcardModel>> getFlashcardsByNote(String uid, String noteId) async {
    final snapshot = await getFlashcardsRef(uid)
        .where('noteId', isEqualTo: noteId)
        .get();
    
    return snapshot.docs
        .map((doc) => FlashcardModel.fromFirestore(doc))
        .toList();
  }
  
  static Stream<List<FlashcardModel>> watchFlashcardsByNote(String uid, String noteId) {
    return getFlashcardsRef(uid)
        .where('noteId', isEqualTo: noteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlashcardModel.fromFirestore(doc))
            .toList());
  }
  
  static Future<void> updateFlashcard(String uid, FlashcardModel flashcard) async {
    await getFlashcardRef(uid, flashcard.id).set(flashcard.toFirestore());
  }
  
  static Future<void> deleteFlashcard(String uid, String flashcardId) async {
    await getFlashcardRef(uid, flashcardId).delete();
  }
  
  // Quiz operations
  static CollectionReference getQuizzesRef(String uid) {
    return getUserRef(uid).collection('quizzes');
  }
  
  static DocumentReference getQuizRef(String uid, String quizId) {
    return getQuizzesRef(uid).doc(quizId);
  }
  
  static Future<void> saveQuiz(String uid, QuizModel quiz) async {
    await getQuizRef(uid, quiz.id).set(quiz.toFirestore());
  }
  
  static Future<QuizModel?> getQuiz(String uid, String quizId) async {
    final doc = await getQuizRef(uid, quizId).get();
    if (!doc.exists) return null;
    return QuizModel.fromFirestore(doc);
  }
  
  static Future<List<QuizModel>> getQuizzesByNote(String uid, String noteId) async {
    final snapshot = await getQuizzesRef(uid)
        .where('noteId', isEqualTo: noteId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => QuizModel.fromFirestore(doc)).toList();
  }
  
  static Stream<List<QuizModel>> watchQuizzesByNote(String uid, String noteId) {
    return getQuizzesRef(uid)
        .where('noteId', isEqualTo: noteId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuizModel.fromFirestore(doc))
            .toList());
  }
  
  // Quiz results
  static CollectionReference getQuizResultsRef(String uid) {
    return getUserRef(uid).collection('quiz_results');
  }
  
  static Future<void> saveQuizResult(String uid, QuizResultModel result) async {
    await getQuizResultsRef(uid).doc(result.id).set(result.toFirestore());
  }
  
  static Future<List<QuizResultModel>> getQuizResults(String uid, String quizId) async {
    final snapshot = await getQuizResultsRef(uid)
        .where('quizId', isEqualTo: quizId)
        .orderBy('completedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => QuizResultModel.fromFirestore(doc)).toList();
  }
  
  // Subjects operations
  static CollectionReference getSubjectsRef(String uid) {
    return getUserRef(uid).collection('subjects');
  }
  
  static DocumentReference getSubjectRef(String uid, String subjectId) {
    return getSubjectsRef(uid).doc(subjectId);
  }
  
  static Future<void> saveSubject(String uid, SubjectModel subject) async {
    await getSubjectRef(uid, subject.id).set(subject.toMap());
  }
  
  static Future<SubjectModel?> getSubject(String uid, String subjectId) async {
    final doc = await getSubjectRef(uid, subjectId).get();
    if (doc.exists) {
      return SubjectModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
  
  static Stream<List<SubjectModel>> watchSubjects(String uid) {
    return getSubjectsRef(uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  static Future<List<SubjectModel>> getAllSubjects(String uid) async {
    final snapshot = await getSubjectsRef(uid)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => SubjectModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
  
  static Future<void> deleteSubject(String uid, String subjectId) async {
    await getSubjectRef(uid, subjectId).delete();
  }
  
  // Topics operations
  static CollectionReference getTopicsRef(String uid) {
    return getUserRef(uid).collection('topics');
  }
  
  static DocumentReference getTopicRef(String uid, String topicId) {
    return getTopicsRef(uid).doc(topicId);
  }
  
  static Future<void> saveTopic(String uid, Map<String, dynamic> topicData) async {
    await getTopicRef(uid, topicData['id'] as String).set(topicData);
  }
  
  static Stream<List<Map<String, dynamic>>> watchTopicsBySubject(String uid, String subjectId) {
    return getTopicsRef(uid)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }
  
  static Future<void> deleteTopic(String uid, String topicId) async {
    await getTopicRef(uid, topicId).delete();
  }
  
  static Future<TopicModel?> getTopic(String uid, String topicId) async {
    final doc = await getTopicRef(uid, topicId).get();
    if (doc.exists) {
      return TopicModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
  
  static Future<List<TopicModel>> getTopicsBySubject(String uid, String subjectId) async {
    final snapshot = await getTopicsRef(uid)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    return snapshot.docs
        .map((doc) => TopicModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
  
  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}