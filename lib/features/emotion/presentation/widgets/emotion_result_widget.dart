import 'package:flutter/material.dart';
import '../../domain/models/emotion_result.dart';

class EmotionResultWidget extends StatelessWidget {
  final EmotionResult result;
  final bool isDark;

  const EmotionResultWidget({
    super.key,
    required this.result,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: result.getEmotionColor().withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emotion icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: result.getEmotionColor().withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.getEmotionIcon(),
              size: 60,
              color: result.getEmotionColor(),
            ),
          ),

          const SizedBox(height: 20),

          // Emotion label
          Text(
            result.emotion.toUpperCase(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: result.getEmotionColor(),
            ),
          ),

          const SizedBox(height: 12),

          // Confidence bar
          _buildConfidenceBar(),

          const SizedBox(height: 8),

          // Confidence percentage
          Text(
            '${(result.confidence * 100).toStringAsFixed(1)}% Confidence',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar() {
    return Container(
      width: double.infinity,
      height: 12,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: result.confidence,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                result.getEmotionColor(),
                result.getEmotionColor().withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}