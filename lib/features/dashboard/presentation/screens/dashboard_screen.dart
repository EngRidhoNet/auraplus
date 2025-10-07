import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard_home_screen.dart';
import 'therapy_list_screen.dart';
import 'resources_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Main Dashboard Container
/// Manages tab navigation and displays current screen
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(dashboardTabProvider);

    // All screens for tabs
    final screens = [
      const DashboardHomeScreen(),  // Tab 0: Home
      const TherapyListScreen(),     // Tab 1: Therapy
      const ResourcesScreen(),       // Tab 2: Resources
      const ProfileScreen(),         // Tab 3: Profile
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}