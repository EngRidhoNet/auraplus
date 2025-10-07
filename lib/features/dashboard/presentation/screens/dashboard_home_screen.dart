import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/feature_card.dart';
import 'progress_report_screen.dart';

// ✅ CORRECT THERAPY SCREEN IMPORTS
import '../../../therapy/presentation/screens/therapy_categories_screen.dart';
import '../../../therapy/presentation/screens/verbal_therapy_screen.dart';
import '../../../therapy/presentation/screens/aac_therapy_screen.dart';
import 'package:aura_plus/features/therapy/domain/models/therapy_content.dart';

/// Dashboard Home Screen - Main home view with feature cards
class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with user greeting & stats
          const SliverToBoxAdapter(
            child: DashboardHeader(),
          ),

          // ✅ SEARCH BAR - INLINE (No separate widget file needed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1E1E1E) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search therapies...',
                    hintStyle: TextStyle(
                      color: isDark 
                          ? Colors.grey.shade600 
                          : Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark 
                          ? Colors.grey.shade600 
                          : Colors.grey.shade400,
                    ),
                    suffixIcon: Icon(
                      Icons.tune_rounded,
                      color: isDark 
                          ? Colors.grey.shade600 
                          : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Therapy Programs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Feature Cards Grid (2 columns)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                // ✅ VOCABULARY CARD
                FeatureCard(
                  title: 'Vocabulary',
                  description: 'Learn words with AR',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF66BB6A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TherapyCategoriesScreen(),
                      ),
                    );
                  },
                ),

                // ✅ VERBAL CARD - FIXED
                FeatureCard(
                  title: 'Verbal',
                  description: 'Practice speaking',
                  icon: Icons.record_voice_over_rounded,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerbalTherapyScreen(
                          categoryName: 'Verbal Therapy',
                          content: TherapyContent(
                            id: 'verbal_quick_start',
                            categoryId: 'verbal',
                            title: 'Quick Start Verbal Practice',
                            description: 'Begin your verbal therapy journey with basic pronunciation exercises',
                            contentType: ContentType.word,
                            difficultyLevel: 1,
                            targetWord: 'Welcome',
                            pronunciation: '/ˈwelkəm/',
                            imageUrl: null,
                            audioUrl: null,
                            model3dUrl: null,
                            arPlacementData: null,
                            isActive: true,
                            createdAt: DateTime.now(),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ✅ AAC CARD
                FeatureCard(
                  title: 'AAC Tools',
                  description: 'Communication aids',
                  icon: Icons.touch_app_rounded,
                  color: const Color(0xFF9C27B0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AACTherapyScreen(
                          categoryId: 'aac',
                          categoryName: 'AAC Communication',
                        ),
                      ),
                    );
                  },
                ),

                // ✅ PROGRESS CARD
                FeatureCard(
                  title: 'Progress',
                  description: 'Track your growth',
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF4A90E2),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgressReportScreen(),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),

          // Bottom spacing for bottom nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}