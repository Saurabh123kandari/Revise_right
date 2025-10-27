import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/flashcard_model.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String topicId;
  final List<FlashcardModel> flashcards;
  
  const FlashcardScreen({
    super.key,
    required this.topicId,
    required this.flashcards,
  });

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  
  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
      setState(() => _isFlipped = false);
    } else {
      _flipController.forward();
      setState(() => _isFlipped = true);
    }
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _flipController.reset();
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _flipController.reset();
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Cards Reviewed!'),
        content: const Text('You have completed all flashcards for this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to study mode
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _rateCard(String difficulty) {
    // Update flashcard review
    // This would save to Firestore
    print('Card rated: $difficulty');
    
    // Move to next card after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _nextCard();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz,
                  size: 80,
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Flashcards Available',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Add notes and generate flashcards to get started.'),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentFlashcard = widget.flashcards[_currentIndex];
    final progress = (_currentIndex + 1) / widget.flashcards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Card ${_currentIndex + 1} of ${widget.flashcards.length}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                minHeight: 4,
              ),
              const SizedBox(height: 16),
              
              // Flashcard
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _flipController,
                      builder: (context, child) {
                        final angle = _flipController.value;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle * 3.14159),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48,
                            height: 400,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _isFlipped
                                ? _buildBack(currentFlashcard)
                                : _buildFront(currentFlashcard),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_isFlipped) ...[
                      // Difficulty buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rateCard('hard'),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Hard', style: TextStyle(color: Colors.red)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rateCard('medium'),
                              icon: const Icon(Icons.check_circle_outline, color: Colors.orange),
                              label: const Text('OK', style: TextStyle(color: Colors.orange)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[50],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rateCard('easy'),
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              label: const Text('Easy', style: TextStyle(color: Colors.green)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[50],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Flip button
                      ElevatedButton.icon(
                        onPressed: _flipCard,
                        icon: const Icon(Icons.flip),
                        label: const Text('Flip Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Navigation buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: _currentIndex > 0 ? _previousCard : null,
                          icon: const Icon(Icons.arrow_back),
                          color: _currentIndex > 0 ? AppTheme.primaryGreen : Colors.grey,
                        ),
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1} / ${widget.flashcards.length}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _currentIndex < widget.flashcards.length - 1 ? _nextCard : null,
                          icon: const Icon(Icons.arrow_forward),
                          color: _currentIndex < widget.flashcards.length - 1 ? AppTheme.primaryGreen : Colors.grey,
                        ),
                      ],
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

  Widget _buildFront(FlashcardModel flashcard) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            size: 64,
            color: AppTheme.primaryGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Question',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                flashcard.question,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to flip',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(FlashcardModel flashcard) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: AppTheme.primaryGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Answer',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                flashcard.answer,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'How did you do?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

