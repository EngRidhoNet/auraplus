import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../providers/emotion_provider.dart';
import '../widgets/emotion_result_widget.dart';
import '../../../../core/utils/logger.dart';

class EmotionDetectionScreen extends ConsumerStatefulWidget {
  const EmotionDetectionScreen({super.key});

  @override
  ConsumerState<EmotionDetectionScreen> createState() => 
      _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends ConsumerState<EmotionDetectionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        AppLogger.error('No cameras available');
        return;
      }

      // Use front camera for emotion detection
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      AppLogger.error('Error initializing camera: $e');
    }
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      
      // Detect emotion
      await ref.read(emotionDetectionNotifierProvider)
          .detectFromImagePath(image.path);

    } catch (e) {
      AppLogger.error('Error capturing image: $e');
      _showErrorSnackBar('Failed to capture image');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        await ref.read(emotionDetectionNotifierProvider)
            .detectFromImagePath(image.path);
      }
    } catch (e) {
      AppLogger.error('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modelInitAsync = ref.watch(emotionModelInitProvider);
    final currentEmotion = ref.watch(currentEmotionProvider);
    final detectionState = ref.watch(emotionDetectionStateProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: _buildAppBar(isDark),
      body: modelInitAsync.when(
        data: (isInitialized) {
          if (!isInitialized) {
            return _buildErrorState('Failed to load emotion detection model');
          }

          return Column(
            children: [
              // Camera Preview
              Expanded(
                flex: 3,
                child: _buildCameraPreview(isDark),
              ),

              // Emotion Result
              if (currentEmotion != null)
                Expanded(
                  flex: 2,
                  child: EmotionResultWidget(
                    result: currentEmotion,
                    isDark: isDark,
                  ),
                ),

              // Controls
              _buildControls(isDark, detectionState.isDetecting),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState('Error: $error'),
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildAppBar(bool isDark) {
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
      title: const Row(
        children: [
          Icon(Icons.psychology_rounded, size: 24),
          SizedBox(width: 12),
          Text(
            'Emotion Detection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () => _showInfoDialog(),
        ),
      ],
    );
  }

  // ============================================================================
  // CAMERA PREVIEW
  // ============================================================================

  Widget _buildCameraPreview(bool isDark) {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  // ============================================================================
  // CONTROLS
  // ============================================================================

  Widget _buildControls(bool isDark, bool isDetecting) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          _buildControlButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            color: const Color(0xFF4A90E2),
            onTap: isDetecting ? null : _pickImageFromGallery,
            isDark: isDark,
          ),

          // Capture button
          _buildCaptureButton(isDetecting, isDark),

          // History button
          _buildControlButton(
            icon: Icons.history_rounded,
            label: 'History',
            color: const Color(0xFF9C27B0),
            onTap: () => _showHistoryDialog(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: onTap == null
                  ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                  : color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: onTap == null
                    ? Colors.transparent
                    : color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: onTap == null
                  ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                  : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton(bool isDetecting, bool isDark) {
    return GestureDetector(
      onTap: isDetecting ? null : _captureAndDetect,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: isDetecting
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                    ),
              color: isDetecting
                  ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                  : null,
              shape: BoxShape.circle,
              boxShadow: isDetecting
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF66BB6A).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: isDetecting
                ? const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.camera_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            isDetecting ? 'Detecting...' : 'Capture',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // STATES
  // ============================================================================

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Loading emotion detection model...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_rounded, color: Color(0xFF4A90E2)),
            SizedBox(width: 12),
            Text('How it works'),
          ],
        ),
        content: const Text(
          'This feature uses on-device AI to detect emotions from facial expressions. '
          'The model runs entirely on your device for privacy.\n\n'
          'Emotions detected:\n'
          '• Joy 😊\n'
          '• Sadness 😢\n'
          '• Anger 😠\n'
          '• Fear 😨\n'
          '• Surprise 😲\n'
          '• Natural 😐',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    final history = ref.read(emotionHistoryProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detection History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (history.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          ref.read(emotionDetectionNotifierProvider).clearHistory();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
              ),
              
              // History list
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text('No detection history yet'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final result = history[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF2D2D2D)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: result.getEmotionColor().withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    result.getEmotionIcon(),
                                    color: result.getEmotionColor(),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result.emotion.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${(result.confidence * 100).toStringAsFixed(1)}% confidence',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark 
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(result.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark 
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}