import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/therapy_content.dart';
import '../widgets/speech_wave_visualizer.dart';
import '../widgets/pronunciation_feedback.dart';

class VerbalTherapyScreen extends StatefulWidget {
  final TherapyContent content;
  final VoidCallback? onComplete;
  
  const VerbalTherapyScreen({
    super.key,
    required this.content,
    this.onComplete,
  });

  @override
  State<VerbalTherapyScreen> createState() => _VerbalTherapyScreenState();
}

class _VerbalTherapyScreenState extends State<VerbalTherapyScreen>
    with TickerProviderStateMixin {
  // Speech recognition state
  bool _isListening = false;
  bool _isRecording = false;
  String _recognizedText = '';
  double _confidence = 0.0;
  List<String> _attempts = [];
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _successController;
  
  // Therapy state
  int _currentAttempt = 0;
  final int _maxAttempts = 5;
  bool _sessionComplete = false;
  
  // Speech analysis
  List<double> _speechLevels = [];
  Timer? _speechTimer;
  double _currentVolume = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeechRecognition();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _initializeSpeechRecognition() {
    // In real implementation, initialize speech recognition service
    // For now, we'll simulate it
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _successController.dispose();
    _speechTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomControls(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Verbal Therapy'),
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showInstructions,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          const SizedBox(height: 24),
          
          // Word display
          _buildWordDisplay(),
          
          const SizedBox(height: 32),
          
          // Speech visualization
          _buildSpeechVisualization(),
          
          const SizedBox(height: 32),
          
          // Recognition feedback
          if (_recognizedText.isNotEmpty) _buildRecognitionFeedback(),
          
          const SizedBox(height: 24),
          
          // Attempts history
          if (_attempts.isNotEmpty) _buildAttemptsHistory(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _currentAttempt / _maxAttempts;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attempt ${_currentAttempt + 1} of $_maxAttempts',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            Text(
              '${(_currentAttempt / _maxAttempts * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildWordDisplay() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.8),
            Colors.blue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Say this word:',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.content.targetWord.toUpperCase(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (widget.content.pronunciation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.content.pronunciation!,
                style: const TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeechVisualization() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening ? Colors.green : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Wave visualizer
          SpeechWaveVisualizer(
            isActive: _isListening,
            speechLevels: _speechLevels,
            currentVolume: _currentVolume,
          ),
          
          // Center microphone
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isListening 
                    ? 1.0 + _pulseController.value * 0.3
                    : 1.0;
                
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? Colors.red.withOpacity(0.8)
                          : Colors.green.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.green)
                              .withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Status text overlay
          if (_isListening)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Listening... Say the word clearly',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecognitionFeedback() {
    return PronunciationFeedback(
      targetWord: widget.content.targetWord,
      recognizedText: _recognizedText,
      confidence: _confidence,
      onTryAgain: _startListening,
    );
  }

  Widget _buildAttemptsHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Attempts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ..._attempts.asMap().entries.map((entry) {
            final index = entry.key;
            final attempt = entry.value;
            final isCorrect = attempt.toLowerCase() == 
                widget.content.targetWord.toLowerCase();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.info,
                    color: isCorrect ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Attempt ${index + 1}: "$attempt"',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 16,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main action button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _sessionComplete ? null : _toggleListening,
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(
                  _sessionComplete 
                      ? 'Session Complete!'
                      : _isListening 
                          ? 'Stop Recording' 
                          : 'Start Speaking',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sessionComplete 
                      ? Colors.grey
                      : _isListening 
                          ? Colors.red 
                          : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Secondary buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _playExample,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Play Example'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _skipWord,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_sessionComplete) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeSession,
                  icon: const Icon(Icons.check),
                  label: const Text('Continue Learning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    if (_currentAttempt >= _maxAttempts) return;
    
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _confidence = 0.0;
    });
    
    _pulseController.repeat();
    _simulateListening();
    HapticFeedback.mediumImpact();
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _pulseController.stop();
    _speechTimer?.cancel();
    
    // Simulate speech recognition result
    _simulateRecognitionResult();
  }

  void _simulateListening() {
    // Simulate real-time speech level updates
    _speechTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentVolume = Random().nextDouble() * 0.8 + 0.2;
        _speechLevels.add(_currentVolume);
        if (_speechLevels.length > 50) {
          _speechLevels.removeAt(0);
        }
      });
    });
    
    // Auto-stop after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (_isListening) _stopListening();
    });
  }

  void _simulateRecognitionResult() {
    // Simulate speech recognition with varying accuracy
    final random = Random();
    final targetWord = widget.content.targetWord.toLowerCase();
    
    // Simulate different recognition results
    final possibleResults = [
      targetWord, // Perfect match
      targetWord + 's', // Close match
      targetWord.substring(0, targetWord.length - 1), // Partial match
      _generateSimilarWord(targetWord), // Similar word
    ];
    
    final recognizedText = possibleResults[random.nextInt(possibleResults.length)];
    final confidence = random.nextDouble() * 0.4 + 0.6; // 60-100% confidence
    
    setState(() {
      _recognizedText = recognizedText;
      _confidence = confidence;
      _attempts.add(recognizedText);
      _currentAttempt++;
    });
    
    // Check if word is correct
    if (recognizedText.toLowerCase() == targetWord) {
      _successController.forward();
      _sessionComplete = true;
      HapticFeedback.heavyImpact();
    } else if (_currentAttempt >= _maxAttempts) {
      _sessionComplete = true;
    }
  }

  String _generateSimilarWord(String target) {
    final similarWords = {
      'cat': ['bat', 'rat', 'hat', 'sat'],
      'dog': ['log', 'fog', 'hog', 'bog'],
      'apple': ['ample', 'appal', 'apply'],
      'water': ['waiter', 'winter', 'wader'],
    };
    
    final similar = similarWords[target];
    if (similar != null && similar.isNotEmpty) {
      return similar[Random().nextInt(similar.length)];
    }
    
    return target.substring(0, max(1, target.length - 1));
  }

  void _playExample() {
    // In real implementation, play TTS of the target word
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: "${widget.content.targetWord}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _skipWord() {
    setState(() {
      _sessionComplete = true;
      _attempts.add('(skipped)');
    });
  }

  void _completeSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verbal Therapy Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great job practicing "${widget.content.targetWord}"!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Attempts: ${_attempts.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ${_calculateAccuracy()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close therapy screen
              if (widget.onComplete != null) {
                widget.onComplete!();
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  int _calculateAccuracy() {
    if (_attempts.isEmpty) return 0;
    
    final correctAttempts = _attempts.where((attempt) =>
        attempt.toLowerCase() == widget.content.targetWord.toLowerCase()).length;
    
    return ((correctAttempts / _attempts.length) * 100).round();
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verbal Therapy Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎯 How it works:'),
              Text('• Look at the word displayed'),
              Text('• Tap the microphone to start'),
              Text('• Say the word clearly'),
              Text('• Get instant feedback'),
              SizedBox(height: 12),
              Text('💡 Tips for better recognition:'),
              Text('• Speak clearly and slowly'),
              Text('• Find a quiet environment'),
              Text('• Hold device close to mouth'),
              Text('• Practice pronunciation first'),
              SizedBox(height: 12),
              Text('🎮 Controls:'),
              Text('• Mic button: Start/stop recording'),
              Text('• Play button: Hear example'),
              Text('• Skip: Move to next word'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}