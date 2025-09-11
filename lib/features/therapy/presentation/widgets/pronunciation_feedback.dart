import 'package:flutter/material.dart';

class PronunciationFeedback extends StatelessWidget {
  final String targetWord;
  final String recognizedText;
  final double confidence;
  final VoidCallback? onTryAgain;
  
  const PronunciationFeedback({
    super.key,
    required this.targetWord,
    required this.recognizedText,
    required this.confidence,
    this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = recognizedText.toLowerCase() == targetWord.toLowerCase();
    final isClose = _calculateSimilarity(targetWord, recognizedText) > 0.7;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getFeedbackColor(isCorrect, isClose).withOpacity(0.2),
            _getFeedbackColor(isCorrect, isClose).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getFeedbackColor(isCorrect, isClose),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Feedback icon
          Icon(
            _getFeedbackIcon(isCorrect, isClose),
            size: 48,
            color: _getFeedbackColor(isCorrect, isClose),
          ),
          
          const SizedBox(height: 16),
          
          // Feedback message
          Text(
            _getFeedbackMessage(isCorrect, isClose),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getFeedbackColor(isCorrect, isClose),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Recognition details
          _buildRecognitionDetails(),
          
          const SizedBox(height: 16),
          
          // Suggestions
          if (!isCorrect) _buildSuggestions(),
          
          // Action button
          if (!isCorrect && onTryAgain != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTryAgain,
              icon: const Icon(Icons.mic),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecognitionDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'You said:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '"$recognizedText"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Confidence:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${(confidence * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConfidenceColor(confidence),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _generateSuggestions();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.yellow, size: 16),
              SizedBox(width: 8),
              Text(
                'Pronunciation Tips:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $suggestion',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getFeedbackColor(bool isCorrect, bool isClose) {
    if (isCorrect) return Colors.green;
    if (isClose) return Colors.orange;
    return Colors.red;
  }

  IconData _getFeedbackIcon(bool isCorrect, bool isClose) {
    if (isCorrect) return Icons.check_circle;
    if (isClose) return Icons.info;
    return Icons.error;
  }

  String _getFeedbackMessage(bool isCorrect, bool isClose) {
    if (isCorrect) return 'Perfect! Well done! 🎉';
    if (isClose) return 'Close! Try again 👍';
    return 'Not quite right. Let\'s try again! 🔄';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  double _calculateSimilarity(String target, String recognized) {
    // Simple similarity calculation - in real app, use more sophisticated algorithm
    final targetLower = target.toLowerCase();
    final recognizedLower = recognized.toLowerCase();
    
    if (targetLower == recognizedLower) return 1.0;
    
    // Calculate Levenshtein-like similarity
    final maxLength = [targetLower.length, recognizedLower.length].reduce((a, b) => a > b ? a : b);
    final minLength = [targetLower.length, recognizedLower.length].reduce((a, b) => a < b ? a : b);
    
    int matches = 0;
    for (int i = 0; i < minLength; i++) {
      if (targetLower[i] == recognizedLower[i]) {
        matches++;
      }
    }
    
    return matches / maxLength;
  }

  List<String> _generateSuggestions() {
    final suggestions = <String>[];
    
    // Analyze differences and provide specific tips
    if (recognizedText.length < targetWord.length) {
      suggestions.add('Try to pronounce all syllables clearly');
    }
    
    if (recognizedText.length > targetWord.length) {
      suggestions.add('Speak more concisely, avoid extra sounds');
    }
    
    if (confidence < 0.6) {
      suggestions.add('Speak louder and more clearly');
      suggestions.add('Make sure you\'re in a quiet environment');
    }
    
    // Word-specific tips
    switch (targetWord.toLowerCase()) {
      case 'cat':
        suggestions.add('Emphasize the "ca" sound and end with a sharp "t"');
        break;
      case 'dog':
        suggestions.add('Start with a strong "d" and round your lips for "og"');
        break;
      case 'water':
        suggestions.add('Break it down: "wa-ter", emphasize both syllables');
        break;
      default:
        suggestions.add('Practice saying each syllable slowly first');
    }
    
    suggestions.add('Listen to the example pronunciation');
    
    return suggestions.take(3).toList();
  }
}