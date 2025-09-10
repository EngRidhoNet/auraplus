import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/therapy_content.dart';

class ARPronunciationGuide extends StatefulWidget {
  final TherapyContent content;
  
  const ARPronunciationGuide({
    super.key,
    required this.content,
  });

  @override
  State<ARPronunciationGuide> createState() => _ARPronunciationGuideState();
}

class _ARPronunciationGuideState extends State<ARPronunciationGuide>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _breathController;
  
  bool _isPlaying = false;
  bool _isRecording = false;
  int _currentSyllable = 0;
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _breathController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.withOpacity(0.9),
            Colors.purple.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: 20),
          
          // Pronunciation visualization
          _buildPronunciationVisualization(),
          
          const SizedBox(height: 20),
          
          // Syllable breakdown
          _buildSyllableBreakdown(),
          
          const SizedBox(height: 20),
          
          // Audio controls
          _buildAudioControls(),
          
          const SizedBox(height: 16),
          
          // Recording controls
          _buildRecordingControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.record_voice_over,
          size: 40,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        const Text(
          'Pronunciation Guide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Learn to say "${widget.content.targetWord}"',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPronunciationVisualization() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Sound waves
          if (_isPlaying) _buildSoundWaves(),
          
          // Pronunciation text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.content.targetWord.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.content.pronunciation != null)
                  Text(
                    widget.content.pronunciation!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundWaves() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: SoundWavePainter(
            animationValue: _waveController.value,
            isActive: _isPlaying,
          ),
        );
      },
    );
  }

  Widget _buildSyllableBreakdown() {
    final syllables = _breakIntoSyllables(widget.content.targetWord);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Syllable Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: syllables.asMap().entries.map((entry) {
              final index = entry.key;
              final syllable = entry.value;
              final isActive = _currentSyllable == index && _isPlaying;
              
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = isActive ? 1.0 + _pulseController.value * 0.2 : 1.0;
                  
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.yellow.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? Colors.yellow : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        syllable,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.yellow : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAudioButton(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          label: _isPlaying ? 'Pause' : 'Play',
          color: Colors.green,
          onPressed: _togglePlayback,
        ),
        _buildAudioButton(
          icon: Icons.slow_motion_video,
          label: 'Slow',
          color: Colors.blue,
          onPressed: _playSlowly,
        ),
        _buildAudioButton(
          icon: Icons.repeat,
          label: 'Repeat',
          color: Colors.orange,
          onPressed: _repeatPlayback,
        ),
      ],
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Practice Speaking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRecordButton(),
              _buildBreathingGuide(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _isRecording ? 1.0 + _pulseController.value * 0.3 : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording 
                    ? Colors.red.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.red : Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreathingGuide() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final breathValue = sin(_breathController.value * 2 * pi);
        final scale = 1.0 + breathValue * 0.2;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  breathValue > 0 ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.blue,
                  size: 20,
                ),
                Text(
                  breathValue > 0 ? 'In' : 'Out',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _breakIntoSyllables(String word) {
    // Simple syllable breakdown - in real app, use proper phonetic analysis
    final syllables = <String>[];
    final vowels = 'aeiouAEIOU';
    String currentSyllable = '';
    
    for (int i = 0; i < word.length; i++) {
      currentSyllable += word[i];
      
      if (vowels.contains(word[i])) {
        if (i + 1 < word.length && !vowels.contains(word[i + 1])) {
          if (i + 2 < word.length) {
            currentSyllable += word[i + 1];
            i++;
          }
        }
        syllables.add(currentSyllable);
        currentSyllable = '';
      }
    }
    
    if (currentSyllable.isNotEmpty) {
      if (syllables.isNotEmpty) {
        syllables.last += currentSyllable;
      } else {
        syllables.add(currentSyllable);
      }
    }
    
    return syllables.isEmpty ? [word] : syllables;
  }

  void _togglePlayback() async {
    setState(() => _isPlaying = !_isPlaying);
    
    if (_isPlaying) {
      _waveController.repeat();
      _pulseController.repeat();
      
      // Simulate syllable progression
      final syllables = _breakIntoSyllables(widget.content.targetWord);
      for (int i = 0; i < syllables.length; i++) {
        if (!_isPlaying) break;
        setState(() => _currentSyllable = i);
        await Future.delayed(const Duration(milliseconds: 600));
      }
      
      setState(() {
        _isPlaying = false;
        _currentSyllable = 0;
      });
      _waveController.stop();
      _pulseController.stop();
    } else {
      _waveController.stop();
      _pulseController.stop();
    }
    
    HapticFeedback.lightImpact();
  }

  void _playSlowly() async {
    if (_isPlaying) return;
    
    setState(() => _isPlaying = true);
    _waveController.repeat();
    _pulseController.repeat();
    
    // Slower syllable progression
    final syllables = _breakIntoSyllables(widget.content.targetWord);
    for (int i = 0; i < syllables.length; i++) {
      if (!_isPlaying) break;
      setState(() => _currentSyllable = i);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    
    setState(() {
      _isPlaying = false;
      _currentSyllable = 0;
    });
    _waveController.stop();
    _pulseController.stop();
    
    HapticFeedback.lightImpact();
  }

  void _repeatPlayback() {
    _togglePlayback();
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    
    if (_isRecording) {
      _pulseController.repeat();
      _breathController.repeat();
    } else {
      _pulseController.stop();
      _breathController.stop();
    }
    
    HapticFeedback.mediumImpact();
  }
}

class SoundWavePainter extends CustomPainter {
  final double animationValue;
  final bool isActive;
  
  SoundWavePainter({required this.animationValue, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final path = Path();
    
    for (double x = 0; x < size.width; x += 2) {
      final normalizedX = x / size.width;
      final wave1 = sin((normalizedX + animationValue) * 4 * pi) * 15;
      final wave2 = sin((normalizedX + animationValue) * 6 * pi) * 8;
      final y = centerY + wave1 + wave2;
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}