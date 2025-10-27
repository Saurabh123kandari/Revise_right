import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject_model.dart';
import '../services/firebase_service.dart';

// Subjects stream provider
final subjectsProvider = StreamProvider<List<SubjectModel>>((ref) {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) {
    return Stream.value([]);
  }
  return FirebaseService.watchSubjects(firebaseUser.uid);
});

// Subject controller provider
final subjectControllerProvider = Provider<SubjectController>((ref) {
  return SubjectController();
});

class SubjectController {
  // Create subject
  Future<void> createSubject(SubjectModel subject) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      await FirebaseService.saveSubject(firebaseUser.uid, subject);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update subject
  Future<void> updateSubject(SubjectModel subject) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      await FirebaseService.saveSubject(firebaseUser.uid, subject);
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete subject
  Future<void> deleteSubject(String subjectId) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      await FirebaseService.deleteSubject(firebaseUser.uid, subjectId);
    } catch (e) {
      rethrow;
    }
  }
}

