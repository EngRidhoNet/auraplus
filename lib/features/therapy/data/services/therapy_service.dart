import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/therapy_category.dart';
import '../../domain/models/therapy_content.dart';
import '../../domain/models/therapy_session.dart';
import '../../../../core/utils/logger.dart';

class TherapyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // ========== THERAPY CATEGORIES ==========
  
  Future<List<TherapyCategory>> getTherapyCategories() async {
    try {
      final response = await _supabase
          .from('therapy_categories')
          .select()
          .eq('is_active', true)
          .order('name');
      
      AppLogger.success('Therapy categories loaded: ${response.length} items');
      return (response as List)
          .map((category) => TherapyCategory.fromJson(category))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get therapy categories: $e');
      return [];
    }
  }
  
  // ========== THERAPY CONTENT ==========
  
Future<List<TherapyContent>> getTherapyContent({
  String? categoryId,
  int? difficultyLevel,
  ContentType? contentType,
}) async {
  try {
    print('🔍 Getting therapy content for categoryId: $categoryId');
    
    var query = _supabase
        .from('therapy_content')
        .select()
        .eq('is_active', true);
    
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
      print('🔍 Filtering by category_id: $categoryId');
    }
    
    if (difficultyLevel != null) {
      query = query.eq('difficulty_level', difficultyLevel);
    }
    
    if (contentType != null) {
      query = query.eq('content_type', contentType.name);
    }
    
    print('🔍 About to execute query...');
    
    // Add timeout to prevent hanging
    final response = await query
        .order('difficulty_level')
        .timeout(const Duration(seconds: 10));
    
    print('🔍 Raw response: $response');
    print('🔍 Response type: ${response.runtimeType}');
    print('🔍 Response length: ${response.length}');
    
    if (response.isEmpty) {
      print('⚠️ No content found for categoryId: $categoryId');
      return [];
    }
    
    final contentList = (response as List)
        .map((content) {
          print('🔍 Processing content: $content');
          try {
            return TherapyContent.fromJson(content);
          } catch (e) {
            print('❌ Error parsing content: $e');
            print('❌ Content data: $content');
            rethrow;
          }
        })
        .toList();
    
    AppLogger.success('Therapy content loaded: ${contentList.length} items');
    return contentList;
  } catch (e, stackTrace) {
    print('❌ Error in getTherapyContent: $e');
    print('❌ Stack trace: $stackTrace');
    AppLogger.error('Failed to get therapy content: $e');
    return [];
  }
}
  
  Future<TherapyContent?> getTherapyContentById(String contentId) async {
    try {
      final response = await _supabase
          .from('therapy_content')
          .select()
          .eq('id', contentId)
          .single();
      
      return TherapyContent.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get therapy content by ID: $e');
      return null;
    }
  }
  
  // ========== THERAPY SESSIONS ==========
  
  Future<TherapySession?> createTherapySession({
    required String userId,
    required String categoryId,
    required SessionType sessionType,
    int totalItems = 0,
  }) async {
    try {
      final sessionData = {
        'user_id': userId,
        'category_id': categoryId,
        'session_type': sessionType.name,
        'status': SessionStatus.started.name,
        'total_items': totalItems,
        'started_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from('therapy_sessions')
          .insert(sessionData)
          .select()
          .single();
      
      AppLogger.success('Therapy session created successfully');
      return TherapySession.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to create therapy session: $e');
      rethrow;
    }
  }
  
  Future<TherapySession?> updateTherapySession(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('therapy_sessions')
          .update(updates)
          .eq('id', sessionId)
          .select()
          .single();
      
      AppLogger.success('Therapy session updated successfully');
      return TherapySession.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to update therapy session: $e');
      rethrow;
    }
  }
  
  Future<TherapySession?> completeTherapySession({
    required String sessionId,
    required int completedItems,
    required int correctAnswers,
    required double score,
    required int durationSeconds,
  }) async {
    try {
      final updates = {
        'status': SessionStatus.completed.name,
        'completed_items': completedItems,
        'correct_answers': correctAnswers,
        'score': score,
        'duration_seconds': durationSeconds,
        'completed_at': DateTime.now().toIso8601String(),
      };
      
      return await updateTherapySession(sessionId, updates);
    } catch (e) {
      AppLogger.error('Failed to complete therapy session: $e');
      rethrow;
    }
  }
  
  Future<List<TherapySession>> getUserTherapySessions(String userId) async {
    try {
      final response = await _supabase
          .from('therapy_sessions')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false);
      
      AppLogger.success('User therapy sessions loaded: ${response.length} items');
      return (response as List)
          .map((session) => TherapySession.fromJson(session))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get user therapy sessions: $e');
      return [];
    }
  }
  
  // ========== PROGRESS TRACKING ==========
  
  Future<void> recordProgress({
    required String sessionId,
    required String contentId,
    required String userId,
    required bool isCorrect,
    int? responseTimeMs,
    String? userResponse,
    double? confidenceScore,
  }) async {
    try {
      final progressData = {
        'session_id': sessionId,
        'content_id': contentId,
        'user_id': userId,
        'is_correct': isCorrect,
        'response_time_ms': responseTimeMs,
        'user_response': userResponse,
        'confidence_score': confidenceScore,
      };
      
      await _supabase.from('therapy_progress').insert(progressData);
      AppLogger.success('Progress recorded successfully');
    } catch (e) {
      AppLogger.error('Failed to record progress: $e');
      rethrow;
    }
  }
  
  // ========== ANALYTICS ==========
  
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get total sessions
      final sessionsResponse = await _supabase
          .from('therapy_sessions')
          .select('id, status, score, duration_seconds')
          .eq('user_id', userId);
      
      final sessions = sessionsResponse as List;
      final totalSessions = sessions.length;
      final completedSessions = sessions.where((s) => s['status'] == 'completed').length;
      final averageScore = sessions.isNotEmpty
          ? sessions.map((s) => s['score'] ?? 0.0).reduce((a, b) => a + b) / sessions.length
          : 0.0;
      final totalTime = sessions.fold<int>(0, (sum, s) => sum + ((s['duration_seconds'] ?? 0) as num).toInt());
      
      AppLogger.success('User stats calculated successfully');
      return {
        'total_sessions': totalSessions,
        'completed_sessions': completedSessions,
        'average_score': averageScore,
        'total_time_seconds': totalTime,
      };
    } catch (e) {
      AppLogger.error('Failed to get user stats: $e');
      return {
        'total_sessions': 0,
        'completed_sessions': 0,
        'average_score': 0.0,
        'total_time_seconds': 0,
      };
    }
  }
}