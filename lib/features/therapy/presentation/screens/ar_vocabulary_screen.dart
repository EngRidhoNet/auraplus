import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/models/therapy_content.dart';
import '../widgets/ar_3d_model_viewer.dart';
import '../widgets/ar_pronunciation_guide.dart';

class ARVocabularyScreen extends StatefulWidget {
  final TherapyContent content;
  final VoidCallback? onComplete;
  
  const ARVocabularyScreen({
    super.key,
    required this.content,
    this.onComplete,
  });

  @override
  State<ARVocabularyScreen> createState() => _ARVocabularyScreenState();
}

class _ARVocabularyScreenState extends State<ARVocabularyScreen>
    with TickerProviderStateMixin {
  bool _permissionGranted = false;
  bool _isARInitialized = false;
  bool _objectPlaced = false;
  bool _showPronunciationGuide = false;
  bool _show3DModel = false;
  bool _isLoading = false;
  String _currentARMode = 'word'; // word, model, pronunciation
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  
  // AR tracking state
  bool _surfaceDetected = false;
  int _detectedSurfaces = 0;
  String _trackingQuality = 'Poor';
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestPermissions();
    _initializeAR();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    setState(() {
      _permissionGranted = status == PermissionStatus.granted;
    });
  }

  Future<void> _initializeAR() async {
    if (!_permissionGranted) return;
    
    setState(() => _isLoading = true);
    
    // Simulate AR initialization
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isARInitialized = true;
        _isLoading = false;
      });
      _startSurfaceDetection();
    }
  }

  void _startSurfaceDetection() {
    // Simulate progressive surface detection
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _objectPlaced) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _detectedSurfaces++;
        if (_detectedSurfaces > 2) {
          _surfaceDetected = true;
          _trackingQuality = _detectedSurfaces > 5 ? 'Excellent' : 
                          _detectedSurfaces > 3 ? 'Good' : 'Fair';
        }
      });
      
      if (_detectedSurfaces > 8) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomControls(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('AR: ${widget.content.targetWord.toUpperCase()}'),
      backgroundColor: Colors.black.withOpacity(0.8),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // AR Mode Selector
        PopupMenuButton<String>(
          icon: const Icon(Icons.view_in_ar),
          onSelected: (mode) => setState(() => _currentARMode = mode),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'word', child: Text('Word Display')),
            const PopupMenuItem(value: 'model', child: Text('3D Model')),
            const PopupMenuItem(value: 'pronunciation', child: Text('Pronunciation')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showARInstructions,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (!_permissionGranted) {
      return _buildPermissionRequest();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Stack(
      children: [
        // AR Camera View
        _buildARCameraView(),
        
        // AR Overlays
        if (_isARInitialized) ...[
          _buildTrackingInfo(),
          _buildARInstructions(),
          if (_objectPlaced) _buildARContent(),
          if (_surfaceDetected && !_objectPlaced) _buildSurfaceIndicator(),
        ],
      ],
    );
  }

  Widget _buildARCameraView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Simulate camera feed with animated particles
          ...List.generate(20, (index) => _buildFloatingParticle(index)),
          
          // AR Grid overlay
          if (_surfaceDetected) _buildARGrid(),
          
          // Center crosshair
          if (!_objectPlaced) _buildCrosshair(),
          
          // Touch handler
          GestureDetector(
            onTap: _handleARTap,
            onPanUpdate: _handleARPan,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = Random(index);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned(
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          top: random.nextDouble() * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: (0.3 + _pulseController.value * 0.7) * random.nextDouble(),
            child: Container(
              width: 2 + random.nextDouble() * 4,
              height: 2 + random.nextDouble() * 4,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildARGrid() {
    return CustomPaint(
      size: Size.infinite,
      painter: ARGridPainter(opacity: 0.3),
    );
  }

  Widget _buildCrosshair() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + _pulseController.value * 0.2;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _surfaceDetected ? Colors.green : Colors.white70,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _surfaceDetected ? Icons.add : Icons.search,
                color: _surfaceDetected ? Colors.green : Colors.white70,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackingInfo() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.track_changes,
                  color: _getTrackingColor(),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _trackingQuality,
                  style: TextStyle(
                    color: _getTrackingColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'Surfaces: $_detectedSurfaces',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARInstructions() {
    if (_objectPlaced) return const SizedBox.shrink();
    
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.5 + _pulseController.value * 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _surfaceDetected ? Icons.touch_app : Icons.camera_alt,
                  color: _surfaceDetected ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _surfaceDetected 
                      ? 'Tap to place "${widget.content.targetWord}"'
                      : 'Looking for surfaces...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _surfaceDetected
                      ? 'Point at a flat surface and tap'
                      : 'Move your device slowly',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSurfaceIndicator() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return CustomPaint(
            painter: SurfaceIndicatorPainter(
              animationValue: _pulseController.value,
              surfaceQuality: _trackingQuality,
            ),
          );
        },
      ),
    );
  }

  Widget _buildARContent() {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + _scaleController.value * 0.4,
              child: _buildCurrentARMode(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentARMode() {
    switch (_currentARMode) {
      case 'model':
        return _build3DModelViewer();
      case 'pronunciation':
        return _buildPronunciationGuide();
      default:
        return _buildEnhancedWordDisplay();
    }
  }

  Widget _build3DModelViewer() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_rotationController.value * 2 * pi)
            ..rotateX(sin(_rotationController.value * 2 * pi) * 0.3),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.9),
                  Colors.indigo.withOpacity(1.0),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.view_in_ar,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.content.targetWord.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '3D Model',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPronunciationGuide() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.withOpacity(0.9),
            Colors.red.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + _pulseController.value * 0.1,
                child: const Icon(
                  Icons.volume_up,
                  size: 48,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.content.targetWord.toUpperCase(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.content.pronunciation != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.content.pronunciation!,
              style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Simulate pronunciation playback
              HapticFeedback.mediumImpact();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Pronunciation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWordDisplay() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_rotationController.value * 0.2)
            ..rotateX(0.1),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.9),
                  Colors.purple.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main word
                Text(
                  widget.content.targetWord.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                
                // Pronunciation
                if (widget.content.pronunciation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.content.pronunciation!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                ],
                
                // Description
                if (widget.content.description != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.content.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AR Mode Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModeButton('Word', 'word', Icons.text_fields),
                _buildModeButton('3D', 'model', Icons.view_in_ar),
                _buildModeButton('Audio', 'pronunciation', Icons.volume_up),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                if (_objectPlaced) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _resetAR,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _objectPlaced ? _completeARSession : null,
                    icon: Icon(_objectPlaced ? Icons.check : Icons.camera),
                    label: Text(_objectPlaced ? 'Complete Session' : 'Place Object First'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, String mode, IconData icon) {
    final isSelected = _currentARMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentARMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AR functionality requires camera access to detect surfaces and place objects.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Grant Camera Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: Icon(
                  Icons.view_in_ar,
                  size: 64,
                  color: Colors.blue,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Initializing AR...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we prepare the AR experience',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleARTap() {
    if (!_surfaceDetected || _objectPlaced) return;
    
    setState(() => _objectPlaced = true);
    _scaleController.forward();
    HapticFeedback.mediumImpact();
  }

  void _handleARPan(DragUpdateDetails details) {
    // Handle AR object manipulation
    if (_objectPlaced) {
      // Rotate or scale object based on pan gesture
      HapticFeedback.selectionClick();
    }
  }

  void _resetAR() {
    setState(() {
      _objectPlaced = false;
      _detectedSurfaces = 0;
      _surfaceDetected = false;
      _trackingQuality = 'Poor';
    });
    _scaleController.reset();
    _startSurfaceDetection();
  }

  void _completeARSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Session Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great job learning "${widget.content.targetWord}" in AR!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You successfully:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✓ Detected surfaces'),
                Text('✓ Placed AR object'),
                Text('✓ Interacted with 3D word'),
                Text('✓ Practiced pronunciation'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close AR screen
              if (widget.onComplete != null) {
                widget.onComplete!();
              }
            },
            child: const Text('Continue Learning'),
          ),
        ],
      ),
    );
  }

  void _showARInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enhanced AR Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎯 Getting Started:'),
              Text('• Point camera at a flat surface'),
              Text('• Wait for surface detection'),
              Text('• Tap to place the word'),
              SizedBox(height: 12),
              Text('🎮 AR Modes:'),
              Text('• Word: See 3D text floating'),
              Text('• 3D: Interactive 3D model'),
              Text('• Audio: Pronunciation guide'),
              SizedBox(height: 12),
              Text('✨ Interactions:'),
              Text('• Tap to place objects'),
              Text('• Pan to rotate/move'),
              Text('• Switch modes anytime'),
              Text('• Reset to try again'),
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

  Color _getTrackingColor() {
    switch (_trackingQuality) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

// Custom painters for AR effects
class ARGridPainter extends CustomPainter {
  final double opacity;
  
  ARGridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(opacity)
      ..strokeWidth = 1;

    const spacing = 50.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SurfaceIndicatorPainter extends CustomPainter {
  final double animationValue;
  final String surfaceQuality;
  
  SurfaceIndicatorPainter({
    required this.animationValue,
    required this.surfaceQuality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getQualityColor().withOpacity(0.3 + animationValue * 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = 100 + animationValue * 20;
    
    canvas.drawCircle(center, radius, paint);
    
    // Draw corner brackets
    final bracketSize = 30.0;
    final corners = [
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx + radius, center.dy + radius),
    ];
    
    for (int i = 0; i < corners.length; i++) {
      _drawCornerBracket(canvas, corners[i], bracketSize, paint, i);
    }
  }

  void _drawCornerBracket(Canvas canvas, Offset corner, double size, Paint paint, int index) {
    final path = Path();
    
    switch (index) {
      case 0: // Top-left
        path.moveTo(corner.dx + size, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy + size);
        break;
      case 1: // Top-right
        path.moveTo(corner.dx - size, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy + size);
        break;
      case 2: // Bottom-left
        path.moveTo(corner.dx, corner.dy - size);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx + size, corner.dy);
        break;
      case 3: // Bottom-right
        path.moveTo(corner.dx, corner.dy - size);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx - size, corner.dy);
        break;
    }
    
    canvas.drawPath(path, paint);
  }

  Color _getQualityColor() {
    switch (surfaceQuality) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}