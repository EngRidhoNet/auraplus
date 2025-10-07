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
    extends ConsumerState<VocabularyTherapyScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int correctAnswers = 0;
  int totalAnswers = 0;
  DateTime? sessionStartTime;
  String? currentSessionId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    sessionStartTime = DateTime.now();
    _startTherapySession();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: false,
      appBar: _buildModernAppBar(contentAsync, isDark),
      body: contentAsync.when(
        data: (content) => content.isEmpty
            ? _buildEmptyContent(isDark)
            : _buildTherapyContent(content, isDark),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorContent(error.toString(), isDark),
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildModernAppBar(
    AsyncValue<List<TherapyContent>> contentAsync,
    bool isDark,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.category.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          contentAsync.when(
            data: (content) => Text(
              '${currentIndex + 1} of ${content.length} words',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 16,
                color: _getCategoryColor(),
              ),
              const SizedBox(width: 4),
              Text(
                '$correctAnswers/$totalAnswers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getCategoryColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MAIN CONTENT
  // ============================================================================

  Widget _buildTherapyContent(List<TherapyContent> content, bool isDark) {
    if (currentIndex >= content.length) {
      return _buildSessionComplete(isDark);
    }

    final currentContent = content[currentIndex];

    return Column(
      children: [
        // Modern Progress Bar
        _buildProgressBar(content.length, isDark),

        // Content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Word Header Card
                    _buildWordHeaderCard(currentContent, isDark),

                    const SizedBox(height: 20),

                    // Main Word Card
                    _buildModernWordCard(currentContent, isDark),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildModernActionButtons(content, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int totalItems, bool isDark) {
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: (currentIndex + 1) / totalItems,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor()),
        ),
      ),
    );
  }

  Widget _buildWordHeaderCard(TherapyContent content, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(),
            _getCategoryColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Learn this word',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.targetWord.toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (content.pronunciation != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                content.pronunciation!,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernWordCard(TherapyContent content, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCategoryColor().withOpacity(0.2),
                  _getCategoryColor().withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _getCategoryColor().withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _getContentIcon(content.targetWord),
              size: 60,
              color: _getCategoryColor(),
            ),
          ),

          const SizedBox(height: 20),

          // Word
          Text(
            content.targetWord,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 1,
            ),
          ),

          if (content.description != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content.description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // AR Button
          _buildARButton(content, isDark),
        ],
      ),
    );
  }

  Widget _buildARButton(TherapyContent content, bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(),
            _getCategoryColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('AR session completed!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.view_in_ar_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Experience in AR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButtons(List<TherapyContent> content, bool isDark) {
    return Row(
      children: [
        // Wrong Answer Button
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.shade400,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleAnswer(false, content),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: Colors.red.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wrong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Correct Answer Button
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF66BB6A),
                  Color(0xFF43A047),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF66BB6A).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleAnswer(true, content),
                borderRadius: BorderRadius.circular(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Correct',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // SESSION COMPLETE
  // ============================================================================

  Widget _buildSessionComplete(bool isDark) {
    final accuracy =
        totalAnswers > 0 ? (correctAnswers / totalAnswers * 100) : 0.0;
    final duration = sessionStartTime != null
        ? DateTime.now().difference(sessionStartTime!).inSeconds
        : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF121212),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(),
                      _getCategoryColor().withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getCategoryColor().withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Session Complete!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Great job! Keep practicing!',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              // Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Results',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildModernStatRow(
                      Icons.percent_rounded,
                      'Accuracy',
                      '${accuracy.toStringAsFixed(1)}%',
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildModernStatRow(
                      Icons.check_circle_rounded,
                      'Correct Answers',
                      '$correctAnswers/$totalAnswers',
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildModernStatRow(
                      Icons.timer_rounded,
                      'Duration',
                      _formatDuration(duration),
                      isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              _buildCompleteActionButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
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
      ),
    );
  }

  Widget _buildCompleteActionButtons(bool isDark) {
    return Column(
      children: [
        // Try Again Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCategoryColor(),
                _getCategoryColor().withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _getCategoryColor().withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  currentIndex = 0;
                  correctAnswers = 0;
                  totalAnswers = 0;
                  sessionStartTime = DateTime.now();
                });
                _startTherapySession();
                _animationController.reset();
                _animationController.forward();
              },
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Back to Categories',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // LOADING & ERROR STATES
  // ============================================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: _getCategoryColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading vocabulary...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.library_books_rounded,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No content available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  void _handleAnswer(bool isCorrect, List<TherapyContent> content) {
    setState(() {
      totalAnswers++;
      if (isCorrect) correctAnswers++;
      currentIndex++;
    });

    // Reset animation for next card
    _animationController.reset();
    _animationController.forward();

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              isCorrect ? 'Correct! Well done!' : 'Keep practicing!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
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
      return const Color(0xFF4A90E2);
    }
  }

  IconData _getContentIcon(String word) {
    final iconMap = {
      'cat': Icons.pets_rounded,
      'kucing': Icons.pets_rounded,
      'dog': Icons.pets_rounded,
      'anjing': Icons.pets_rounded,
      'apple': Icons.apple_rounded,
      'apel': Icons.apple_rounded,
      'red': Icons.palette_rounded,
      'merah': Icons.palette_rounded,
      'blue': Icons.palette_rounded,
      'biru': Icons.palette_rounded,
      'circle': Icons.circle_rounded,
      'lingkaran': Icons.circle_rounded,
      'square': Icons.square_rounded,
      'kotak': Icons.square_rounded,
      'ball': Icons.sports_soccer_rounded,
      'bola': Icons.sports_soccer_rounded,
      'car': Icons.directions_car_rounded,
      'mobil': Icons.directions_car_rounded,
      'house': Icons.home_rounded,
      'rumah': Icons.home_rounded,
      'tree': Icons.park_rounded,
      'pohon': Icons.park_rounded,
      'book': Icons.book_rounded,
      'buku': Icons.book_rounded,
    };

    return iconMap[word.toLowerCase()] ?? Icons.category_rounded;
  }
}