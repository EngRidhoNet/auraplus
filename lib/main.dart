import 'package:aura_plus/features/therapy/domain/models/therapy_session.dart';
import 'package:aura_plus/features/therapy/presentation/screens/aac_therapy_screen.dart';
import 'package:aura_plus/features/therapy/presentation/screens/therapy_categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/config/credentials.dart';
import 'core/utils/logger.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: Credentials.supabaseUrl,
      anonKey: Credentials.supabaseAnonKey,
      debug: AppConfig.isDevelopment,
    );
    AppLogger.info('Supabase initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize Supabase: $e');
  }

  runApp(
    const ProviderScope(
      child: AuraPlusApp(),
    ),
  );
}

// 🌙 Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AuraPlusApp extends ConsumerWidget {
  const AuraPlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AURA+',
      themeMode: themeMode,
      
      // ✨ Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      
      // 🌙 Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFF121212),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      
      home: currentUser.when(
        data: (user) =>
            user != null ? const DashboardScreen() : const LoginScreen(),
        loading: () => const LoadingScreen(),
        error: (error, stack) => const LoginScreen(),
      ),
      debugShowCheckedModeBanner: AppConfig.isDevelopment,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading AURA+...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎨 Professional Dashboard Screen
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 🎯 Custom App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: currentUser.when(
                            data: (user) {
                              final name = user?.email?.split('@')[0] ?? 'User';
                              final capitalizedName = name[0].toUpperCase() + 
                                name.substring(1);
                              
                              return Row(
                                children: [
                                  Text(
                                    'Hello, $capitalizedName',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 28),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Text('Hello...'),
                            error: (_, __) => const Text('Hello!'),
                          ),
                        ),
                        // Theme Toggle & Profile Button
                        Row(
                          children: [
                            _buildThemeToggleButton(isDark),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              Icons.notifications_outlined,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No new notifications'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search Bar
                    _buildSearchBar(isDark),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 🎴 Featured Cards Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFeaturedCard(
                        context,
                        'Vocabulary\nTherapy',
                        '15 min',
                        const Color(0xFF2D3E50),
                        Icons.school_rounded,
                        () => _navigateToTherapy(context, SessionType.vocabulary, 'Vocabulary Therapy'),
                      ),
                      const SizedBox(width: 16),
                      _buildFeaturedCard(
                        context,
                        'Verbal\nTherapy',
                        '12 min',
                        isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        Icons.record_voice_over_rounded,
                        () => _navigateToTherapy(context, SessionType.verbal, 'Verbal Therapy'),
                        isLight: !isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 📌 Special For You Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Special for you',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        children: [
                          Text('See all'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 📋 Therapy List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTherapyListCard(
                    context,
                    'AAC Communication',
                    '5 min',
                    'Morning',
                    const Color(0xFFB8E6F0),
                    Icons.touch_app_rounded,
                    () => _navigateToAAC(context),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTherapyListCard(
                    context,
                    'Progress Report',
                    '10 min',
                    'Evening',
                    isDark ? const Color(0xFF2D2D2D) : Colors.white,
                    Icons.analytics_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                    isDark,
                    isLight: !isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTherapyListCard(
                    context,
                    'Speech Practice',
                    '8 min',
                    'Anytime',
                    const Color(0xFFFFE5B4),
                    Icons.mic_rounded,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                    isDark,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      
      // 🎯 Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(context, isDark),
    );
  }

  // ============================================================================
  // WIDGETS
  // ============================================================================

  Widget _buildThemeToggleButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: IconButton(
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: isDark ? Colors.amber : Colors.grey.shade700,
        ),
        onPressed: () {
          final currentMode = ref.read(themeModeProvider);
          ref.read(themeModeProvider.notifier).state =
              currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        },
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    String title,
    String duration,
    Color backgroundColor,
    IconData icon,
    VoidCallback onTap, {
    bool isLight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: isLight
              ? Border.all(color: Colors.grey.shade200)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isLight ? Colors.black : Colors.white,
                height: 1.2,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (isLight ? Colors.grey.shade200 : Colors.white.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLight ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7AC7E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTherapyListCard(
    BuildContext context,
    String title,
    String duration,
    String time,
    Color backgroundColor,
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    bool isLight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isLight
              ? Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight 
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isLight ? (isDark ? Colors.white70 : Colors.black87) : Colors.black87,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLight ? (isDark ? Colors.white : Colors.black) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLight
                              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          duration,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLight ? (isDark ? Colors.white70 : Colors.black87) : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLight
                              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLight ? (isDark ? Colors.white70 : Colors.black87) : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7AC7E3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              _buildNavItem(Icons.home_rounded, 'Home', true, isDark),
              _buildNavItem(Icons.play_circle_outline_rounded, 'Therapy', false, isDark),
              _buildNavItem(Icons.auto_stories_rounded, 'Resources', false, isDark),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', false, isDark, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFFB8E6F0).withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive 
                  ? const Color(0xFF4A90E2)
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? const Color(0xFF4A90E2)
                    : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // NAVIGATION METHODS
  // ============================================================================

  void _navigateToTherapy(BuildContext context, SessionType type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TherapyCategoriesScreen(
          sessionType: type,
          title: title,
        ),
      ),
    );
  }

  void _navigateToAAC(BuildContext context) async {
    final supabase = Supabase.instance.client;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await supabase
          .from('therapy_categories')
          .select()
          .eq('name', 'AAC Dasar')
          .single();

      if (context.mounted) Navigator.pop(context);

      if (response != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AACTherapyScreen(
              categoryId: response['id'] as String,
              categoryName: response['name'] as String,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      
      AppLogger.error('Error loading AAC category: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AAC category not found'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}