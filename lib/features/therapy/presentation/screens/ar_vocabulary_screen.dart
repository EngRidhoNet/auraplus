import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/models/therapy_content.dart';

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

class _ARVocabularyScreenState extends State<ARVocabularyScreen> {
  bool _permissionGranted = false;
  String _instructionText = "Point your camera at a flat surface and tap to place the word";
  bool _objectPlaced = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _permissionGranted = status == PermissionStatus.granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR: ${widget.content.targetWord}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showARInstructions,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (!_permissionGranted) {
      return _buildPermissionRequest();
    }

    return Stack(
      children: [
        // AR Camera Simulation (for now)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
          child: _buildARSimulation(),
        ),
        
        // Instruction overlay
        if (!_objectPlaced)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildInstructionCard(),
          ),
          
        // Word info overlay
        if (_objectPlaced)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildWordInfoCard(),
          ),
          
        // Center crosshair
        if (!_objectPlaced)
          const Center(
            child: Icon(
              Icons.add,
              size: 50,
              color: Colors.white70,
            ),
          ),
      ],
    );
  }

  Widget _buildARSimulation() {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: _objectPlaced
            ? _buildPlacedObject()
            : _buildDetectionAnimation(),
      ),
    );
  }

  Widget _buildDetectionAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated scanning lines
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Scanning line animation would go here
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
                const Center(
                  child: Text(
                    'Looking for surfaces...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap anywhere to place word',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacedObject() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D-like word display
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(0.1)
              ..rotateY(0.1),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.content.targetWord.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  if (widget.content.pronunciation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.content.pronunciation!,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Floating particles effect
          ...List.generate(6, (index) => 
            Positioned(
              left: 100 + (index * 20).toDouble(),
              top: 200 + (index * 15).toDouble(),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 1000 + (index * 200)),
                curve: Curves.easeInOut,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app,
              size: 32,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 8),
            Text(
              _instructionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordInfoCard() {
    return Card(
      elevation: 8,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Word Placed Successfully!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.content.targetWord.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            if (widget.content.pronunciation != null)
              Text(
                widget.content.pronunciation!,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            if (widget.content.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.content.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_objectPlaced) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetAR,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _objectPlaced ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: _objectPlaced ? _completeARSession : null,
              icon: Icon(_objectPlaced ? Icons.check : Icons.visibility),
              label: Text(_objectPlaced ? 'Complete' : 'Place Word First'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
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
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AR functionality requires camera access to work properly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap() {
    if (!_objectPlaced) {
      setState(() {
        _objectPlaced = true;
        _instructionText = "Great! You placed '${widget.content.targetWord}' in AR!";
      });
      
      HapticFeedback.lightImpact();
    }
  }

  void _showARInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Instructions'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Point your camera at a flat surface'),
            SizedBox(height: 8),
            Text('2. Wait for the surface to be detected'),
            SizedBox(height: 8),
            Text('3. Tap on the surface to place the word'),
            SizedBox(height: 8),
            Text('4. Practice saying the word out loud'),
            SizedBox(height: 8),
            Text('5. Tap "Complete" when ready'),
          ],
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

  void _resetAR() {
    setState(() {
      _objectPlaced = false;
      _instructionText = "Point your camera at a flat surface and tap to place the word";
    });
  }

  void _completeARSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great Job!'),
        content: Text(
          'You successfully placed and learned the word "${widget.content.targetWord}" in AR!',
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}