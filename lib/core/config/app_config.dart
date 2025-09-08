class AppConfig {
  // Supabase Configuration - Dari environment atau fallback ke placeholders
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'PLEASE_SET_SUPABASE_URL', // Placeholder, bukan credentials asli
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY', 
    defaultValue: 'PLEASE_SET_SUPABASE_ANON_KEY', // Placeholder, bukan credentials asli
  );
  
  // AR Configuration
  static const bool enableARDebug = true;
  static const double arPlaneDetectionSensitivity = 0.8;
  static const int maxARObjects = 5;
  
  // AI Configuration
  static const String aiModelPath = 'assets/models/ai/therapy_recommendation_model.tflite';
  static const double aiConfidenceThreshold = 0.7;
  static const int maxRecommendations = 3;
  
  // Therapy Configuration
  static const int maxSessionDuration = 30; // minutes
  static const int minAccuracyForProgression = 70; // percentage
  static const int maxDailySessionsChild = 3;
  
  // App Settings
  static const String appVersion = '1.0.0';
  static const bool enableAnalytics = false; // Privacy first for medical app
  static const Duration sessionTimeout = Duration(minutes: 15);
  
  // Environment
  static const bool isDevelopment = bool.fromEnvironment(
    'DEBUG_MODE', 
    defaultValue: true,
  );
  static const bool enableLogging = isDevelopment;
}