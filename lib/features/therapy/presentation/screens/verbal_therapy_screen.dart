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
    this.onComplete, required String categoryName,
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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
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
      duration: const Duration(milliseconds: 1500),
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

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeController.forward();
  }

  void _initializeSpeechRecognition() {
    // In real implementation, initialize speech recognition service
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _successController.dispose();
    _fadeController.dispose();
    _speechTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: false,
      appBar: _buildModernAppBar(isDark),
      body: _buildBody(isDark),
      bottomNavigationBar: _buildBottomControls(isDark),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildModernAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verbal Therapy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            'Practice pronunciation',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            onPressed: _showInstructions,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MAIN BODY
  // ============================================================================

  Widget _buildBody(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Modern Progress Bar
            _buildProgressBar(isDark),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Word Display Card
                    _buildModernWordCard(isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Speech Visualization
                    _buildModernSpeechVisualization(isDark),
                    
                    const SizedBox(height: 24),
                    
                    // Recognition Feedback
                    if (_recognizedText.isNotEmpty) 
                      _buildModernRecognitionFeedback(isDark),
                    
                    if (_recognizedText.isNotEmpty)
                      const SizedBox(height: 24),
                    
                    // Attempts History
                    if (_attempts.isNotEmpty) 
                      _buildModernAttemptsHistory(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = _currentAttempt / _maxAttempts;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      size: 16,
                      color: Color(0xFF66BB6A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Attempt ${_currentAttempt + 1} of $_maxAttempts',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF66BB6A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark 
                  ? const Color(0xFF2D2D2D) 
                  : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF66BB6A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernWordCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF66BB6A),
            Color(0xFF43A047),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF66BB6A).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Say this word clearly',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main Word
          Text(
            widget.content.targetWord.toUpperCase(),
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),

          // Pronunciation Guide
          if (widget.content.pronunciation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hearing_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.content.pronunciation!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Description
          if (widget.content.description != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.content.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernSpeechVisualization(bool isDark) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isListening 
              ? const Color(0xFF66BB6A)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: 2,
        ),
        boxShadow: [
          if (_isListening)
            BoxShadow(
              color: const Color(0xFF66BB6A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Stack(
        children: [
          // Wave Visualizer Background
          SpeechWaveVisualizer(
            isActive: _isListening,
            speechLevels: _speechLevels,
            currentVolume: _currentVolume,
          ),
          
          // Center Microphone Button
          Center(
            child: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _isListening 
                      ? 1.0 + (_pulseController.value * 0.15)
                      : 1.0;
                  
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isListening 
                              ? [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                ]
                              : [
                                  const Color(0xFF66BB6A),
                                  const Color(0xFF43A047),
                                ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening 
                                ? Colors.red 
                                : const Color(0xFF66BB6A)
                            ).withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Status Indicator
          if (_isListening)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Listening... Speak clearly',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Tap to start hint (when not listening)
          if (!_isListening && _attempts.isEmpty)
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF66BB6A).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: Color(0xFF66BB6A),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap microphone to start',
                        style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernRecognitionFeedback(bool isDark) {
    return PronunciationFeedback(
      targetWord: widget.content.targetWord,
      recognizedText: _recognizedText,
      confidence: _confidence,
      onTryAgain: _startListening,
    );
  }

  Widget _buildModernAttemptsHistory(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Attempts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._attempts.asMap().entries.map((entry) {
            final index = entry.key;
            final attempt = entry.value;
            final isCorrect = attempt.toLowerCase() == 
                widget.content.targetWord.toLowerCase();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? const Color(0xFF66BB6A).withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrect 
                      ? const Color(0xFF66BB6A)
                      : Colors.orange.shade400,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCorrect 
                          ? const Color(0xFF66BB6A)
                          : Colors.orange.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCorrect 
                          ? Icons.check_rounded 
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attempt ${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"$attempt"',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCorrect)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Perfect!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTTOM CONTROLS
  // ============================================================================

  Widget _buildBottomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Secondary Buttons Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF2D2D2D) 
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF66BB6A).withOpacity(0.3),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _playExample,
                        borderRadius: BorderRadius.circular(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              color: Color(0xFF66BB6A),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Play Example',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF66BB6A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF2D2D2D) 
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _skipWord,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.skip_next_rounded,
                              color: Colors.orange.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_sessionComplete) ...[
              const SizedBox(height: 16),
              // Complete Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4A90E2),
                      Color(0xFF357ABD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _completeSession,
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Continue Learning',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // METHODS
  // ============================================================================

  void _toggleListening() {
    if (_sessionComplete) return;
    
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
    
    _simulateRecognitionResult();
  }

  void _simulateListening() {
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
    
    Timer(const Duration(seconds: 3), () {
      if (_isListening) _stopListening();
    });
  }

  void _simulateRecognitionResult() {
    final random = Random();
    final targetWord = widget.content.targetWord.toLowerCase();
    
    final possibleResults = [
      targetWord,
      targetWord + 's',
      targetWord.substring(0, max(1, targetWord.length - 1)),
      _generateSimilarWord(targetWord),
    ];
    
    final recognizedText = possibleResults[random.nextInt(possibleResults.length)];
    final confidence = random.nextDouble() * 0.4 + 0.6;
    
    setState(() {
      _recognizedText = recognizedText;
      _confidence = confidence;
      _attempts.add(recognizedText);
      _currentAttempt++;
    });
    
    if (recognizedText.toLowerCase() == targetWord) {
      _successController.forward();
      _sessionComplete = true;
      HapticFeedback.heavyImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.celebration_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Perfect! You got it right! 🎉'),
            ],
          ),
          backgroundColor: const Color(0xFF66BB6A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text('Playing: "${widget.content.targetWord}"'),
          ],
        ),
        backgroundColor: const Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _skipWord() {
    setState(() {
      _sessionComplete = true;
      _attempts.add('(skipped)');
    });
    
    HapticFeedback.lightImpact();
  }

  void _completeSession() {
    final accuracy = _calculateAccuracy();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.celebration_rounded,
              color: Color(0xFF66BB6A),
              size: 32,
            ),
            SizedBox(width: 12),
            Text('Session Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great job practicing "${widget.content.targetWord}"!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attempts:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_attempts.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Accuracy:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$accuracy%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close therapy screen
                if (widget.onComplete != null) {
                  widget.onComplete!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF66BB6A)),
            SizedBox(width: 12),
            Text('How It Works'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎯 Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Look at the word displayed'),
              Text('• Tap the microphone to start'),
              Text('• Say the word clearly'),
              Text('• Get instant feedback'),
              SizedBox(height: 16),
              Text(
                '💡 Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Speak clearly and slowly'),
              Text('• Find a quiet environment'),
              Text('• Practice pronunciation first'),
              Text('• Use the "Play Example" button'),
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