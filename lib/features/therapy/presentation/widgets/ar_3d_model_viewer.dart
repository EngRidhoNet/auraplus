import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/therapy_content.dart';

class AR3DModelViewer extends StatefulWidget {
  final TherapyContent content;
  
  const AR3DModelViewer({
    super.key,
    required this.content,
  });

  @override
  State<AR3DModelViewer> createState() => _AR3DModelViewerState();
}

class _AR3DModelViewerState extends State<AR3DModelViewer>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _bounceController;
  late AnimationController _particleController;
  
  double _scale = 1.0;
  double _rotationY = 0.0;
  
  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        // Handle scaling start
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (details.scale * 1.0).clamp(0.5, 2.0);
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _rotationY += details.delta.dx * 0.01;
        });
      },
      child: Stack(
        children: [
          // Particle effects
          ..._buildParticleEffects(),
          
          // Main 3D model
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _rotationController,
                _bounceController,
              ]),
              builder: (context, child) {
                final bounce = sin(_bounceController.value * pi) * 10;
                
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..translate(0.0, bounce, 0.0)
                    ..rotateY(_rotationController.value * 2 * pi + _rotationY)
                    ..rotateX(0.2)
                    ..scale(_scale),
                  child: _build3DModel(),
                );
              },
            ),
          ),
          
          // Model info overlay
          _buildModelInfo(),
        ],
      ),
    );
  }

  Widget _build3DModel() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
            Colors.pink.withOpacity(0.8),
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
      child: Stack(
        children: [
          // 3D-like faces
          ..._build3DFaces(),
          
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForWord(widget.content.targetWord),
                  size: 60,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _build3DFaces() {
    return [
      // Top face
      Positioned(
        top: 0,
        left: 10,
        right: 10,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      
      // Right face
      Positioned(
        top: 10,
        right: 0,
        bottom: 10,
        width: 20,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildParticleEffects() {
    return List.generate(15, (index) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final random = Random(index);
          final angle = (_particleController.value + random.nextDouble()) * 2 * pi;
          final radius = 150 + random.nextDouble() * 50;
          final size = 3 + random.nextDouble() * 4;
          
          final x = cos(angle) * radius;
          final y = sin(angle) * radius;
          
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + x,
            top: MediaQuery.of(context).size.height / 2 + y,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildModelInfo() {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '3D Model: ${widget.content.targetWord}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Pinch to scale\n• Drag to rotate\n• Tap to interact',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForWord(String word) {
    switch (word.toLowerCase()) {
      case 'cat':
        return Icons.pets;
      case 'dog':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'apple':
        return Icons.apple;
      case 'banana':
        return Icons.eco;
      case 'water':
        return Icons.water_drop;
      case 'red':
        return Icons.palette;
      case 'blue':
        return Icons.palette;
      case 'circle':
        return Icons.circle;
      case 'hand':
        return Icons.back_hand;
      case 'eye':
        return Icons.visibility;
      default:
        return Icons.category;
    }
  }
}