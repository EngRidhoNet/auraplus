import 'package:aura_plus/features/therapy/domain/models/therapy_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'progress_report_screen.dart';

// ✅ CORRECT IMPORTS
import '../../../therapy/presentation/screens/therapy_categories_screen.dart';
import '../../../therapy/presentation/screens/verbal_therapy_screen.dart';
import '../../../therapy/presentation/screens/aac_therapy_screen.dart';

/// Therapy List Screen - Shows all available therapies
class TherapyListScreen extends ConsumerWidget {
  const TherapyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
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
                      Icons.psychology_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'All Therapies',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

          // Info Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF66BB6A).withOpacity(0.15),
                    const Color(0xFF43A047).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF66BB6A).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Color(0xFF66BB6A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Therapy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select therapy that fits your needs',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Therapy Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ✅ VOCABULARY THERAPY
                _buildTherapyCard(
                  context,
                  'Vocabulary Therapy',
                  'Learn new words with interactive AR technology',
                  Icons.school_rounded,
                  const Color(0xFF66BB6A),
                  isDark,
                  '48 Activities',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TherapyCategoriesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // ✅ VERBAL THERAPY - FIXED WITH CORRECT MODEL
                _buildTherapyCard(
                  context,
                  'Verbal Therapy',
                  'Practice pronunciation and speaking skills',
                  Icons.record_voice_over_rounded,
                  const Color(0xFFFF9800),
                  isDark,
                  '32 Exercises',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerbalTherapyScreen(
                          categoryName: 'Verbal Therapy',
                          content: TherapyContent(
                            id: 'verbal_therapy_intro',
                            categoryId: 'verbal',
                            title: 'Verbal Therapy Session',
                            description: 'Practice your pronunciation and speaking skills with interactive exercises designed to improve your verbal communication. Focus on clear articulation, proper stress patterns, and natural intonation.',
                            contentType: ContentType.word,
                            difficultyLevel: 2,
                            targetWord: 'Hello',
                            pronunciation: '/həˈloʊ/',
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
                const SizedBox(height: 16),
                
                // ✅ AAC COMMUNICATION
                _buildTherapyCard(
                  context,
                  'AAC Communication',
                  'Symbol-based communication tools',
                  Icons.touch_app_rounded,
                  const Color(0xFF9C27B0),
                  isDark,
                  '120 Symbols',
                  () {
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
                const SizedBox(height: 16),
                
                // ✅ PROGRESS REPORT
                _buildTherapyCard(
                  context,
                  'Progress Report',
                  'Track your therapy progress and achievements',
                  Icons.analytics_rounded,
                  const Color(0xFF4A90E2),
                  isDark,
                  'View Stats',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgressReportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapyCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    bool isDark,
    String badge,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, size: 36, color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  badge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 24,
                        color: color,
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
}