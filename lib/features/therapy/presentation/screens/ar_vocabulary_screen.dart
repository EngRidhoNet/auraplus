import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/models/therapy_content.dart';
import '../../../../core/utils/logger.dart';

class ARVocabularyScreen extends StatefulWidget {
  final TherapyContent content;
  final VoidCallback onComplete;

  const ARVocabularyScreen({
    Key? key,
    required this.content,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ARVocabularyScreen> createState() => _ARVocabularyScreenState();
}

class _ARVocabularyScreenState extends State<ARVocabularyScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  CameraController? _cameraController;
  FlutterTts? _flutterTts;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // State variables
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _showInstructions = true;
  bool _isObjectPlaced = false;
  bool _isSpeaking = false;

  // Object positioning
  Offset _objectPosition = const Offset(0.5, 0.5);
  double _objectScale = 1.0;
  double _baseScale = 1.0;

  // ✅ Multi-touch gesture tracking
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          _showErrorSnackBar('Camera permission is required for AR');
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
        _showErrorSnackBar('Camera initialization failed');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildCameraPreview(),
          if (_showInstructions) _buildInstructionsOverlay(),
          if (_isCameraInitialized && !_showInstructions) _buildARLayer(),
          _buildWordDisplay(),
          _buildControlPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('AR: ${widget.content.targetWord.toUpperCase()}'),
      backgroundColor: Colors.blue.shade800,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => setState(() => _showInstructions = true),
          tooltip: 'Show Help',
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
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

  Widget _buildARLayer() {
    return Stack(
      children: [
        if (!_isObjectPlaced) _buildPlacementTarget(),
        if (_isObjectPlaced) _build3DObject(),
        if (!_isObjectPlaced) _buildScanOverlay(),
      ],
    );
  }

  Widget _buildPlacementTarget() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap "Place" to place object',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ScanLinePainter(animation: _pulseController),
      ),
    );
  }

  // ✅ FIXED: Use ONLY Listener - NO GestureDetector!
  Widget _build3DObject() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final objectSize = 150 * _objectScale;

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
              // ✅ Single finger = DRAG
              final delta = event.delta;
              _objectPosition = Offset(
                ((_objectPosition.dx * screenWidth) + delta.dx) / screenWidth,
                ((_objectPosition.dy * screenHeight) + delta.dy) / screenHeight,
              ).clamp(const Offset(0.1, 0.1), const Offset(0.9, 0.9));
            } else if (_pointers.length == 2) {
              // ✅ Two fingers = PINCH/SCALE
              final positions = _pointers.values.toList();
              final distance = (positions[0] - positions[1]).distance;

              if (_initialPinchDistance == null) {
                _initialPinchDistance = distance;
              } else {
                final scale = distance / _initialPinchDistance!;
                _objectScale = (_baseScale * scale).clamp(0.5, 2.5);
              }
            }
          });
        },
        onPointerUp: (event) {
          // ✅ Detect tap: quick touch without movement
          final tapDuration =
              DateTime.now().difference(_tapStartTime ?? DateTime.now());
          final tapDistance =
              (event.position - (_tapStartPosition ?? Offset.zero)).distance;

          if (tapDuration.inMilliseconds < 300 &&
              tapDistance < 10 &&
              _pointers.length == 1) {
            _playAudio(); // Play audio on tap
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: objectSize,
          height: objectSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.7),
                Colors.purple.withOpacity(0.7),
              ],
            ),
            border: Border.all(
              color: _isSpeaking ? Colors.yellow : Colors.white,
              width: _isSpeaking ? 4 : 3,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (_isSpeaking ? Colors.yellow : Colors.blue)
                    .withOpacity(0.6),
                blurRadius: _isSpeaking ? 40 : 30,
                spreadRadius: _isSpeaking ? 15 : 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForWord(widget.content.targetWord),
                    size: 60 * _objectScale,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8 * _objectScale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * _objectScale),
                    child: Text(
                      widget.content.targetWord.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * _objectScale,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4 * _objectScale),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * _objectScale,
                      vertical: 4 * _objectScale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSpeaking ? Icons.volume_up : Icons.touch_app,
                          size: 12 * _objectScale,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4 * _objectScale),
                        Text(
                          _isSpeaking ? 'Speaking...' : 'Tap to speak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * _objectScale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isSpeaking)
                Positioned.fill(
                  child: CustomPaint(
                    painter: AudioWavePainter(animation: _pulseController),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.view_in_ar,
                    size: 64,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'AR Learning Mode',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Practice "${widget.content.targetWord}"',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInstructionItem(
                  Icons.camera_alt,
                  'Point camera at flat surface',
                ),
                _buildInstructionItem(
                  Icons.touch_app,
                  'Tap "Place" to position object',
                ),
                _buildInstructionItem(
                  Icons.pan_tool,
                  'Drag to move, pinch to resize',
                ),
                _buildInstructionItem(
                  Icons.volume_up,
                  'Tap object to hear word',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() => _showInstructions = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start AR Experience',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _showInstructions ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.content.targetWord.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (widget.content.pronunciation != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.content.pronunciation!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showInstructions ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.9),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.info_outline,
                  label: 'Info',
                  color: Colors.blue,
                  onPressed: _showWordInfo,
                ),
                _buildControlButton(
                  icon:
                      _isObjectPlaced ? Icons.refresh : Icons.add_location_alt,
                  label: _isObjectPlaced ? 'Reset' : 'Place',
                  color: _isObjectPlaced ? Colors.orange : Colors.green,
                  onPressed: _isObjectPlaced ? _resetObject : _placeObject,
                  isPrimary: !_isObjectPlaced,
                ),
                _buildControlButton(
                  icon: Icons.volume_up,
                  label: 'Audio',
                  color: Colors.purple,
                  onPressed: _playAudio,
                  isActive: _isSpeaking,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.all(isPrimary ? 16 : 12),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.3)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color : color.withOpacity(0.5),
                  width: isActive ? 3 : 2,
                ),
              ),
              child: Icon(
                icon,
                size: isPrimary ? 36 : 28,
                color: color,
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

  IconData _getIconForWord(String word) {
    final wordMap = {
      'cat': Icons.pets,
      'kucing': Icons.pets,
      'dog': Icons.pets,
      'anjing': Icons.pets,
      'apple': Icons.apple,
      'apel': Icons.apple,
      'ball': Icons.sports_soccer,
      'bola': Icons.sports_soccer,
      'car': Icons.directions_car,
      'mobil': Icons.directions_car,
      'house': Icons.home,
      'rumah': Icons.home,
      'tree': Icons.park,
      'pohon': Icons.park,
      'book': Icons.book,
      'buku': Icons.book,
      'chair': Icons.chair,
      'kursi': Icons.chair,
      'table': Icons.table_restaurant,
      'meja': Icons.table_restaurant,
      'flower': Icons.local_florist,
      'bunga': Icons.local_florist,
      'sun': Icons.wb_sunny,
      'matahari': Icons.wb_sunny,
      'moon': Icons.nightlight,
      'bulan': Icons.nightlight,
      'star': Icons.star,
      'bintang': Icons.star,
    };

    return wordMap[word.toLowerCase()] ?? Icons.category;
  }

  void _showWordInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.content.targetWord.toUpperCase(),
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.content.pronunciation != null) ...[
              _buildInfoRow(
                Icons.record_voice_over,
                'Pronunciation',
                widget.content.pronunciation!,
              ),
              const SizedBox(height: 12),
            ],
            if (widget.content.description != null) ...[
              _buildInfoRow(
                Icons.description,
                'Description',
                widget.content.description!,
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'AR Controls',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildControlInfo(Icons.pan_tool, 'Drag to move'),
            _buildControlInfo(Icons.pinch, 'Pinch to resize'),
            _buildControlInfo(Icons.touch_app, 'Tap to hear'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _placeObject() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isObjectPlaced = true;
        });

        _playAudio();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${widget.content.targetWord} placed in AR!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
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
        _showErrorSnackBar('Unable to play audio');
      }
    }
  }

  void _resetObject() {
    setState(() {
      _isObjectPlaced = false;
      _objectPosition = const Offset(0.5, 0.5);
      _objectScale = 1.0;
      _baseScale = 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 12),
            Text('Object reset. Tap "Place" to place again.'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Extension untuk membatasi Offset dalam bounds
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

class ScanLinePainter extends CustomPainter {
  final Animation<double> animation;
  ScanLinePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final y = size.height * animation.value;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AudioWavePainter extends CustomPainter {
  final Animation<double> animation;
  AudioWavePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barCount = 8;
    final spacing = size.width / (barCount + 1);

    for (var i = 0; i < barCount; i++) {
      final x = spacing * (i + 1);
      final animationOffset = (animation.value * 10 + i) % 4;
      final heightMultiplier =
          animationOffset < 2 ? animationOffset : 4 - animationOffset;
      final height = 10 + (20 * heightMultiplier);

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