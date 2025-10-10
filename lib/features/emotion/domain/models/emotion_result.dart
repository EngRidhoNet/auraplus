import 'package:flutter/material.dart'; // ✅ ADD THIS

class EmotionResult {
  final String emotion;
  final double confidence;
  final int classIndex;
  final DateTime timestamp;

  const EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.classIndex,
    required this.timestamp,
  });

  factory EmotionResult.fromPrediction({
    required int index,
    required double score,
    required List<String> labels,
  }) {
    return EmotionResult(
      emotion: labels[index],
      confidence: score,
      classIndex: index,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'emotion': emotion,
        'confidence': confidence,
        'class_index': classIndex,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Get color for emotion
  Color getEmotionColor() {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return const Color(0xFFFFD700); // Gold
      case 'anger':
        return const Color(0xFFFF5252); // Red
      case 'sadness':
        return const Color(0xFF2196F3); // Blue
      case 'fear':
        return const Color(0xFF9C27B0); // Purple
      case 'surprise':
        return const Color(0xFFFF9800); // Orange
      case 'natural':
      default:
        return const Color(0xFF66BB6A); // Green
    }
  }

  /// Get icon for emotion
  IconData getEmotionIcon() {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return Icons.sentiment_very_satisfied_rounded;
      case 'anger':
        return Icons.sentiment_very_dissatisfied_rounded;
      case 'sadness':
        return Icons.sentiment_dissatisfied_rounded;
      case 'fear':
        return Icons.sentiment_neutral_rounded;
      case 'surprise':
        return Icons.sentiment_satisfied_rounded;
      case 'natural':
      default:
        return Icons.face_rounded;
    }
  }

  /// Get description for emotion (Indonesian)
  String getEmotionDescription() {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return 'Menunjukkan kebahagiaan dan kepuasan';
      case 'anger':
        return 'Menunjukkan kemarahan atau frustrasi';
      case 'sadness':
        return 'Menunjukkan kesedihan atau kekecewaan';
      case 'fear':
        return 'Menunjukkan ketakutan atau kekhawatiran';
      case 'surprise':
        return 'Menunjukkan keterkejutan atau kekaguman';
      case 'natural':
        return 'Ekspresi netral tanpa emosi khusus';
      default:
        return 'Emosi tidak dikenali';
    }
  }
}