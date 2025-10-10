import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart'; // ✅ ADD THIS
import '../../domain/models/emotion_result.dart';
import '../../../../core/utils/logger.dart';

class EmotionDetectionService {
  ModelObjectDetection? _model;
  bool _isInitialized = false;

  final List<String> _emotionLabels = [
    "anger",
    "fear",
    "joy",
    "natural",
    "sadness",
    "surprise",
  ];

  static final EmotionDetectionService _instance =
      EmotionDetectionService._internal();

  factory EmotionDetectionService() => _instance;
  EmotionDetectionService._internal();

  bool get isInitialized => _isInitialized;
  List<String> get emotionLabels => List.unmodifiable(_emotionLabels);

  /// Initialize PyTorch model - WITH DETAILED ERROR HANDLING
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Emotion detection model already initialized');
      return;
    }

    try {
      AppLogger.info('🔄 Loading emotion detection model...');
      
      // ✅ STEP 1: Check if file exists in assets
      const modelPath = "assets/models/mobilenetv3_autism.ptl";
      AppLogger.info('📁 Model path: $modelPath');
      
      try {
        final data = await rootBundle.load(modelPath);
        AppLogger.info('✅ Model file found! Size: ${data.lengthInBytes} bytes');
      } catch (e) {
        AppLogger.error('❌ Model file NOT FOUND in assets: $e');
        throw Exception('Model file not found: $modelPath');
      }

      // ✅ STEP 2: Try loading model
      AppLogger.info('🔄 Attempting to load model...');
      
      try {
        _model = await PytorchLite.loadObjectDetectionModel(
          modelPath,
          _emotionLabels.length,
          224,
          224,
          objectDetectionModelType: ObjectDetectionModelType.yolov8,
          labelPath: null,
        );
        
        AppLogger.success('✅ Model loaded successfully!');
      } catch (e) {
        AppLogger.error('❌ Failed to load model: $e');
        AppLogger.error('Stack trace: ${StackTrace.current}');
        
        // Try alternative: load as classification model
        AppLogger.info('🔄 Trying alternative: loadClassificationModel...');
        
        try {
          _model = await PytorchLite.loadClassificationModel(
            modelPath,
            224,
            224,
            _emotionLabels.length,
          ) as ModelObjectDetection?;
          
          AppLogger.success('✅ Model loaded as classification model!');
        } catch (e2) {
          AppLogger.error('❌ Alternative also failed: $e2');
          rethrow;
        }
      }

      _isInitialized = true;
      AppLogger.success('🎉 Emotion detection model initialized!');
      AppLogger.info('📋 Labels: ${_emotionLabels.join(", ")}');
      
    } catch (e, stackTrace) {
      _isInitialized = false;
      AppLogger.error('💥 FATAL: Failed to initialize model');
      AppLogger.error('Error: $e');
      AppLogger.error('Stack: $stackTrace');
      rethrow;
    }
  }

  // ...existing code...


  /// Predict emotion from image file path
  Future<EmotionResult?> predictFromImagePath(String imagePath) async {
    if (!_isInitialized || _model == null) {
      AppLogger.error('Model not initialized');
      return null;
    }

    try {
      AppLogger.info('Predicting emotion from: $imagePath');

      // Read image bytes
      final imageBytes = await File(imagePath).readAsBytes();

      // Run prediction
      final results = await _model!.getImagePrediction(
        imageBytes,
        minimumScore: 0.1,
        iOUThreshold: 0.3,
      );

      if (results.isNotEmpty) {
        // Get detection with highest score
        var bestResult = results.first;
        for (var result in results) {
          if (result.score > bestResult.score) {
            bestResult = result;
          }
        }

        final emotionIndex = bestResult.classIndex;
        final confidence = bestResult.score;

        AppLogger.info(
          'Emotion detected: ${_emotionLabels[emotionIndex]} '
          '(confidence: ${confidence.toStringAsFixed(2)})',
        );

        return EmotionResult.fromPrediction(
          index: emotionIndex,
          score: confidence,
          labels: _emotionLabels,
        );
      }

      AppLogger.warning('No emotion detected in image');
      return null;
    } catch (e) {
      AppLogger.error('Error predicting emotion: $e');
      return null;
    }
  }

  /// Predict emotion from File object
  Future<EmotionResult?> predictFromFile(File imageFile) async {
    return predictFromImagePath(imageFile.path);
  }

  /// Predict emotion from image bytes
  Future<EmotionResult?> predictFromBytes(
    Uint8List imageBytes, {
    int? width,
    int? height,
  }) async {
    if (!_isInitialized || _model == null) {
      AppLogger.error('Model not initialized');
      return null;
    }

    try {
      final results = await _model!.getImagePrediction(
        imageBytes,
        minimumScore: 0.1,
        iOUThreshold: 0.3,
      );

      if (results.isNotEmpty) {
        var bestResult = results.first;
        for (var result in results) {
          if (result.score > bestResult.score) {
            bestResult = result;
          }
        }

        final emotionIndex = bestResult.classIndex;
        final confidence = bestResult.score;

        return EmotionResult.fromPrediction(
          index: emotionIndex,
          score: confidence,
          labels: _emotionLabels,
        );
      }

      return null;
    } catch (e) {
      AppLogger.error('Error predicting emotion from bytes: $e');
      return null;
    }
  }

  /// Predict emotion from camera image (realtime)
  Future<EmotionResult?> predictFromCameraImage(CameraImage image) async {
    if (!_isInitialized || _model == null) {
      return null;
    }

    try {
      final bytes = await _convertCameraImageToBytes(image);
      return await predictFromBytes(bytes);
    } catch (e) {
      AppLogger.error('Error predicting from camera: $e');
      return null;
    }
  }

  /// Convert CameraImage to Uint8List
  Future<Uint8List> _convertCameraImageToBytes(CameraImage image) async {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToJPEG(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToJPEG(image);
      } else {
        // Fallback
        final allBytes = <int>[];
        for (final Plane plane in image.planes) {
          allBytes.addAll(plane.bytes);
        }
        return Uint8List.fromList(allBytes);
      }
    } catch (e) {
      AppLogger.error('Error converting camera image: $e');
      rethrow;
    }
  }

  /// Convert YUV420 to bytes
  Uint8List _convertYUV420ToJPEG(CameraImage image) {
    final yPlane = image.planes[0];
    return Uint8List.fromList(yPlane.bytes);
  }

  /// Convert BGRA8888 to bytes
  Uint8List _convertBGRA8888ToJPEG(CameraImage image) {
    final bytes = image.planes[0].bytes;
    final rgbBytes = Uint8List(bytes.length ~/ 4 * 3);
    int rgbIndex = 0;

    for (int i = 0; i < bytes.length; i += 4) {
      rgbBytes[rgbIndex++] = bytes[i + 2]; // R
      rgbBytes[rgbIndex++] = bytes[i + 1]; // G
      rgbBytes[rgbIndex++] = bytes[i];     // B
    }

    return rgbBytes;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _model = null;
    _isInitialized = false;
    AppLogger.info('Emotion detection service disposed');
  }
}