import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import 'core/config/app_config.dart';
import 'core/config/credentials.dart';
import 'core/utils/logger.dart';

// Features - Auth
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// Features - Dashboard - ✅ CORRECT IMPORT
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

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
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AURA+',
      themeMode: themeMode,
      
      // ✨ Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A),
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
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      
      // 🌙 Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A),
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
      
      debugShowCheckedModeBanner: AppConfig.isDevelopment,
      
      // ✅ HOME SCREEN - FIXED WITH CORRECT CLASS NAME
      home: authState.when(
        data: (_) {
          // Check if user is authenticated
          final user = Supabase.instance.client.auth.currentUser;
          return user == null 
              ? const LoginScreen()  
              : const DashboardScreen(); // ✅ CORRECT CLASS NAME
        },
        loading: () => const LoadingScreen(),
        error: (error, stack) {
          AppLogger.error('Auth error: $error');
          return ErrorScreen(
            message: 'Failed to authenticate. Please try again.',
            onRetry: () {
              ref.refresh(authStateProvider);
            },
          );
        },
      ),
    );
  }
}

// ⏳ Loading Screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF66BB6A),
                            Color(0xFF43A047),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF66BB6A).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Loading AURA+...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark 
                    ? Colors.grey.shade400 
                    : Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Preparing your therapy session',
              style: TextStyle(
                fontSize: 13,
                color: isDark 
                    ? Colors.grey.shade600 
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ❌ Error Screen
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}