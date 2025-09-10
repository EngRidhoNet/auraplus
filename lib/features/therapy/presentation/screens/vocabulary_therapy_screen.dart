import 'package:aura_plus/features/therapy/domain/models/therapy_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/therapy_provider.dart';
import '../../domain/models/therapy_category.dart';
import '../../domain/models/therapy_content.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'ar_vocabulary_screen.dart';

class VocabularyTherapyScreen extends ConsumerStatefulWidget {
  final TherapyCategory category;

  const VocabularyTherapyScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<VocabularyTherapyScreen> createState() =>
      _VocabularyTherapyScreenState();
}

class _VocabularyTherapyScreenState
    extends ConsumerState<VocabularyTherapyScreen> {
  int currentIndex = 0;
  int correctAnswers = 0;
  int totalAnswers = 0;
  DateTime? sessionStartTime;
  String? currentSessionId;

  @override
  void initState() {
    super.initState();
    sessionStartTime = DateTime.now();
    _startTherapySession();
  }

  Future<void> _startTherapySession() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      await ref.read(currentSessionProvider.notifier).startSession(
            userId: currentUser.id,
            categoryId: widget.category.id,
            sessionType: SessionType.vocabulary,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(therapyContentProvider(widget.category.id));
    final currentSession = ref.watch(currentSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: _getCategoryColor(),
        foregroundColor: Colors.white,
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: contentAsync.when(
                data: (content) => Text(
                  '${currentIndex + 1}/${content.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),
        ],
      ),
      body: contentAsync.when(
        data: (content) => content.isEmpty
            ? _buildEmptyContent()
            : _buildTherapyContent(content),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorContent(error.toString()),
      ),
    );
  }

  Widget _buildTherapyContent(List<TherapyContent> content) {
    if (currentIndex >= content.length) {
      return _buildSessionComplete();
    }

    final currentContent = content[currentIndex];

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: (currentIndex + 1) / content.length,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor()),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Learn this word:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentContent.targetWord.toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(),
                        ),
                      ),
                      if (currentContent.pronunciation != null)
                        Text(
                          currentContent.pronunciation!,
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Word Card
                Expanded(
                  child: _buildWordCard(currentContent),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(TherapyContent content) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor().withOpacity(0.1),
              _getCategoryColor().withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image placeholder (AR will replace this)
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(75),
              ),
              child: Icon(
                _getContentIcon(content.targetWord),
                size: 80,
                color: _getCategoryColor(),
              ),
            ),

            const SizedBox(height: 24),

            // Word
            Text(
              content.targetWord,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            if (content.description != null)
              Text(
                content.description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

            const SizedBox(height: 20),

            // AR Button (placeholder)
            // Replace AR Button dengan ini:
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ARVocabularyScreen(
                      content: content,
                      onComplete: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('AR session completed!')),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.view_in_ar),
              label: const Text('View in AR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getCategoryColor(),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(List<TherapyContent> content) {
    return Row(
      children: [
        // I Got It Wrong
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleAnswer(false, content),
            icon: const Icon(Icons.close),
            label: const Text('I Got It Wrong'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // I Got It Right
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleAnswer(true, content),
            icon: const Icon(Icons.check),
            label: const Text('I Got It Right'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionComplete() {
    final accuracy =
        totalAnswers > 0 ? (correctAnswers / totalAnswers * 100) : 0.0;
    final duration = sessionStartTime != null
        ? DateTime.now().difference(sessionStartTime!).inSeconds
        : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: _getCategoryColor(),
            ),

            const SizedBox(height: 24),

            const Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            // Stats
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStatRow('Accuracy', '${accuracy.toStringAsFixed(1)}%'),
                  const SizedBox(height: 12),
                  _buildStatRow(
                      'Correct Answers', '$correctAnswers/$totalAnswers'),
                  const SizedBox(height: 12),
                  _buildStatRow('Duration', '${duration}s'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentIndex = 0;
                        correctAnswers = 0;
                        totalAnswers = 0;
                        sessionStartTime = DateTime.now();
                      });
                      _startTherapySession();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCategoryColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back to Categories'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getCategoryColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleAnswer(bool isCorrect, List<TherapyContent> content) {
    setState(() {
      totalAnswers++;
      if (isCorrect) correctAnswers++;
      currentIndex++;
    });

    // Record progress
    final currentSession = ref.read(currentSessionProvider).value;
    final currentUser = ref.read(currentUserProvider).value;

    if (currentSession != null &&
        currentUser != null &&
        currentIndex <= content.length) {
      ref.read(currentSessionProvider.notifier).recordProgress(
            sessionId: currentSession.id,
            contentId: content[currentIndex - 1].id,
            userId: currentUser.id,
            isCorrect: isCorrect,
          );
    }

    // Complete session if finished
    if (currentIndex >= content.length) {
      _completeSession();
    }
  }

  void _completeSession() {
    final currentSession = ref.read(currentSessionProvider).value;
    if (currentSession != null) {
      final duration = sessionStartTime != null
          ? DateTime.now().difference(sessionStartTime!).inSeconds
          : 0;

      ref.read(currentSessionProvider.notifier).completeSession(
            sessionId: currentSession.id,
            completedItems: totalAnswers,
            correctAnswers: correctAnswers,
            score:
                totalAnswers > 0 ? (correctAnswers / totalAnswers * 100) : 0.0,
            durationSeconds: duration,
          );
    }
  }

  Color _getCategoryColor() {
    try {
      return Color(int.parse(widget.category.color.substring(1), radix: 16) +
          0xFF000000);
    } catch (e) {
      return Colors.green;
    }
  }

  IconData _getContentIcon(String word) {
    switch (word.toLowerCase()) {
      case 'cat':
        return Icons.pets;
      case 'dog':
        return Icons.pets;
      case 'red':
        return Icons.palette;
      case 'circle':
        return Icons.circle;
      default:
        return Icons.book;
    }
  }
}
