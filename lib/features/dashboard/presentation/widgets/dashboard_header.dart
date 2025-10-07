import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gotrue/src/types/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) => Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)]
                : [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Profile Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF66BB6A).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: user?.photoUrl != null
                        ? Image.network(
                            user!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(user?.displayName ?? 'U');
                            },
                          )
                        : _buildDefaultAvatar(user?.displayName ?? 'U'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.local_fire_department_rounded,
                    '12',
                    'Day Streak',
                    const Color(0xFFFF9800),
                    isDark,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                  _buildStatItem(
                    Icons.emoji_events_rounded,
                    '48',
                    'Completed',
                    const Color(0xFF66BB6A),
                    isDark,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                  _buildStatItem(
                    Icons.schedule_rounded,
                    '2.5h',
                    'This Week',
                    const Color(0xFF4A90E2),
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => _buildLoadingSkeleton(isDark),
      error: (error, stack) => _buildErrorState(isDark),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: const Center(
        child: Text('Error loading user data'),
      ),
    );
  }
}

extension on User? {
  get displayName => null;
  
  get photoUrl => null;
}