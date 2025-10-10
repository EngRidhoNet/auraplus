import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/services/emotion_detection_service.dart';
import '../../domain/models/emotion_result.dart';
import '../../../../core/utils/logger.dart';

// Service provider
final emotionDetectionServiceProvider = Provider<EmotionDetectionService>((ref) {
  return EmotionDetectionService();
});

// Initialization state provider
final emotionModelInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(emotionDetectionServiceProvider);
  try {
    await service.initialize();
    return true;
  } catch (e) {
    AppLogger.error('Failed to initialize emotion model: $e');
    return false;
  }
});

// Current emotion result provider
final currentEmotionProvider = StateProvider<EmotionResult?>((ref) => null);

// Emotion detection history provider
final emotionHistoryProvider = StateProvider<List<EmotionResult>>((ref) => []);

// Camera controller provider
final cameraControllerProvider = StateProvider<CameraController?>((ref) => null);

// Detection state provider
class EmotionDetectionState {
  final bool isDetecting;
  final bool isCameraReady;
  final String? errorMessage;

  EmotionDetectionState({
    this.isDetecting = false,
    this.isCameraReady = false,
    this.errorMessage,
  });

  EmotionDetectionState copyWith({
    bool? isDetecting,
    bool? isCameraReady,
    String? errorMessage,
  }) {
    return EmotionDetectionState(
      isDetecting: isDetecting ?? this.isDetecting,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final emotionDetectionStateProvider = 
    StateProvider<EmotionDetectionState>((ref) => EmotionDetectionState());

// Detection action provider
final emotionDetectionNotifierProvider = 
    Provider<EmotionDetectionNotifier>((ref) {
  return EmotionDetectionNotifier(ref);
});

class EmotionDetectionNotifier {
  final Ref _ref;

  EmotionDetectionNotifier(this._ref);

  /// Detect emotion from image path
  Future<void> detectFromImagePath(String imagePath) async {
    final service = _ref.read(emotionDetectionServiceProvider);
    
    _ref.read(emotionDetectionStateProvider.notifier).state = 
        _ref.read(emotionDetectionStateProvider).copyWith(isDetecting: true);

    try {
      final result = await service.predictFromImagePath(imagePath);
      
      if (result != null) {
        // Update current emotion
        _ref.read(currentEmotionProvider.notifier).state = result;
        
        // Add to history
        final history = _ref.read(emotionHistoryProvider);
        _ref.read(emotionHistoryProvider.notifier).state = [
          result,
          ...history,
        ].take(10).toList(); // Keep last 10 results
      }
    } catch (e) {
      _ref.read(emotionDetectionStateProvider.notifier).state = 
          _ref.read(emotionDetectionStateProvider).copyWith(
            errorMessage: 'Detection failed: $e',
          );
    } finally {
      _ref.read(emotionDetectionStateProvider.notifier).state = 
          _ref.read(emotionDetectionStateProvider).copyWith(isDetecting: false);
    }
  }

  /// Clear current detection
  void clearDetection() {
    _ref.read(currentEmotionProvider.notifier).state = null;
  }

  /// Clear history
  void clearHistory() {
    _ref.read(emotionHistoryProvider.notifier).state = [];
  }
}