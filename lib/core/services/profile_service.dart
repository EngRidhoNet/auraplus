import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../utils/logger.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get user profile by ID
  Future<UserModel?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      
      AppLogger.success('Profile loaded successfully');
      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get profile: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<UserModel?> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      
      AppLogger.success('Profile updated successfully');
      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to update profile: $e');
      rethrow;
    }
  }
  
  // Get children profiles (for parents)
  Future<List<UserModel>> getChildrenProfiles(String parentId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('parent_id', parentId)
          .eq('role', 'child');
      
      AppLogger.success('Children profiles loaded');
      return (response as List)
          .map((child) => UserModel.fromJson(child))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get children profiles: $e');
      return [];
    }
  }
  
  // Link child to parent
  Future<void> linkChildToParent(String childId, String parentId) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'parent_id': parentId, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', childId);
      
      AppLogger.success('Child linked to parent successfully');
    } catch (e) {
      AppLogger.error('Failed to link child to parent: $e');
      rethrow;
    }
  }
  
  // Search users by email (for linking)
  Future<UserModel?> searchUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('email', email)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.warning('User not found: $email');
      return null;
    }
  }
  
  // Upload avatar
  Future<String?> uploadAvatar(String userId, String filePath) async {
    try {
      final file = await _supabase.storage
          .from('avatars')
          .upload('$userId/avatar.jpg', filePath);
      
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl('$userId/avatar.jpg');
      
      AppLogger.success('Avatar uploaded successfully');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Failed to upload avatar: $e');
      return null;
    }
  }
}