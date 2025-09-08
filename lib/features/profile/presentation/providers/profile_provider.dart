import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart'; // Add this import
import '../../../../core/services/profile_service.dart';

// Profile Service Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// Current User Profile Provider
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  return currentUser.when(
    data: (user) async {
      if (user != null) {
        return await profileService.getProfile(user.id);
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Profile State Provider for updates
final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, AsyncValue<UserModel?>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileStateNotifier(profileService);
});

// Children Profiles Provider (for parents)
final childrenProfilesProvider = FutureProvider.family<List<UserModel>, String>((ref, parentId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getChildrenProfiles(parentId);
});

class ProfileStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ProfileService _profileService;
  
  ProfileStateNotifier(this._profileService) : super(const AsyncValue.data(null));
  
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final updatedProfile = await _profileService.updateProfile(userId, updates);
      state = AsyncValue.data(updatedProfile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> linkChild(String childId, String parentId) async {
    state = const AsyncValue.loading();
    try {
      await _profileService.linkChildToParent(childId, parentId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<UserModel?> searchUser(String email) async {
    try {
      return await _profileService.searchUserByEmail(email);
    } catch (e) {
      return null;
    }
  }
}