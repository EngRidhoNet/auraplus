import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../../domain/models/therapy_category.dart';
import '../../domain/models/therapy_content.dart';
import '../../domain/models/therapy_session.dart';
import '../../data/services/therapy_service.dart';

// Service Provider
final therapyServiceProvider = Provider<TherapyService>((ref) {
  return TherapyService();
});

// Categories Provider
final therapyCategoriesProvider = FutureProvider<List<TherapyCategory>>((ref) {
  final therapyService = ref.watch(therapyServiceProvider);
  return therapyService.getTherapyCategories();
});

// Content Provider (filtered by category)
final therapyContentProvider = FutureProvider.family<List<TherapyContent>, String>((ref, categoryId) {
  final therapyService = ref.watch(therapyServiceProvider);
  return therapyService.getTherapyContent(categoryId: categoryId);
});

// Current Session Provider
final currentSessionProvider = StateNotifierProvider<CurrentSessionNotifier, AsyncValue<TherapySession?>>((ref) {
  final therapyService = ref.watch(therapyServiceProvider);
  return CurrentSessionNotifier(therapyService);
});

// User Sessions Provider
final userSessionsProvider = FutureProvider.family<List<TherapySession>, String>((ref, userId) {
  final therapyService = ref.watch(therapyServiceProvider);
  return therapyService.getUserTherapySessions(userId);
});

// User Stats Provider
final userStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  final therapyService = ref.watch(therapyServiceProvider);
  return therapyService.getUserStats(userId);
});

class CurrentSessionNotifier extends StateNotifier<AsyncValue<TherapySession?>> {
  final TherapyService _therapyService;
  
  CurrentSessionNotifier(this._therapyService) : super(const AsyncValue.data(null));
  
  Future<void> startSession({
    required String userId,
    required String categoryId,
    required SessionType sessionType,
    int totalItems = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _therapyService.createTherapySession(
        userId: userId,
        categoryId: categoryId,
        sessionType: sessionType,
        totalItems: totalItems,
      );
      state = AsyncValue.data(session);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    try {
      final updatedSession = await _therapyService.updateTherapySession(sessionId, updates);
      state = AsyncValue.data(updatedSession);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> completeSession({
    required String sessionId,
    required int completedItems,
    required int correctAnswers,
    required double score,
    required int durationSeconds,
  }) async {
    try {
      final completedSession = await _therapyService.completeTherapySession(
        sessionId: sessionId,
        completedItems: completedItems,
        correctAnswers: correctAnswers,
        score: score,
        durationSeconds: durationSeconds,
      );
      state = AsyncValue.data(completedSession);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
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
      await _therapyService.recordProgress(
        sessionId: sessionId,
        contentId: contentId,
        userId: userId,
        isCorrect: isCorrect,
        responseTimeMs: responseTimeMs,
        userResponse: userResponse,
        confidenceScore: confidenceScore,
      );
    } catch (e) {
      // Log error but don't update state for progress recording
      // TODO: Use proper logging framework
      debugPrint('Failed to record progress: $e');
      print('Failed to record progress: $e');
    }
  }
  
  void clearSession() {
    state = const AsyncValue.data(null);
  }
}