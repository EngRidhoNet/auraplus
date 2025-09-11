import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/therapy_provider.dart';
import '../../domain/models/therapy_category.dart';
import '../../domain/models/therapy_session.dart';
import 'vocabulary_therapy_screen.dart';
import 'verbal_therapy_screen.dart';
import 'aac_therapy_screen.dart';

class TherapyCategoriesScreen extends ConsumerWidget {
  final SessionType sessionType;
  final String title;
  
  const TherapyCategoriesScreen({
    super.key,
    this.sessionType = SessionType.vocabulary,
    this.title = 'Therapy Categories',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(therapyCategoriesProvider);
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: _buildAppBar(context),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoriesList(context, categories, ref),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorContent(context, error.toString(), ref),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: _getAppBarColor(),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showSessionTypeInfo(context),
        ),
      ],
    );
  }

  Color _getAppBarColor() {
    switch (sessionType) {
      case SessionType.vocabulary:
        return Colors.green.shade700;
      case SessionType.verbal:
        return Colors.orange.shade700;
      case SessionType.aac:
        return Colors.purple.shade700;
    }
  }

  Color _getBackgroundColor() {
    switch (sessionType) {
      case SessionType.vocabulary:
        return Colors.green.shade50;
      case SessionType.verbal:
        return Colors.orange.shade50;
      case SessionType.aac:
        return Colors.purple.shade50;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_getAppBarColor()),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading categories...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesList(BuildContext context, List<TherapyCategory> categories, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // Header section
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        
        // Categories grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: categories.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      return _buildCategoryCard(context, category, ref);
                    },
                    childCount: categories.length,
                  ),
                ),
        ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getAppBarColor().withOpacity(0.1),
            _getAppBarColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getAppBarColor().withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAppBarColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSessionTypeIcon(),
                  size: 32,
                  color: _getAppBarColor(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSessionTypeTitle(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getAppBarColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a Category',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getSessionTypeDescription(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, TherapyCategory category, WidgetRef ref) {
    final color = _getColorFromHex(category.color);
    
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _navigateToSession(context, category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.05),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon container
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(category.name),
                        size: 36,
                        color: color,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    if (category.description != null)
                      Text(
                        category.description!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // Session type indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAppBarColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSessionTypeIcon(),
                            size: 12,
                            color: _getAppBarColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getSessionTypeShortName(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getAppBarColor(),
                            ),
                          ),
                        ],
                      ),
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
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Categories Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Categories for ${sessionType.displayName} will appear here when added.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) => ElevatedButton.icon(
              onPressed: () {
                // Add sample categories for testing
                _addSampleCategories(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Sample Categories'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getAppBarColor(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorContent(BuildContext context, String error, WidgetRef ref) {
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
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ref.refresh(therapyCategoriesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getAppBarColor(),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _getAppBarColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToSession(BuildContext context, TherapyCategory category) {
    Widget destinationScreen;
    
    switch (sessionType) {
      case SessionType.vocabulary:
        destinationScreen = VocabularyTherapyScreen(category: category);
        break;
      case SessionType.verbal:
        destinationScreen = VerbalTherapyScreen(
          content: _createSampleContent(category),
          onComplete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verbal therapy session completed!'),
              ),
            );
          },
        );
        break;
      case SessionType.aac:
        destinationScreen = AACTherapyScreen(category: category);
        break;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  // Helper methods
  IconData _getSessionTypeIcon() {
    switch (sessionType) {
      case SessionType.vocabulary:
        return Icons.school;
      case SessionType.verbal:
        return Icons.record_voice_over;
      case SessionType.aac:
        return Icons.touch_app;
    }
  }

  String _getSessionTypeTitle() {
    switch (sessionType) {
      case SessionType.vocabulary:
        return 'Vocabulary Therapy';
      case SessionType.verbal:
        return 'Verbal Therapy';
      case SessionType.aac:
        return 'AAC Therapy';
    }
  }

  String _getSessionTypeShortName() {
    switch (sessionType) {
      case SessionType.vocabulary:
        return 'VOCAB';
      case SessionType.verbal:
        return 'VERBAL';
      case SessionType.aac:
        return 'AAC';
    }
  }

  String _getSessionTypeDescription() {
    switch (sessionType) {
      case SessionType.vocabulary:
        return 'Interactive vocabulary learning with AR visualization and word recognition exercises.';
      case SessionType.verbal:
        return 'Speech practice sessions with real-time pronunciation feedback and voice recognition.';
      case SessionType.aac:
        return 'Alternative communication tools using symbols, pictures, and interactive communication boards.';
    }
  }
  
  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return _getAppBarColor(); // Use session type color as default
    }
  }
  
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'animals':
        return Icons.pets;
      case 'food & drinks':
      case 'food':
        return Icons.restaurant;
      case 'colors & shapes':
      case 'colors':
        return Icons.palette;
      case 'body parts':
      case 'body':
        return Icons.accessibility;
      case 'family & people':
      case 'family':
        return Icons.family_restroom;
      case 'emotions':
        return Icons.sentiment_satisfied;
      case 'actions':
        return Icons.directions_run;
      case 'objects':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  void _showSessionTypeInfo(BuildContext context) {
    // Show dialog with session type information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getSessionTypeTitle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getSessionTypeDescription()),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getAppBarColor(),
              ),
            ),
            const SizedBox(height: 8),
            ..._getSessionTypeFeatures().map((feature) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: _getAppBarColor(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  List<String> _getSessionTypeFeatures() {
    switch (sessionType) {
      case SessionType.vocabulary:
        return [
          'AR word visualization',
          '3D interactive models',
          'Pronunciation guides',
          'Progress tracking',
        ];
      case SessionType.verbal:
        return [
          'Speech recognition',
          'Pronunciation feedback',
          'Real-time analysis',
          'Speaking practice',
        ];
      case SessionType.aac:
        return [
          'Symbol communication',
          'Picture exchange',
          'Touch-based interaction',
          'Customizable boards',
        ];
    }
  }

  void _addSampleCategories(BuildContext context) {
    // This would trigger adding sample categories
    // In real app, this would call a provider method
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample categories would be added here'),
      ),
    );
  }

  // Create sample content for testing
  dynamic _createSampleContent(TherapyCategory category) {
    // This should return appropriate content based on session type
    // For now, return a basic structure that matches expected interface
    return {
      'id': 'sample_${category.id}',
      'categoryId': category.id,
      'title': 'Sample ${category.name} Word',
      'description': 'Practice word from ${category.name}',
      'contentType': 'word',
      'difficultyLevel': 1,
      'targetWord': _getSampleWord(category.name),
      'pronunciation': _getSamplePronunciation(category.name),
      'createdAt': DateTime.now(),
    };
  }

  String _getSampleWord(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'animals':
        return 'cat';
      case 'food & drinks':
      case 'food':
        return 'apple';
      case 'colors & shapes':
      case 'colors':
        return 'red';
      case 'body parts':
      case 'body':
        return 'hand';
      case 'family & people':
      case 'family':
        return 'mom';
      default:
        return 'word';
    }
  }

  String _getSamplePronunciation(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'animals':
        return '/kæt/';
      case 'food & drinks':
      case 'food':
        return '/ˈæpəl/';
      case 'colors & shapes':
      case 'colors':
        return '/red/';
      case 'body parts':
      case 'body':
        return '/hænd/';
      case 'family & people':
      case 'family':
        return '/mɑm/';
      default:
        return '/wɜrd/';
    }
  }
}