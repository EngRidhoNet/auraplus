import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../utils/logger.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Authentication stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Sign up with email
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role.name,
          'display_name': displayName ?? email.split('@').first,
        },
      );
      
      AppLogger.success('User signed up successfully');
      return response;
    } catch (e) {
      AppLogger.error('Sign up failed: $e');
      rethrow;
    }
  }
  
  // Sign in with email
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      AppLogger.success('User signed in successfully');
      return response;
    } catch (e) {
      AppLogger.error('Sign in failed: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      AppLogger.success('User signed out successfully');
    } catch (e) {
      AppLogger.error('Sign out failed: $e');
      rethrow;
    }
  }
  
  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get user profile: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', userId);
      
      AppLogger.success('User profile updated successfully');
    } catch (e) {
      AppLogger.error('Failed to update user profile: $e');
      rethrow;
    }
  }
}