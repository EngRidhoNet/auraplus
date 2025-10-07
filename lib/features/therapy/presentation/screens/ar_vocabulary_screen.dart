import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/models/therapy_content.dart';
import '../../../../core/utils/logger.dart';

class ARVocabularyScreen extends StatefulWidget {
  final TherapyContent content;
  final VoidCallback onComplete;

  const ARVocabularyScreen({
    super.key,
    required this.content,
    required this.onComplete,
  });

  @override
  State<ARVocabularyScreen> createState() => _ARVocabularyScreenState();
}

class _ARVocabularyScreenState extends State<ARVocabularyScreen>
    with TickerProviderStateMixin {
  // Controllers
  CameraController? _cameraController;
  FlutterTts? _flutterTts;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  // State variables
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _showInstructions = true;
  bool _isObjectPlaced = false;
  bool _isSpeaking = false;
  int _tapCount = 0;

  // Object positioning
  Offset _objectPosition = const Offset(0.5, 0.5);
  double _objectScale = 1.0;
  double _baseScale = 1.0;

  // Multi-touch gesture tracking
  DateTime? _tapStartTime;
  Offset? _tapStartPosition;
  final Map<int, Offset> _pointers = {};
  double? _initialPinchDistance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
    _initializeTTS();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          _showModernSnackBar(
            'Camera permission required',
            Icons.camera_alt_outlined,
            Colors.red,
          );
          Navigator.pop(context);
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        AppLogger.success('Camera initialized successfully');
      }
    } catch (e) {
      AppLogger.error('Error initializing camera: $e');
      if (mounted) {
        _showModernSnackBar(
          'Camera initialization failed',
          Icons.error_outline,
          Colors.red,
        );
      }
    }
  }

  Future<void> _initializeTTS() async {
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage("id-ID");
      await _flutterTts!.setSpeechRate(0.4);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);

      _flutterTts!.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _flutterTts!.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts!.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
        AppLogger.error('TTS Error: $msg');
      });

      AppLogger.success('TTS initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing TTS: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts?.stop();
    _pulseController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(isDark),
      body: Stack(
        children: [
          _buildCameraPreview(),
          if (_showInstructions) _buildModernInstructionsOverlay(isDark),
          if (_isCameraInitialized && !_showInstructions) _buildARLayer(),
          if (!_showInstructions) _buildModernWordDisplay(isDark),
          if (!_showInstructions) _buildModernControlPanel(isDark),
        ],
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildModernAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.view_in_ar_rounded, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'AR: ${widget.content.targetWord.toUpperCase()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            onPressed: () => setState(() => _showInstructions = true),
            tooltip: 'Show Help',
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // CAMERA PREVIEW
  // ============================================================================

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF66BB6A).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  // ============================================================================
  // AR LAYER
  // ============================================================================

  Widget _buildARLayer() {
    return Stack(
      children: [
        if (!_isObjectPlaced) _buildModernPlacementTarget(),
        if (_isObjectPlaced) _buildModern3DObject(),
        if (!_isObjectPlaced) _buildModernScanOverlay(),
      ],
    );
  }

  Widget _buildModernPlacementTarget() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Outer Ring
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF66BB6A).withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF66BB6A).withOpacity(0.3),
                            const Color(0xFF66BB6A).withOpacity(0.0),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF66BB6A),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        size: 80,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF66BB6A).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: Color(0xFF66BB6A),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Tap "Place" to position object',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernScanOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ModernScanLinePainter(
          animation: _pulseController,
          glowAnimation: _glowController,
        ),
      ),
    );
  }

  Widget _buildModern3DObject() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final objectSize = 180 * _objectScale;

    return Positioned(
      left: (screenWidth * _objectPosition.dx) - (objectSize / 2),
      top: (screenHeight * _objectPosition.dy) - (objectSize / 2),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          setState(() {
            _tapStartTime = DateTime.now();
            _tapStartPosition = event.position;
            _baseScale = _objectScale;
            _pointers[event.pointer] = event.position;
          });
        },
        onPointerMove: (event) {
          setState(() {
            _pointers[event.pointer] = event.position;

            if (_pointers.length == 1) {
              // Single finger = DRAG
              final delta = event.delta;
              _objectPosition = Offset(
                ((_objectPosition.dx * screenWidth) + delta.dx) / screenWidth,
                ((_objectPosition.dy * screenHeight) + delta.dy) / screenHeight,
              ).clamp(const Offset(0.15, 0.15), const Offset(0.85, 0.85));
            } else if (_pointers.length == 2) {
              // Two fingers = PINCH/SCALE
              final positions = _pointers.values.toList();
              final distance = (positions[0] - positions[1]).distance;

              if (_initialPinchDistance == null) {
                _initialPinchDistance = distance;
              } else {
                final scale = distance / _initialPinchDistance!;
                _objectScale = (_baseScale * scale).clamp(0.5, 3.0);
              }
            }
          });
        },
        onPointerUp: (event) {
          // Detect tap
          final tapDuration =
              DateTime.now().difference(_tapStartTime ?? DateTime.now());
          final tapDistance =
              (event.position - (_tapStartPosition ?? Offset.zero)).distance;

          if (tapDuration.inMilliseconds < 300 &&
              tapDistance < 10 &&
              _pointers.length == 1) {
            _handleObjectTap();
          }

          setState(() {
            _pointers.remove(event.pointer);
            if (_pointers.isEmpty) {
              _initialPinchDistance = null;
              _baseScale = _objectScale;
            }
          });
        },
        onPointerCancel: (event) {
          setState(() {
            _pointers.remove(event.pointer);
            if (_pointers.isEmpty) {
              _initialPinchDistance = null;
            }
          });
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotateAnimation, _glowAnimation]),
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * 0.05,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: objectSize,
                height: objectSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isSpeaking
                        ? [
                            const Color(0xFFFFD700).withOpacity(0.9),
                            const Color(0xFFFFA500).withOpacity(0.9),
                          ]
                        : [
                            const Color(0xFF66BB6A).withOpacity(0.85),
                            const Color(0xFF43A047).withOpacity(0.85),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _isSpeaking
                        ? Colors.yellow
                        : Colors.white.withOpacity(0.8),
                    width: _isSpeaking ? 4 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSpeaking
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF66BB6A))
                          .withOpacity(_glowAnimation.value),
                      blurRadius: _isSpeaking ? 50 : 40,
                      spreadRadius: _isSpeaking ? 20 : 15,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CustomPaint(
                          painter: ARPatternPainter(
                            animation: _rotateController,
                          ),
                        ),
                      ),
                    ),

                    // Main Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(16 * _objectScale),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForWord(widget.content.targetWord),
                            size: 50 * _objectScale,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 12 * _objectScale),

                        // Word
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * _objectScale,
                          ),
                          child: Text(
                            widget.content.targetWord.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20 * _objectScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        SizedBox(height: 8 * _objectScale),

                        // Tap Counter Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * _objectScale,
                            vertical: 6 * _objectScale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSpeaking
                                    ? Icons.volume_up_rounded
                                    : Icons.touch_app_rounded,
                                size: 14 * _objectScale,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6 * _objectScale),
                              Text(
                                _isSpeaking
                                    ? 'Speaking...'
                                    : 'Taps: $_tapCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12 * _objectScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Audio Wave Effect
                    if (_isSpeaking)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CustomPaint(
                            painter: ModernAudioWavePainter(
                              animation: _pulseController,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================================
  // INSTRUCTIONS OVERLAY
  // ============================================================================

  Widget _buildModernInstructionsOverlay(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.85),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFF66BB6A).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF66BB6A).withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.view_in_ar_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'AR Learning Mode',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Practice: ${widget.content.targetWord.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Instructions
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'How to Use AR',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildModernInstructionItem(
                        Icons.camera_alt_rounded,
                        'Point Camera',
                        'Aim at a flat surface',
                        const Color(0xFF66BB6A),
                        isDark,
                      ),
                      _buildModernInstructionItem(
                        Icons.add_location_alt_rounded,
                        'Place Object',
                        'Tap "Place" button to position',
                        const Color(0xFF4A90E2),
                        isDark,
                      ),
                      _buildModernInstructionItem(
                        Icons.pan_tool_rounded,
                        'Move & Resize',
                        'Drag to move, pinch to scale',
                        const Color(0xFF9C27B0),
                        isDark,
                      ),
                      _buildModernInstructionItem(
                        Icons.volume_up_rounded,
                        'Hear Word',
                        'Tap the object to listen',
                        const Color(0xFFFF9800),
                        isDark,
                      ),
                    ],
                  ),
                ),

                // Start Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF66BB6A).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _showInstructions = false);
                          HapticFeedback.mediumImpact();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start AR Experience',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInstructionItem(
    IconData icon,
    String title,
    String description,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WORD DISPLAY
  // ============================================================================

  Widget _buildModernWordDisplay(bool isDark) {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showInstructions ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF66BB6A).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForWord(widget.content.targetWord),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.content.targetWord.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        if (widget.content.pronunciation != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.hearing_rounded,
                                size: 14,
                                color: Color(0xFF66BB6A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.content.pronunciation!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.content.description != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.content.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // CONTROL PANEL
  // ============================================================================

  Widget _buildModernControlPanel(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showInstructions ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(
                color: const Color(0xFF66BB6A).withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stats Row
                if (_isObjectPlaced)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.touch_app_rounded,
                          'Taps',
                          _tapCount.toString(),
                          const Color(0xFF66BB6A),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStatItem(
                          Icons.zoom_in_rounded,
                          'Scale',
                          '${(_objectScale * 100).toInt()}%',
                          const Color(0xFF4A90E2),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStatItem(
                          Icons.volume_up_rounded,
                          'Audio',
                          _isSpeaking ? 'Playing' : 'Ready',
                          const Color(0xFFFF9800),
                        ),
                      ],
                    ),
                  ),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModernControlButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Info',
                      color: const Color(0xFF4A90E2),
                      onPressed: _showModernWordInfo,
                    ),
                    _buildModernControlButton(
                      icon: _isObjectPlaced
                          ? Icons.refresh_rounded
                          : Icons.add_location_alt_rounded,
                      label: _isObjectPlaced ? 'Reset' : 'Place',
                      color: _isObjectPlaced
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF66BB6A),
                      onPressed: _isObjectPlaced ? _resetObject : _placeObject,
                      isPrimary: !_isObjectPlaced,
                    ),
                    _buildModernControlButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Audio',
                      color: const Color(0xFF9C27B0),
                      onPressed: _playAudio,
                      isActive: _isSpeaking,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModernControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isPrimary ? 72 : 64,
          height: isPrimary ? 72 : 64,
          decoration: BoxDecoration(
            gradient: isActive || isPrimary
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  )
                : null,
            color: !isActive && !isPrimary
                ? Colors.white.withOpacity(0.15)
                : null,
            borderRadius: BorderRadius.circular(isPrimary ? 20 : 18),
            border: Border.all(
              color: color.withOpacity(isActive ? 1.0 : 0.5),
              width: isActive ? 3 : 2,
            ),
            boxShadow: isActive || isPrimary
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(isPrimary ? 20 : 18),
              child: Center(
                child: Icon(
                  icon,
                  size: isPrimary ? 36 : 28,
                  color: isActive || isPrimary ? Colors.white : color,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  IconData _getIconForWord(String word) {
    final wordMap = {
      'cat': Icons.pets_rounded,
      'kucing': Icons.pets_rounded,
      'dog': Icons.pets_rounded,
      'anjing': Icons.pets_rounded,
      'apple': Icons.apple_rounded,
      'apel': Icons.apple_rounded,
      'ball': Icons.sports_soccer_rounded,
      'bola': Icons.sports_soccer_rounded,
      'car': Icons.directions_car_rounded,
      'mobil': Icons.directions_car_rounded,
      'house': Icons.home_rounded,
      'rumah': Icons.home_rounded,
      'tree': Icons.park_rounded,
      'pohon': Icons.park_rounded,
      'book': Icons.book_rounded,
      'buku': Icons.book_rounded,
      'chair': Icons.chair_rounded,
      'kursi': Icons.chair_rounded,
      'table': Icons.table_restaurant_rounded,
      'meja': Icons.table_restaurant_rounded,
      'flower': Icons.local_florist_rounded,
      'bunga': Icons.local_florist_rounded,
      'sun': Icons.wb_sunny_rounded,
      'matahari': Icons.wb_sunny_rounded,
      'moon': Icons.nightlight_rounded,
      'bulan': Icons.nightlight_rounded,
      'star': Icons.star_rounded,
      'bintang': Icons.star_rounded,
    };

    return wordMap[word.toLowerCase()] ?? Icons.category_rounded;
  }

  void _handleObjectTap() {
    setState(() => _tapCount++);
    _playAudio();
    HapticFeedback.mediumImpact();
  }

  void _placeObject() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isObjectPlaced = true;
        });

        _playAudio();

        _showModernSnackBar(
          '${widget.content.targetWord} placed in AR!',
          Icons.check_circle_rounded,
          const Color(0xFF66BB6A),
        );
      }
    });
  }

  Future<void> _playAudio() async {
    if (_flutterTts == null || _isSpeaking) return;
    try {
      await _flutterTts!.speak(widget.content.targetWord);
    } catch (e) {
      AppLogger.error('Error playing audio: $e');
      if (mounted) {
        _showModernSnackBar(
          'Unable to play audio',
          Icons.error_outline_rounded,
          Colors.red,
        );
      }
    }
  }

  void _resetObject() {
    setState(() {
      _isObjectPlaced = false;
      _objectPosition = const Offset(0.5, 0.5);
      _objectScale = 1.0;
      _baseScale = 1.0;
      _tapCount = 0;
    });

    HapticFeedback.mediumImpact();

    _showModernSnackBar(
      'Object reset. Tap "Place" to position again',
      Icons.refresh_rounded,
      const Color(0xFFFF9800),
    );
  }

  void _showModernWordInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForWord(widget.content.targetWord),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.content.targetWord.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.content.pronunciation != null)
                _buildModernInfoRow(
                  Icons.record_voice_over_rounded,
                  'Pronunciation',
                  widget.content.pronunciation!,
                  const Color(0xFF4A90E2),
                  isDark,
                ),
              if (widget.content.description != null) ...[
                const SizedBox(height: 16),
                _buildModernInfoRow(
                  Icons.description_rounded,
                  'Description',
                  widget.content.description!,
                  const Color(0xFF9C27B0),
                  isDark,
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF66BB6A).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AR Controls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildModernControlInfo(
                      Icons.pan_tool_rounded,
                      'Drag to move object',
                      isDark,
                    ),
                    _buildModernControlInfo(
                      Icons.pinch_rounded,
                      'Pinch to resize',
                      isDark,
                    ),
                    _buildModernControlInfo(
                      Icons.touch_app_rounded,
                      'Tap to hear word',
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
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

  Widget _buildModernInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernControlInfo(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModernSnackBar(String message, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Extension untuk Offset clamp
extension OffsetClamp on Offset {
  Offset clamp(Offset lower, Offset upper) {
    return Offset(
      dx.clamp(lower.dx, upper.dx),
      dy.clamp(lower.dy, upper.dy),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

class ModernScanLinePainter extends CustomPainter {
  final Animation<double> animation;
  final Animation<double> glowAnimation;

  ModernScanLinePainter({
    required this.animation,
    required this.glowAnimation,
  }) : super(repaint: Listenable.merge([animation, glowAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF66BB6A).withOpacity(0.4 * glowAnimation.value)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        10 * glowAnimation.value,
      );

    final y = size.height * animation.value;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // Draw corner brackets
    final bracketSize = 40.0;
    final bracketPaint = Paint()
      ..color = const Color(0xFF66BB6A).withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(const Offset(20, 20), Offset(20 + bracketSize, 20), bracketPaint);
    canvas.drawLine(const Offset(20, 20), Offset(20, 20 + bracketSize), bracketPaint);

    // Top-right
    canvas.drawLine(
      Offset(size.width - 20, 20),
      Offset(size.width - 20 - bracketSize, 20),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - 20, 20),
      Offset(size.width - 20, 20 + bracketSize),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(20 + bracketSize, size.height - 20),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(20, size.height - 20 - bracketSize),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20),
      Offset(size.width - 20 - bracketSize, size.height - 20),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - 20, size.height - 20),
      Offset(size.width - 20, size.height - 20 - bracketSize),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ModernAudioWavePainter extends CustomPainter {
  final Animation<double> animation;

  ModernAudioWavePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barCount = 12;
    final spacing = size.width / (barCount + 1);

    for (var i = 0; i < barCount; i++) {
      final x = spacing * (i + 1);
      final animationOffset = (animation.value * 10 + i) % 4;
      final heightMultiplier =
          animationOffset < 2 ? animationOffset : 4 - animationOffset;
      final height = 15 + (30 * heightMultiplier);

      canvas.drawLine(
        Offset(x, centerY - height),
        Offset(x, centerY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ARPatternPainter extends CustomPainter {
  final Animation<double> animation;

  ARPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridSize = 20.0;
    final offset = animation.value * gridSize;

    // Vertical lines
    for (var x = -offset; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (var y = -offset; y < size.height + gridSize; y += gridSize) {
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