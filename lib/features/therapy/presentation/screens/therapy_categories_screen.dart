import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/therapy_provider.dart';
import '../../domain/models/therapy_category.dart';
import 'vocabulary_therapy_screen.dart';

class TherapyCategoriesScreen extends ConsumerWidget {
  const TherapyCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(therapyCategoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Therapy'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoriesList(context, categories, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorContent(context, error.toString()),
      ),
    );
  }
  
  Widget _buildCategoriesList(BuildContext context, List<TherapyCategory> categories, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 32,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Choose a Category',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a vocabulary category to start learning!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Categories Grid
          Expanded(
            child: categories.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryCard(context, category, ref);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, TherapyCategory category, WidgetRef ref) {
    final color = _getColorFromHex(category.color);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VocabularyTherapyScreen(category: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  size: 32,
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
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No categories available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Categories will appear here when added',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorContent(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading categories',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Refresh categories
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue; // Default color
    }
  }
  
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'animals':
        return Icons.pets;
      case 'food & drinks':
        return Icons.restaurant;
      case 'colors & shapes':
        return Icons.palette;
      case 'body parts':
        return Icons.accessibility;
      case 'family & people':
        return Icons.family_restroom;
      default:
        return Icons.category;
    }
  }
}