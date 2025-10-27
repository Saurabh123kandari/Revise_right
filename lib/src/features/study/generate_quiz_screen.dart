import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/note_model.dart';
import '../../../src/models/quiz_model.dart';
import '../../../src/providers/quiz_provider.dart';
import 'quiz_screen.dart';

class GenerateQuizScreen extends ConsumerStatefulWidget {
  final NoteModel note;
  
  const GenerateQuizScreen({
    super.key,
    required this.note,
  });

  @override
  ConsumerState<GenerateQuizScreen> createState() => _GenerateQuizScreenState();
}

class _GenerateQuizScreenState extends ConsumerState<GenerateQuizScreen> {
  int _selectedQuestionCount = 5;
  bool _isGenerating = false;
  String? _error;

  Future<void> _generateQuiz() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      final quizController = ref.read(quizControllerProvider);
      final quiz = await quizController.generateAndSaveQuiz(
        uid: firebaseUser.uid,
        noteId: widget.note.id,
        subjectId: widget.note.subjectId,
        topicId: widget.note.topicId,
        noteContent: widget.note.plainTextContent,
        noteTitle: widget.note.title ?? 'Untitled',
        questionCount: _selectedQuestionCount,
      );

      if (mounted) {
        // Navigate to quiz screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(quiz: quiz),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate AI Quiz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF16213E)
                  : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note Preview
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.note.title ?? 'Untitled Note',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.note.plainTextContent.length > 200
                                ? '${widget.note.plainTextContent.substring(0, 200)}...'
                                : widget.note.plainTextContent,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Question Count Selector
                  Text(
                    'Number of Questions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _QuestionCountButton(
                          count: 3,
                          selected: _selectedQuestionCount == 3,
                          onTap: () => setState(() => _selectedQuestionCount = 3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuestionCountButton(
                          count: 5,
                          selected: _selectedQuestionCount == 5,
                          onTap: () => setState(() => _selectedQuestionCount = 5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuestionCountButton(
                          count: 10,
                          selected: _selectedQuestionCount == 10,
                          onTap: () => setState(() => _selectedQuestionCount = 10),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Info Card
                  Card(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Questions are generated using AI and test understanding of the note content.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Error Message
                  if (_error != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateQuiz,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.quiz),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCountButton extends StatelessWidget {
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _QuestionCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.quiz,
              color: selected ? Colors.white : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.grey[800],
              ),
            ),
            Text(
              count == 1 ? 'Question' : 'Questions',
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
