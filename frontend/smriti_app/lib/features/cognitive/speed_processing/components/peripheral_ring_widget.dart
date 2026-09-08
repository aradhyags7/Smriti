import 'dart:math';
import 'package:flutter/material.dart';

class PeripheralRingWidget extends StatelessWidget {
  final String mode; // 'idle' | 'flash' | 'interactive'
  final List<int> positionsDegree;
  final int? flashedIndex;
  final int? distractorIndex;
  final int? selectedIndex;
  final double targetSizeDp;
  final double radius;
  final void Function(
          int index, int degree, TapDownDetails details, double x, double y)?
      onSelectPosition;

  const PeripheralRingWidget({
    super.key,
    required this.mode,
    this.positionsDegree = const [0, 45, 90, 135, 180, 225, 270, 315],
    this.flashedIndex,
    this.distractorIndex,
    this.selectedIndex,
    this.targetSizeDp = 52.0,
    this.radius = 120.0,
    this.onSelectPosition,
  });

  @override
  Widget build(BuildContext context) {
    final double containerSize = radius * 2 + 60;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(positionsDegree.length, (index) {
          final degree = positionsDegree[index];
          final angleRad = (degree - 90) * (pi / 180);
          final x = radius * cos(angleRad);
          final y = radius * sin(angleRad);

          final isFlashed = mode == 'flash' && flashedIndex == index;
          final isDistractor = mode == 'flash' && distractorIndex == index;
          final isSelected = selectedIndex == index;

          Color bgColor = const Color(0xFF1E293B);
          Color borderColor = const Color(0xFF475569);
          double borderWidth = 2.0;
          double scale = 1.0;

          if (isFlashed) {
            bgColor = const Color(0xFFFFD700); // Yellow target flash
            borderColor = Colors.white;
            borderWidth = 4.0;
            scale = 1.15;
          } else if (isDistractor) {
            bgColor = const Color(0xFFEF4444); // Red distractor flash
            borderColor = Colors.white;
            borderWidth = 3.0;
          } else if (isSelected) {
            bgColor = const Color(0xFF00F0FF); // Cyan selected
            borderColor = Colors.white;
            borderWidth = 4.0;
          }

          final touchSize = max(targetSizeDp, 48.0);

          return Transform.translate(
            offset: Offset(x, y),
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: mode == 'interactive' && onSelectPosition != null
                    ? (details) =>
                        onSelectPosition!(index, degree, details, x, y)
                    : null,
                child: Semantics(
                  button: true,
                  enabled: mode == 'interactive',
                  label: 'Ring position at $degree degrees',
                  child: Container(
                    width: touchSize,
                    height: touchSize,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: borderWidth),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFlashed
                              ? const Color(0xFF1E293B)
                              : (isDistractor
                                  ? Colors.white
                                  : (isSelected
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
