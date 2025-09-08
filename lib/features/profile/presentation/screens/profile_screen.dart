import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon!')),
              );
            },
          ),
        ],
      ),
      body: userProfile.when(
        data: (profile) => profile != null 
            ? _buildProfileContent(context, profile, ref)
            : _buildEmptyProfile(context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorContent(context, error.toString()),
      ),
    );
  }
  
  Widget _buildProfileContent(BuildContext context, UserModel profile, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade200,
                  backgroundImage: profile.avatarUrl != null 
                      ? NetworkImage(profile.avatarUrl!) 
                      : null,
                  child: profile.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.blue.shade600,
                        )
                      : null,
                ),
                
                const SizedBox(height: 16),
                
                // Name
                Text(
                  profile.displayName ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(profile.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getRoleColor(profile.role)),
                  ),
                  child: Text(
                    profile.role.displayName.toUpperCase(),
                    style: TextStyle(
                      color: _getRoleColor(profile.role),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile Details
          _buildDetailCard('Personal Information', [
            _buildDetailRow('Email', profile.email),
            if (profile.firstName != null)
              _buildDetailRow('First Name', profile.firstName!),
            if (profile.lastName != null)
              _buildDetailRow('Last Name', profile.lastName!),
            if (profile.age != null)
              _buildDetailRow('Age', '${profile.age} years old'),
            if (profile.gender != null)
              _buildDetailRow('Gender', profile.gender!),
          ]),
          
          const SizedBox(height: 16),
          
          // Account Information
          _buildDetailCard('Account Information', [
            _buildDetailRow('Role', profile.role.displayName),
            if (profile.createdAt != null)
              _buildDetailRow('Member Since', 
                  '${profile.createdAt!.day}/${profile.createdAt!.month}/${profile.createdAt!.year}'),
          ]),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }
  
  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon!')),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyProfile(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No profile found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorContent(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.child:
        return Colors.green;
      case UserRole.parent:
        return Colors.blue;
      case UserRole.therapist:
        return Colors.purple;
    }
  }
}