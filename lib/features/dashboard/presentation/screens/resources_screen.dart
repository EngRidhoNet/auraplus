import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  String _selectedCategory = 'all';

  final List<ResourceItem> _resources = [
    ResourceItem(
      title: 'Speech Therapy Guide',
      category: 'guide',
      description: 'Complete guide for parents and therapists',
      icon: Icons.book_rounded,
      color: const Color(0xFF66BB6A),
      duration: '15 min read',
    ),
    ResourceItem(
      title: 'Pronunciation Techniques',
      category: 'video',
      description: 'Video tutorials for better pronunciation',
      icon: Icons.play_circle_rounded,
      color: const Color(0xFFFF9800),
      duration: '8 videos',
    ),
    ResourceItem(
      title: 'AAC Communication Tips',
      category: 'article',
      description: 'Effective AAC strategies for daily use',
      icon: Icons.article_rounded,
      color: const Color(0xFF9C27B0),
      duration: '10 min read',
    ),
    ResourceItem(
      title: 'AR Learning Activities',
      category: 'guide',
      description: 'Interactive AR exercises for kids',
      icon: Icons.view_in_ar_rounded,
      color: const Color(0xFF4A90E2),
      duration: '12 activities',
    ),
    ResourceItem(
      title: 'Parent Support Group',
      category: 'community',
      description: 'Connect with other parents',
      icon: Icons.group_rounded,
      color: const Color(0xFFE91E63),
      duration: 'Join now',
    ),
    ResourceItem(
      title: 'FAQ & Troubleshooting',
      category: 'article',
      description: 'Common questions and solutions',
      icon: Icons.help_rounded,
      color: const Color(0xFF00BCD4),
      duration: '5 min read',
    ),
  ];

  List<ResourceItem> get _filteredResources {
    if (_selectedCategory == 'all') return _resources;
    return _resources.where((r) => r.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Resources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF66BB6A).withOpacity(0.1),
                      const Color(0xFF43A047).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Category Filter
          SliverToBoxAdapter(
            child: Container(
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryChip('all', 'All', Icons.apps_rounded, isDark),
                  _buildCategoryChip('guide', 'Guides', Icons.book_rounded, isDark),
                  _buildCategoryChip('video', 'Videos', Icons.play_circle_rounded, isDark),
                  _buildCategoryChip('article', 'Articles', Icons.article_rounded, isDark),
                  _buildCategoryChip('community', 'Community', Icons.group_rounded, isDark),
                ],
              ),
            ),
          ),

          // Resources Grid
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final resource = _filteredResources[index];
                  return _buildResourceCard(resource, isDark, index);
                },
                childCount: _filteredResources.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon, bool isDark) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        ),
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
        selectedColor: const Color(0xFF66BB6A),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF66BB6A)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
          HapticFeedback.selectionClick();
        },
      ),
    );
  }

  Widget _buildResourceCard(ResourceItem resource, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: resource.color.withOpacity(0.15),
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
              _showResourceDetail(resource, isDark);
            },
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background gradient
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          resource.color.withOpacity(0.15),
                          resource.color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              resource.color.withOpacity(0.2),
                              resource.color.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: resource.color.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          resource.icon,
                          size: 28,
                          color: resource.color,
                        ),
                      ),

                      const Spacer(),

                      // Title
                      Text(
                        resource.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Text(
                        resource.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Duration badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: resource.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: resource.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              resource.duration,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: resource.color,
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
      ),
    );
  }

  void _showResourceDetail(ResourceItem resource, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [resource.color, resource.color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: resource.color.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                resource.icon,
                size: 40,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                resource.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                resource.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Coming soon message
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: resource.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: resource.color.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 48,
                      color: resource.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Coming Soon!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This resource will be available in the next update',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: resource.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResourceItem {
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final String duration;

  ResourceItem({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.duration,
  });
}