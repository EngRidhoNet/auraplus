import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';

class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTab = ref.watch(dashboardTabProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                ref,
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
                0,
                currentTab == 0,
                isDark,
              ),
              _buildNavItem(
                context,
                ref,
                Icons.play_circle_outline,
                Icons.play_circle_rounded,
                'Therapy',
                1,
                currentTab == 1,
                isDark,
              ),
              _buildNavItem(
                context,
                ref,
                Icons.auto_stories_outlined,
                Icons.auto_stories_rounded,
                'Resources',
                2,
                currentTab == 2,
                isDark,
              ),
              _buildNavItem(
                context,
                ref,
                Icons.person_outline,
                Icons.person_rounded,
                'Profile',
                3,
                currentTab == 3,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
    int index,
    bool isActive,
    bool isDark,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(dashboardTabProvider.notifier).state = index;
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF66BB6A).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? iconFilled : iconOutlined,
                    size: 26,
                    color: isActive
                        ? const Color(0xFF66BB6A)
                        : (isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF66BB6A)
                        : (isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600),
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}