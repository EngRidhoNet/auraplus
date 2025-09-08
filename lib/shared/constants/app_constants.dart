class AppConstants {
  // Database Tables
  static const String userProfilesTable = 'user_profiles';
  static const String therapySessionsTable = 'therapy_sessions';
  static const String progressDataTable = 'progress_data';
  static const String therapyActivitiesTable = 'therapy_activities';
  
  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String audioFilesBucket = 'audio_files';
  static const String therapyContentBucket = 'therapy_content';
  
  // Therapy Types
  static const String vocabularyTherapy = 'vocabulary';
  static const String verbalTherapy = 'verbal';
  static const String aacTherapy = 'aac';
  
  // User Roles
  static const String childRole = 'child';
  static const String parentRole = 'parent';
  static const String therapistRole = 'therapist';
  
  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String lastLoginKey = 'last_login';
  static const String settingsKey = 'app_settings';
}