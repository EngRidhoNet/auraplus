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

class _ARVocabularyScreenState extends State<ARVocabularyScreen> {
  CameraController? _cameraController;
  FlutterTts? _flutterTts;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool showInstructions = true;
  bool _isObjectPlaced = false;
  Offset _objectPosition = const Offset(0.5, 0.5);
  double _objectScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTTS();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      var status = await Permission.camera.request();
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required for AR'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Initialize camera controller
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }

      AppLogger.success('Camera initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing camera: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
      AppLogger.success('TTS initialized');
    } catch (e) {
      AppLogger.error('Error initializing TTS: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR: ${widget.content.targetWord.toUpperCase()}'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Instructions Overlay
          if (showInstructions) _buildInstructionsOverlay(),

          // AR Overlay (Simulated)
          if (_isCameraInitialized && !showInstructions)
            _buildAROverlay(),

          // Bottom Control Panel
          _buildControlPanel(),

          // Word Display
          _buildWordDisplay(),
        ],
      ),
    );
  }

  Widget _buildAROverlay() {
    return Stack(
      children: [
        // Target indicator (only show when object not placed)
        if (!_isObjectPlaced)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.camera_enhance,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Point camera at a flat surface\nTap "Place" to place object',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Show 3D object when placed
        if (_isObjectPlaced)
          _build3DObject(),
      ],
    );
  }

  Widget _build3DObject() {
    return Positioned(
      left: MediaQuery.of(context).size.width * _objectPosition.dx - (75 * _objectScale),
      top: MediaQuery.of(context).size.height * _objectPosition.dy - (75 * _objectScale),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _objectPosition = Offset(
              (_objectPosition.dx * MediaQuery.of(context).size.width + details.delta.dx) / 
                  MediaQuery.of(context).size.width,
              (_objectPosition.dy * MediaQuery.of(context).size.height + details.delta.dy) / 
                  MediaQuery.of(context).size.height,
            );
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            _objectScale = (_objectScale * details.scale).clamp(0.5, 2.0);
          });
        },
        onTap: () {
          _playAudio();
        },
        child: Container(
          width: 150 * _objectScale,
          height: 150 * _objectScale,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.6),
                Colors.purple.withOpacity(0.6),
              ],
            ),
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon representing the object
              Icon(
                _getIconForWord(widget.content.targetWord),
                size: 60 * _objectScale,
                color: Colors.white,
              ),
              SizedBox(height: 8 * _objectScale),
              Text(
                widget.content.targetWord.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * _objectScale,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
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
                      Icons.touch_app,
                      size: 12 * _objectScale,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4 * _objectScale),
                    Text(
                      'Tap to speak',
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
        ),
      ),
    );
  }

  IconData _getIconForWord(String word) {
    switch (word.toLowerCase()) {
      case 'cat':
      case 'kucing':
        return Icons.pets;
      case 'dog':
      case 'anjing':
        return Icons.pets;
      case 'apple':
      case 'apel':
        return Icons.apple;
      case 'ball':
      case 'bola':
        return Icons.sports_soccer;
      case 'car':
      case 'mobil':
        return Icons.directions_car;
      case 'house':
      case 'rumah':
        return Icons.home;
      case 'tree':
      case 'pohon':
        return Icons.park;
      case 'book':
      case 'buku':
        return Icons.book;
      case 'chair':
      case 'kursi':
        return Icons.chair;
      case 'table':
      case 'meja':
        return Icons.table_restaurant;
      default:
        return Icons.category;
    }
  }

  Widget _buildInstructionsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'AR Mode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Practice "${widget.content.targetWord}" in AR:\n\n'
                '1. Point your camera at a flat surface\n'
                '2. Tap "Place" button to place the object\n'
                '3. Drag to move, pinch to resize\n'
                '4. Tap object to hear pronunciation\n'
                '5. Use buttons below for more actions',
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showInstructions = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Start AR'),
              ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: Icons.text_fields,
              label: 'Word',
              color: Colors.blue,
              onPressed: _showWordInfo,
            ),
            _buildControlButton(
              icon: _isObjectPlaced ? Icons.refresh : Icons.touch_app,
              label: _isObjectPlaced ? 'Reset' : 'Place',
              color: _isObjectPlaced ? Colors.orange : Colors.green,
              onPressed: _isObjectPlaced ? _resetObject : _simulatePlacement,
            ),
            _buildControlButton(
              icon: Icons.volume_up,
              label: 'Audio',
              color: Colors.purple,
              onPressed: _playAudio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 32),
          color: color,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWordDisplay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              widget.content.targetWord.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.content.pronunciation != null)
              Text(
                widget.content.pronunciation!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWordInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.content.targetWord.toUpperCase()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.content.pronunciation != null)
              Text('Pronunciation: ${widget.content.pronunciation}'),
            const SizedBox(height: 8),
            if (widget.content.description != null)
              Text('Description: ${widget.content.description}'),
            const SizedBox(height: 16),
            const Text(
              'AR Controls:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('• Drag to move object'),
            const Text('• Pinch to resize'),
            const Text('• Tap object to hear word'),
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

  void _simulatePlacement() {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    // Simulate AR placement with animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isObjectPlaced = true;
        });
        
        // Auto-play audio when placed
        _playAudio();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.content.targetWord} placed in AR!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _playAudio() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.speak(widget.content.targetWord);
        
        if (mounted) {
          // Visual feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Speaking: ${widget.content.targetWord}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error playing audio: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetObject() {
    setState(() {
      _isObjectPlaced = false;
      _objectPosition = const Offset(0.5, 0.5);
      _objectScale = 1.0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Object reset. Tap "Place" to place again.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHelp() {
    setState(() {
      showInstructions = true;
    });
  }
}