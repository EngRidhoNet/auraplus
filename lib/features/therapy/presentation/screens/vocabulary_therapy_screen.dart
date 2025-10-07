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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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

        // Content - Scrollable with proper constraints
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Header info - Compact
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _getCategoryColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Learn this word:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentContent.targetWord.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getCategoryColor(),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (currentContent.pronunciation != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  currentContent.pronunciation!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Word Card - Optimized with constraints
                        _buildWordCard(currentContent),

                        const SizedBox(height: 16),

                        // Action Buttons
                        _buildActionButtons(content),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(TherapyContent content) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxHeight: 320, // 👈 KEY FIX: Limit max height
        ),
        padding: const EdgeInsets.all(18),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(45),
                boxShadow: [
                  BoxShadow(
                    color: _getCategoryColor().withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _getContentIcon(content.targetWord),
                size: 45,
                color: _getCategoryColor(),
              ),
            ),

            const SizedBox(height: 14),

            // Word
            Text(
              content.targetWord,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 8),

            // Description - with flexible constraint
            if (content.description != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    content.description!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // AR Button - CLICKABLE!
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ARVocabularyScreen(
                        content: content,
                        onComplete: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('AR session completed!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.view_in_ar, size: 20),
                label: const Text(
                  'View in AR',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 5,
                  shadowColor: _getCategoryColor().withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(List<TherapyContent> content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // I Got It Wrong
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleAnswer(false, content),
              icon: const Icon(Icons.close, size: 20),
              label: const Text(
                'I Got It Wrong',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // I Got It Right
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleAnswer(true, content),
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'I Got It Right',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 5,
                shadowColor: Colors.green.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionComplete() {
    final accuracy =
        totalAnswers > 0 ? (correctAnswers / totalAnswers * 100) : 0.0;
    final duration = sessionStartTime != null
        ? DateTime.now().difference(sessionStartTime!).inSeconds
        : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 80,
                color: _getCategoryColor(),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Great job! Keep practicing!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 32),

            // Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getCategoryColor().withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow(
                    Icons.percent,
                    'Accuracy',
                    '${accuracy.toStringAsFixed(1)}%',
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    Icons.check_circle,
                    'Correct Answers',
                    '$correctAnswers/$totalAnswers',
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    Icons.timer,
                    'Duration',
                    _formatDuration(duration),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        currentIndex = 0;
                        correctAnswers = 0;
                        totalAnswers = 0;
                        sessionStartTime = DateTime.now();
                      });
                      _startTherapySession();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCategoryColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'Back to Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: _getCategoryColor(),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: _getCategoryColor(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getCategoryColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check back later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAnswer(bool isCorrect, List<TherapyContent> content) {
    setState(() {
      totalAnswers++;
      if (isCorrect) correctAnswers++;
      currentIndex++;
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(isCorrect ? 'Correct! Well done!' : 'Keep practicing!'),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${seconds}s';
  }

  Color _getCategoryColor() {
    try {
      return Color(
        int.parse(widget.category.color.substring(1), radix: 16) + 0xFF000000,
      );
    } catch (e) {
      return Colors.green;
    }
  }

  IconData _getContentIcon(String word) {
    final iconMap = {
      'cat': Icons.pets,
      'kucing': Icons.pets,
      'dog': Icons.pets,
      'anjing': Icons.pets,
      'apple': Icons.apple,
      'apel': Icons.apple,
      'red': Icons.palette,
      'merah': Icons.palette,
      'blue': Icons.palette,
      'biru': Icons.palette,
      'circle': Icons.circle,
      'lingkaran': Icons.circle,
      'square': Icons.square,
      'kotak': Icons.square,
      'ball': Icons.sports_soccer,
      'bola': Icons.sports_soccer,
      'car': Icons.directions_car,
      'mobil': Icons.directions_car,
      'house': Icons.home,
      'rumah': Icons.home,
      'tree': Icons.park,
      'pohon': Icons.park,
      'book': Icons.book,
      'buku': Icons.book,
    };

    return iconMap[word.toLowerCase()] ?? Icons.category;
  }
}