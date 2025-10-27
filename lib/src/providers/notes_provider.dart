import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';
import '../services/firebase_service.dart';

// Notes by topic stream provider
final notesByTopicProvider = StreamProvider.family<List<NoteModel>, String>((ref, topicId) {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) {
    return Stream.value([]);
  }
  return FirebaseService.watchNotesByTopic(firebaseUser.uid, topicId);
});

// Notes by subject stream provider
final notesBySubjectProvider = StreamProvider.family<List<NoteModel>, String>((ref, subjectId) {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) {
    return Stream.value([]);
  }
  return FirebaseService.watchNotesBySubject(firebaseUser.uid, subjectId);
});

// All notes stream provider
final allNotesProvider = StreamProvider<List<NoteModel>>((ref) {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) {
    return Stream.value([]);
  }
  return FirebaseService.watchAllNotes(firebaseUser.uid);
});

// Notes controller provider
final notesControllerProvider = Provider<NotesController>((ref) {
  return NotesController();
});

class NotesController {
  // Save note
  Future<void> saveNote(NoteModel note) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      await FirebaseService.saveNote(firebaseUser.uid, note);
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      await FirebaseService.deleteNote(firebaseUser.uid, noteId);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get note by ID
  Future<NoteModel?> getNote(String noteId) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      return await FirebaseService.getNote(firebaseUser.uid, noteId);
    } catch (e) {
      rethrow;
    }
  }
}

