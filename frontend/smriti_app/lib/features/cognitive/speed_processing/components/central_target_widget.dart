import 'package:flutter/material.dart';
import '../models/pulse_trainer_models.dart';

class CentralTargetWidget extends StatelessWidget {
  final String mode; // 'fixation' | 'flash' | 'choice' | 'hidden'
  final StimulusItem? activeItem;
  final StimulusItem? choiceOptionA;
  final StimulusItem? choiceOptionB;
  final double targetSizeDp;
  final void Function(StimulusItem item, TapDownDetails details)? onSelectChoice;
  final void Function(TapDownDetails details)? onPrematureTap;

  const CentralTargetWidget({
    super.key,
    required this.mode,
    this.activeItem,
    this.choiceOptionA,
    this.choiceOptionB,
    this.targetSizeDp = 110.0,
    this.onSelectChoice,
    this.onPrematureTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == 'hidden') {
      return const SizedBox(width: 140, height: 140);
    }

    if (mode == 'fixation') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onPrematureTap,
        child: SizedBox(
          width: 140,
          height: 140,
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F0FF),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
      );
    }

    if (mode == 'flash' && activeItem != null) {
      return SizedBox(
        width: 140,
        height: 140,
        child: Center(
          child: Container(
            width: targetSizeDp,
            height: targetSizeDp,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00F0FF), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Center(
              child: _buildShapeView(activeItem!),
            ),
          ),
        ),
      );
    }

    if (mode == 'choice' &&
        choiceOptionA != null &&
        choiceOptionB != null &&
        onSelectChoice != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Which image appeared in center?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChoiceButton(choiceOptionA!),
              const SizedBox(width: 16),
              _buildChoiceButton(choiceOptionB!),
            ],
          ),
        ],
      );
    }

    return const SizedBox(width: 140, height: 140);
  }

  Widget _buildChoiceButton(StimulusItem item) {
    return GestureDetector(
      onTapDown: (details) => onSelectChoice!(item, details),
      child: Semantics(
        button: true,
        label: 'Option: ${item.label}',
        child: Container(
          constraints: const BoxConstraints(minWidth: 130, minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F0FF), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSmallShapeView(item),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapeView(StimulusItem item) {
    if (item.shape == 'circle') {
      return Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFD700),
        ),
      );
    } else if (item.shape == 'square') {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    } else {
      return Text(
        item.label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }
  }

  Widget _buildSmallShapeView(StimulusItem item) {
    if (item.shape == 'circle') {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFD700),
        ),
      );
    } else if (item.shape == 'square') {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else {
      return const Icon(Icons.image, color: Colors.cyanAccent, size: 24);
    }
  }
}
