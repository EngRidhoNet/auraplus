import 'dart:math';
import 'package:flutter/material.dart';

class SpeechWaveVisualizer extends StatefulWidget {
  final bool isActive;
  final List<double> speechLevels;
  final double currentVolume;
  
  const SpeechWaveVisualizer({
    super.key,
    required this.isActive,
    required this.speechLevels,
    required this.currentVolume,
  });

  @override
  State<SpeechWaveVisualizer> createState() => _SpeechWaveVisualizerState();
}

class _SpeechWaveVisualizerState extends State<SpeechWaveVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    if (widget.isActive) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(SpeechWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _waveController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: SpeechWavePainter(
            isActive: widget.isActive,
            speechLevels: widget.speechLevels,
            currentVolume: widget.currentVolume,
            animationValue: _waveController.value,
          ),
        );
      },
    );
  }
}

class SpeechWavePainter extends CustomPainter {
  final bool isActive;
  final List<double> speechLevels;
  final double currentVolume;
  final double animationValue;
  
  SpeechWavePainter({
    required this.isActive,
    required this.speechLevels,
    required this.currentVolume,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive && speechLevels.isEmpty) {
      _paintIdleWave(canvas, size);
      return;
    }

    _paintActiveWave(canvas, size);
    _paintVolumeIndicator(canvas, size);
  }

  void _paintIdleWave(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final path = Path();

    for (double x = 0; x < size.width; x += 2) {
      final normalizedX = x / size.width;
      final wave = sin((normalizedX + animationValue) * 2 * pi) * 10;
      final y = centerY + wave;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _paintActiveWave(Canvas canvas, Size size) {
    if (speechLevels.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final barWidth = size.width / speechLevels.length;
    final centerY = size.height / 2;

    for (int i = 0; i < speechLevels.length; i++) {
      final level = speechLevels[i];
      final barHeight = level * size.height * 0.4;
      final x = i * barWidth;

      // Draw waveform bar
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );

      // Add glow effect for high levels
      if (level > 0.7) {
        final glowPaint = Paint()
          ..color = Colors.green.withOpacity(0.3)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(x, centerY - barHeight / 2),
          Offset(x, centerY + barHeight / 2),
          glowPaint,
        );
      }
    }
  }

  void _paintVolumeIndicator(Canvas canvas, Size size) {
    if (!isActive) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = currentVolume * 30 + 10;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    // Draw volume rings
    for (int i = 1; i <= 3; i++) {
      final ringRadius = radius + (i * 15);
      final ringOpacity = (1.0 - (i * 0.3)) * currentVolume;

      final ringPaint = Paint()
        ..color = Colors.green.withOpacity(ringOpacity * 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(centerX, centerY), ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}