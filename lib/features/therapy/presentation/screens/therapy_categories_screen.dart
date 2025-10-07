import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/therapy_provider.dart';
import '../../domain/models/therapy_category.dart';
import '../../domain/models/therapy_session.dart';
import '../../domain/models/therapy_content.dart';
import 'vocabulary_therapy_screen.dart';
import 'verbal_therapy_screen.dart';
import 'aac_therapy_screen.dart';

class TherapyCategoriesScreen extends ConsumerStatefulWidget {
  final SessionType sessionType;
  final String title;
  
  const TherapyCategoriesScreen({
    super.key,
    this.sessionType = SessionType.vocabulary,
    this.title = 'Therapy Categories',
  });

  @override
  ConsumerState<TherapyCategoriesScreen> createState() =>
      _TherapyCategoriesScreenState();
}

class _TherapyCategoriesScreenState
    extends ConsumerState<TherapyCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(therapyCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: false,
      appBar: _buildModernAppBar(isDark),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoriesList(context, categories, ref, isDark),
        loading: () => _buildLoadingState(isDark),
        error: (error, stack) => _buildErrorContent(context, error.toString(), ref, isDark),
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildModernAppBar(bool isDark) {
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
            _getSessionTypeTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            'Choose a category',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            onPressed: () => _showSessionTypeInfo(context, isDark),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MAIN CONTENT
  // ============================================================================

  Widget _buildCategoriesList(
    BuildContext context,
    List<TherapyCategory> categories,
    WidgetRef ref,
    bool isDark,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern Header
          SliverToBoxAdapter(
            child: _buildModernHeader(isDark),
          ),
          
          // Categories Grid
          categories.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.92, // ✅ INCREASED from 0.85 to 0.92
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildCategoryCard(
                          context,
                          categories[index],
                          ref,
                          isDark,
                          index,
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
          
          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getSessionTypeColor(),
            _getSessionTypeColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getSessionTypeColor().withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getSessionTypeIcon(),
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSessionTypeTitle(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSessionTypeShortName(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getSessionTypeDescription(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.95),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED CATEGORY CARD - NO MORE OVERFLOW
  Widget _buildCategoryCard(
    BuildContext context,
    TherapyCategory category,
    WidgetRef ref,
    bool isDark,
    int index,
  ) {
    final color = _getColorFromHex(category.color);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _navigateToSession(context, category);
            },
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background Gradient Circle
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16), // ✅ REDUCED from 20 to 16
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top section: Icon & Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Container
                          Container(
                            width: 56, // ✅ REDUCED from 64 to 56
                            height: 56, // ✅ REDUCED from 64 to 56
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(category.name),
                              size: 28, // ✅ REDUCED from 32 to 28
                              color: color,
                            ),
                          ),
                          
                          // Arrow Button
                          Container(
                            width: 36, // ✅ REDUCED from 40 to 36
                            height: 36, // ✅ REDUCED from 40 to 36
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18, // ✅ REDUCED from 20 to 18
                              color: color,
                            ),
                          ),
                        ],
                      ),

                      // Bottom section: Title & Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // ✅ ADDED
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 16, // ✅ REDUCED from 18 to 16
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6), // ✅ REDUCED from 8 to 6
                          if (category.description != null)
                            Text(
                              category.description!,
                              style: TextStyle(
                                fontSize: 12, // ✅ REDUCED from 13 to 12
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                height: 1.3, // ✅ REDUCED from 1.4 to 1.3
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  // ============================================================================
  // EMPTY & ERROR STATES
  // ============================================================================

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getSessionTypeColor().withOpacity(0.2),
                  _getSessionTypeColor().withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: _getSessionTypeColor().withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 70,
              color: _getSessionTypeColor(),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Categories Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Categories for ${_getSessionTypeTitle()}\nwill appear here when added.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getSessionTypeColor(),
                  _getSessionTypeColor().withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getSessionTypeColor().withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _addSampleCategories(context),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Add Sample Categories',
                        style: TextStyle(
                          color: Colors.white,
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
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getSessionTypeColor().withOpacity(0.2),
                  _getSessionTypeColor().withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getSessionTypeColor(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading categories...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    String error,
    WidgetRef ref,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.shade200,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Categories',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Retry Button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getSessionTypeColor(),
                      _getSessionTypeColor().withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getSessionTypeColor().withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ref.refresh(therapyCategoriesProvider),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
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

              const SizedBox(width: 12),

              // Go Back Button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2D2D2D)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Go Back',
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
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  void _navigateToSession(BuildContext context, TherapyCategory category) {
    Widget destinationScreen;
    
    switch (widget.sessionType) {
      case SessionType.vocabulary:
        destinationScreen = VocabularyTherapyScreen(category: category);
        break;
      case SessionType.verbal:
        destinationScreen = VerbalTherapyScreen(
          categoryName: category.name,
          content: _createSampleContent(category),
          onComplete: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.celebration_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Verbal therapy session completed! 🎉'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF66BB6A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
        );
        break;
      case SessionType.aac:
        destinationScreen = AACTherapyScreen(
          categoryId: category.id,
          categoryName: category.name,
        );
        break;
    }
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            destinationScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Color _getSessionTypeColor() {
    switch (widget.sessionType) {
      case SessionType.vocabulary:
        return const Color(0xFF66BB6A);
      case SessionType.verbal:
        return const Color(0xFFFF9800);
      case SessionType.aac:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getSessionTypeIcon() {
    switch (widget.sessionType) {
      case SessionType.vocabulary:
        return Icons.school_rounded;
      case SessionType.verbal:
        return Icons.record_voice_over_rounded;
      case SessionType.aac:
        return Icons.touch_app_rounded;
    }
  }

  String _getSessionTypeTitle() {
    switch (widget.sessionType) {
      case SessionType.vocabulary:
        return 'Vocabulary Therapy';
      case SessionType.verbal:
        return 'Verbal Therapy';
      case SessionType.aac:
        return 'AAC Therapy';
    }
  }

  String _getSessionTypeShortName() {
    switch (widget.sessionType) {
      case SessionType.vocabulary:
        return 'VOCAB';
      case SessionType.verbal:
        return 'VERBAL';
      case SessionType.aac:
        return 'AAC';
    }
  }

  String _getSessionTypeDescription() {
    switch (widget.sessionType) {
      case SessionType.vocabulary:
        return 'Interactive vocabulary learning with AR visualization and word recognition exercises to enhance language skills.';
      case SessionType.verbal:
        return 'Speech practice sessions with real-time pronunciation feedback and voice recognition technology.';
      case SessionType.aac:
        return 'Alternative communication tools using symbols, pictures, and interactive communication boards for non-verbal expression.';
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return _getSessionTypeColor();
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final iconMap = {
      'animals': Icons.pets_rounded,
      'food & drinks': Icons.restaurant_rounded,
      'food': Icons.restaurant_rounded,
      'colors & shapes': Icons.palette_rounded,
      'colors': Icons.palette_rounded,
      'shapes': Icons.category_rounded,
      'body parts': Icons.accessibility_rounded,
      'body': Icons.accessibility_rounded,
      'family & people': Icons.family_restroom_rounded,
      'family': Icons.family_restroom_rounded,
      'emotions': Icons.sentiment_satisfied_rounded,
      'actions': Icons.directions_run_rounded,
      'objects': Icons.widgets_rounded,
      'places': Icons.place_rounded,
      'vehicles': Icons.directions_car_rounded,
      'nature': Icons.nature_rounded,
    };

    return iconMap[categoryName.toLowerCase()] ?? Icons.category_rounded;
  }

  void _showSessionTypeInfo(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getSessionTypeColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getSessionTypeIcon(),
                color: _getSessionTypeColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_getSessionTypeTitle()),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSessionTypeDescription(),
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSessionTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getSessionTypeColor(),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._getSessionTypeFeatures().map((feature) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: _getSessionTypeColor(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSessionTypeColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSessionTypeFeatures() {
    switch (widget.sessionType) {
      case SessionType.vocabulary:
        return [
          'AR word visualization in 3D space',
          'Interactive 3D models',
          'Pronunciation guides with audio',
          'Progress tracking and analytics',
          'Adaptive difficulty levels',
        ];
      case SessionType.verbal:
        return [
          'Real-time speech recognition',
          'Pronunciation feedback and analysis',
          'Voice quality assessment',
          'Speaking practice exercises',
          'Progress monitoring',
        ];
      case SessionType.aac:
        return [
          'Symbol-based communication',
          'Picture exchange system',
          'Touch-based interaction',
          'Customizable communication boards',
          'Voice output options',
        ];
    }
  }

  void _addSampleCategories(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Sample categories feature coming soon!'),
          ],
        ),
        backgroundColor: _getSessionTypeColor(),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  TherapyContent _createSampleContent(TherapyCategory category) {
    return TherapyContent(
      id: 'sample_${category.id}',
      categoryId: category.id,
      title: _getSampleWord(category.name),
      targetWord: _getSampleWord(category.name),
      pronunciation: _getSamplePronunciation(category.name),
      description: 'Practice word from ${category.name} category',
      contentType: ContentType.word,
      difficultyLevel: 1,
      imageUrl: null,
      audioUrl: null,
      createdAt: DateTime.now(),
    );
  }

  String _getSampleWord(String categoryName) {
    final sampleWords = {
      'animals': 'cat',
      'food & drinks': 'apple',
      'food': 'apple',
      'colors & shapes': 'red',
      'colors': 'red',
      'body parts': 'hand',
      'body': 'hand',
      'family & people': 'mom',
      'family': 'mom',
      'emotions': 'happy',
      'actions': 'run',
    };

    return sampleWords[categoryName.toLowerCase()] ?? 'word';
  }

  String _getSamplePronunciation(String categoryName) {
    final pronunciations = {
      'animals': '/kæt/',
      'food & drinks': '/ˈæpəl/',
      'food': '/ˈæpəl/',
      'colors & shapes': '/red/',
      'colors': '/red/',
      'body parts': '/hænd/',
      'body': '/hænd/',
      'family & people': '/mɑm/',
      'family': '/mɑm/',
      'emotions': '/ˈhæpi/',
      'actions': '/rʌn/',
    };

    return pronunciations[categoryName.toLowerCase()] ?? '/wɜrd/';
  }
}