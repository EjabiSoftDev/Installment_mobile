import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class CustomPatternLock extends StatefulWidget {
  final bool isArabic;
  final String title;
  final String subtitle;
  final Function(List<int>) onPatternComplete;
  final VoidCallback onCancel;

  const CustomPatternLock({
    super.key,
    required this.isArabic,
    required this.title,
    required this.subtitle,
    required this.onPatternComplete,
    required this.onCancel,
  });

  @override
  State<CustomPatternLock> createState() => _CustomPatternLockState();
}

class _CustomPatternLockState extends State<CustomPatternLock> {
  List<int> pattern = [];
  List<Offset> dotPositions = [];
  List<bool> dotSelected = List.filled(9, false);
  Offset? currentPosition;
  bool isDrawing = false;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    statusMessage = widget.isArabic 
        ? 'ارسم نمطاً جديداً'
        : 'Draw a new pattern';
  }

  void _initializeDotPositions(Size drawingAreaSize) {
    final centerX = drawingAreaSize.width / 2;
    final centerY = drawingAreaSize.height / 2;
    final spacing = 80.0;

    dotPositions.clear();
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x = centerX + (col - 1) * spacing;
        final y = centerY + (row - 1) * spacing;
        dotPositions.add(Offset(x, y));
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    final touchPoint = details.localPosition;
    final dotIndex = _getDotAtPosition(touchPoint);
    
    if (dotIndex != -1) {
      setState(() {
        isDrawing = true;
        pattern.clear();
        dotSelected = List.filled(9, false);
        pattern.add(dotIndex);
        dotSelected[dotIndex] = true;
        currentPosition = touchPoint;
        statusMessage = widget.isArabic ? 'استمر في الرسم...' : 'Continue drawing...';
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!isDrawing) return;

    final touchPoint = details.localPosition;
    final dotIndex = _getDotAtPosition(touchPoint);

    setState(() {
      currentPosition = touchPoint;
      
      if (dotIndex != -1 && !dotSelected[dotIndex]) {
        pattern.add(dotIndex);
        dotSelected[dotIndex] = true;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!isDrawing) return;

    setState(() {
      isDrawing = false;
      currentPosition = null;
    });

    if (pattern.length >= 4) {
      setState(() {
        statusMessage = widget.isArabic 
            ? 'تم حفظ النمط بنجاح!'
            : 'Pattern saved successfully!';
      });
      
      // Delay before calling callback to show success message
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onPatternComplete(pattern);
        }
      });
    } else {
      setState(() {
        statusMessage = widget.isArabic 
            ? 'النمط قصير جداً. يجب أن يحتوي على 4 نقاط على الأقل'
            : 'Pattern too short. Must contain at least 4 dots';
        pattern.clear();
        dotSelected = List.filled(9, false);
      });
    }
  }

  int _getDotAtPosition(Offset position) {
    for (int i = 0; i < dotPositions.length; i++) {
      final distance = (dotPositions[i] - position).distance;
      if (distance < 30) { // Touch radius
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final ui.TextDirection direction = widget.isArabic 
        ? ui.TextDirection.rtl 
        : ui.TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B82FF),
          foregroundColor: Colors.white,
          title: Text(widget.title),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onCancel,
          ),
        ),
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF2F6FF), Color(0xFFE3F2FD)],
                  ),
                ),
              ),
            ),
            
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pattern,
                          size: 64,
                          color: const Color(0xFF0B82FF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isArabic 
                              ? 'اربط 4 نقاط على الأقل'
                              : 'Connect at least 4 dots',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Pattern drawing area
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Initialize dot positions based on available drawing area
                        if (dotPositions.isEmpty) {
                          _initializeDotPositions(constraints.biggest);
                        }
                        
                        return GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: Container(
                            width: double.infinity,
                            child: CustomPaint(
                              painter: PatternPainter(
                                dotPositions: dotPositions,
                                pattern: pattern,
                                dotSelected: dotSelected,
                                currentPosition: currentPosition,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Status message
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: statusMessage.contains('success') || statusMessage.contains('بنجاح')
                            ? Colors.green
                            : statusMessage.contains('short') || statusMessage.contains('قصير')
                            ? Colors.red
                            : const Color(0xFF0B82FF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                pattern.clear();
                                dotSelected = List.filled(9, false);
                                statusMessage = widget.isArabic 
                                    ? 'ارسم نمطاً جديداً'
                                    : 'Draw a new pattern';
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(widget.isArabic ? 'إعادة تعيين' : 'Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onCancel,
                            icon: const Icon(Icons.close),
                            label: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<int> pattern;
  final List<bool> dotSelected;
  final Offset? currentPosition;

  PatternPainter({
    required this.dotPositions,
    required this.pattern,
    required this.dotSelected,
    this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dotPositions.isEmpty) return;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill;
    
    final selectedDotPaint = Paint()
      ..color = const Color(0xFF0B82FF)
      ..style = PaintingStyle.fill;
    
    final linePaint = Paint()
      ..color = const Color(0xFF0B82FF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dots
    for (int i = 0; i < dotPositions.length; i++) {
      final paint = dotSelected[i] ? selectedDotPaint : dotPaint;
      paint.color = dotSelected[i] 
          ? const Color(0xFF0B82FF)
          : Colors.grey.shade400;
      
      canvas.drawCircle(dotPositions[i], 20, paint);
      
      // Draw inner circle for selected dots
      if (dotSelected[i]) {
        final innerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(dotPositions[i], 8, innerPaint);
      }
    }

    // Draw lines between connected dots
    if (pattern.length > 1) {
      for (int i = 0; i < pattern.length - 1; i++) {
        final start = dotPositions[pattern[i]];
        final end = dotPositions[pattern[i + 1]];
        canvas.drawLine(start, end, linePaint);
      }
    }

    // Draw line to current finger position
    if (currentPosition != null && pattern.isNotEmpty) {
      final lastDot = dotPositions[pattern.last];
      final tempLinePaint = Paint()
        ..color = const Color(0xFF0B82FF).withOpacity(0.5)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(lastDot, currentPosition!, tempLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}