import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AppLogger {
  static void info(String message) {
    if (AppConfig.enableLogging) {
      debugPrint('ℹ️ [INFO] $message');
    }
  }
  
  static void error(String message) {
    if (AppConfig.enableLogging) {
      debugPrint('❌ [ERROR] $message');
    }
  }
  
  static void warning(String message) {
    if (AppConfig.enableLogging) {
      debugPrint('⚠️ [WARNING] $message');
    }
  }
  
  static void debug(String message) {
    if (AppConfig.enableLogging && AppConfig.isDevelopment) {
      debugPrint('🐛 [DEBUG] $message');
    }
  }
  
  static void success(String message) {
    if (AppConfig.enableLogging) {
      debugPrint('✅ [SUCCESS] $message');
    }
  }
}