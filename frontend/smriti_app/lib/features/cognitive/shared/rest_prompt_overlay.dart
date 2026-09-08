// ─────────────────────────────────────────────────────────────────────────────
// REST PROMPT OVERLAY
// Reusable overlay widget for automatic rest breaks with breathing exercise
// Protects patients from cognitive fatigue
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'haptic_feedback.dart';

class RestPromptOverlay extends StatefulWidget {
  final String message;
  final int restDurationSeconds;
  final VoidCallback onRestComplete;

  const RestPromptOverlay({
    super.key,
    required this.message,
    this.restDurationSeconds = 30,
    required this.onRestComplete,
  });

  @override
  State<RestPromptOverlay> createState() => _RestPromptOverlayState();
}

class _RestPromptOverlayState extends State<RestPromptOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.restDurationSeconds;

    // Breathing circle animation — 4s inhale, 4s exhale
    _breathController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    SmritiHaptics.gentlePulse();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        SmritiHaptics.lightTap();
        widget.onRestComplete();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breathPhase = _breathController.value < 0.5 ? 'Breathe In...' : 'Breathe Out...';

    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rest icon
              const Icon(
                Icons.self_improvement,
                size: 56,
                color: Color(0xFF00F0FF),
              ),
              const SizedBox(height: 20),

              // Message
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Breathing circle
              AnimatedBuilder(
                animation: _breathAnimation,
                builder: (context, child) {
                  return Container(
                    width: 120 * _breathAnimation.value,
                    height: 120 * _breathAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        breathPhase,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Countdown
              Text(
                'Resuming in $_remainingSeconds s',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),

              // Skip button (patient can resume early)
              TextButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  widget.onRestComplete();
                },
                child: const Text(
                  'I\'m ready — continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00F0FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
