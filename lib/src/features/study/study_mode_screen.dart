import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/flashcard_model.dart';
import '../../../src/providers/study_provider.dart';
import '../../../src/services/firebase_service.dart';
import '../../../src/services/ai_service.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class StudyModeScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String subjectId;
  final String topicName;
  final String subjectName;
  final int durationMinutes;
  
  const StudyModeScreen({
    super.key,
    required this.topicId,
    required this.subjectId,
    required this.topicName,
    required this.subjectName,
    required this.durationMinutes,
  });

  @override
  ConsumerState<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends ConsumerState<StudyModeScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isActive = false;
  bool _isLoadingFlashcards = false;
  bool _isGeneratingFlashcards = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
          
          // Check if study time is complete
          if (_elapsedSeconds >= widget.durationMinutes * 60) {
            _stopTimer();
            _showCompletionDialog();
          }
        });
      }
    });
    setState(() => _isActive = true);
  }
  
  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isActive = false);
  }
  
  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isActive = false);
  }
  
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _showCompletionDialog() async {
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Study Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'You studied for ${_formatTime(_elapsedSeconds)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _startStudySession() async {
    setState(() => _isLoadingFlashcards = true);
    
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Set active study session
      ref.read(activeStudySessionProvider.notifier).state = StudySession(
        startTime: DateTime.now(),
        topicId: widget.topicId,
        subjectId: widget.subjectId,
        topicName: widget.topicName,
        subjectName: widget.subjectName,
        durationMinutes: widget.durationMinutes,
      );
      
      // Check if flashcards exist
      final flashcards = await FirebaseService.getFlashcardsByNote(firebaseUser.uid, widget.topicId);
      
      if (flashcards.isEmpty && !_isGeneratingFlashcards) {
        _showGenerateFlashcardsDialog();
        return;
      }
      
      if (mounted) {
        _startTimer();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardScreen(
              topicId: widget.topicId,
              flashcards: flashcards,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFlashcards = false);
      }
    }
  }

  void _showGenerateFlashcardsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Flashcards Yet'),
        content: const Text(
          'Would you like to generate AI flashcards from your notes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateFlashcards();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateFlashcards() async {
    setState(() => _isGeneratingFlashcards = true);
    
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Get notes for this topic
      final notes = await FirebaseService.getNotesByTopic(firebaseUser.uid, widget.topicId);
      
      if (notes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No notes found for this topic'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Generate flashcards from the first note
      final note = notes.first;
      final flashcards = await AIService.generateFlashcards(
        noteContent: note.plainTextContent,
        noteId: note.id,
        count: 5,
      );
      
      // Save flashcards to Firestore
      for (final flashcard in flashcards) {
        await FirebaseService.saveFlashcard(firebaseUser.uid, flashcard);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcards generated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        
        // Start study session with the new flashcards
        await _startStudySession();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating flashcards: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingFlashcards = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studySession = ref.watch(activeStudySessionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(studySession != null ? 'Study Session' : 'Start Study'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Subject Info
                  Icon(
                    Icons.school,
                    size: 80,
                    color: AppTheme.primaryGreen.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.topicName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subjectName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Timer Display
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 48,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _formatTime(_elapsedSeconds),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Goal: ${widget.durationMinutes} minutes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  if (!_isActive && !_isLoadingFlashcards && !_isGeneratingFlashcards) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _startStudySession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                        child: const Text(
                          'Start Study Session',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_isLoadingFlashcards || _isGeneratingFlashcards) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isGeneratingFlashcards 
                          ? 'Generating flashcards...' 
                          : 'Loading study materials...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pauseTimer,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _stopTimer();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('End'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

