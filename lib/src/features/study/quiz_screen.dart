import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/quiz_model.dart';
import '../../../src/providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final QuizModel quiz;
  
  const QuizScreen({
    super.key,
    required this.quiz,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  List<int?> _selectedAnswers = [];
  List<bool> _showResults = [];
  
  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.filled(widget.quiz.questions.length, null);
    _showResults = List.filled(widget.quiz.questions.length, false);
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
      _showResults[_currentIndex] = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _saveAndShowResults();
    }
  }

  void _saveAndShowResults() async {
    // Save quiz results
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final quizController = ref.read(quizControllerProvider);
        await quizController.saveQuizResult(
          uid: firebaseUser.uid,
          quiz: widget.quiz,
          userAnswers: _selectedAnswers,
        );
      }
    } catch (e) {
      print('Error saving quiz result: $e');
    }
    
    _showResultsDialog();
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _showResultsDialog() {
    final correctAnswers = _selectedAnswers.whereIndexed((index, answer) {
      return answer == widget.quiz.questions[index].correctAnswer;
    }).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              correctAnswers == widget.quiz.questions.length
                  ? Icons.celebration
                  : Icons.check_circle,
              size: 64,
              color: correctAnswers == widget.quiz.questions.length
                  ? Colors.amber
                  : AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            Text(
              '$correctAnswers / ${widget.quiz.questions.length}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${((correctAnswers / widget.quiz.questions.length) * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No quiz questions available'),
        ),
      );
    }

    final currentQuestion = widget.quiz.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.quiz.questions.length;
    final selectedAnswer = _selectedAnswers[_currentIndex];
    final showResult = _showResults[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${widget.quiz.questions.length}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                minHeight: 4,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            currentQuestion.question,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Options
                      ...currentQuestion.options.asMap().entries.map((entry) {
                        final optionIndex = entry.key;
                        final option = entry.value;
                        final isSelected = selectedAnswer == optionIndex;
                        final isCorrect = optionIndex == currentQuestion.correctAnswer;
                        
                        Color? backgroundColor;
                        Color? textColor;
                        
                        if (showResult) {
                          if (isCorrect) {
                            backgroundColor = Colors.green[50];
                            textColor = Colors.green[700];
                          } else if (isSelected && !isCorrect) {
                            backgroundColor = Colors.red[50];
                            textColor = Colors.red[700];
                          }
                        } else if (isSelected) {
                          backgroundColor = AppTheme.primaryGreen.withOpacity(0.1);
                          textColor = AppTheme.primaryGreen;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: showResult ? null : () => _selectAnswer(optionIndex),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + optionIndex),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (showResult && isCorrect)
                                    Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0 ? _previousQuestion : null,
                      icon: const Icon(Icons.arrow_back),
                      color: _currentIndex > 0 ? AppTheme.primaryGreen : Colors.grey,
                    ),
                    const Spacer(),
                    Text(
                      '${_currentIndex + 1} / ${widget.quiz.questions.length}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: selectedAnswer != null ? _nextQuestion : null,
                      icon: const Icon(Icons.arrow_forward),
                      color: selectedAnswer != null ? AppTheme.primaryGreen : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension WhereIndexed<T> on List<T> {
  Iterable<T> whereIndexed(bool Function(int index, T element) test) {
    return asMap().entries.where((entry) => test(entry.key, entry.value)).map((entry) => entry.value);
  }
}

