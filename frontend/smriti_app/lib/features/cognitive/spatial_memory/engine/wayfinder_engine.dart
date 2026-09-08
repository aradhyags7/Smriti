// ─────────────────────────────────────────────────────────────────────────────
// WAYFINDER ENGINE
// Path generation, map transformations, and adaptive preview timing
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wayfinder_models.dart';

class WayfinderEngine {
  final Random _random = Random();
  final WayfinderDifficultyParams params;

  WayfinderEngine({required this.params});

  /// Generate a complete trial configuration with randomized node placement.
  WayfinderTrialConfig generateTrial({
    required int trialIndex,
    int? adjustedPreviewMs,
  }) {
    // Generate node positions with minimum spacing constraint
    final positions = _generatePositions(params.totalNodes, minSpacing: 0.18);

    // Select landmark labels
    final shuffledLandmarks = List<Map<String, dynamic>>.from(
        WayfinderLandmarks.landmarks)
      ..shuffle(_random);

    final allNodes = <MapNode>[];
    final pathIndices = <int>[];

    for (int i = 0; i < params.totalNodes; i++) {
      final isDecoy = i >= params.pathLength;
      final landmark = shuffledLandmarks[i % shuffledLandmarks.length];

      allNodes.add(MapNode(
        index: i,
        label: landmark['label'] as String,
        icon: WayfinderLandmarks.getIcon(landmark['icon'] as String),
        relX: positions[i].dx,
        relY: positions[i].dy,
        isDecoy: isDecoy,
      ));

      if (!isDecoy) {
        pathIndices.add(i);
      }
    }

    // Shuffle path order for target recall
    pathIndices.shuffle(_random);

    // Determine map transformations for harder mode
    final bool isRotated = params.enableRotation && _random.nextBool();
    final bool isMirrored = params.enableMirror && _random.nextBool();
    final bool isReverse =
        params.enableReverseRecall && trialIndex >= 5 && _random.nextBool();

    // Calculate cognitive load (1-10)
    int cogLoad = 3;
    cogLoad += (params.pathLength - 4).clamp(0, 3);
    if (isRotated) cogLoad += 1;
    if (isMirrored) cogLoad += 1;
    if (isReverse) cogLoad += 2;
    cogLoad = cogLoad.clamp(1, 10);

    return WayfinderTrialConfig(
      trialIndex: trialIndex,
      allNodes: allNodes,
      targetPath: isReverse ? pathIndices.reversed.toList() : pathIndices,
      previewDurationMs: adjustedPreviewMs ?? params.previewDurationMs,
      isRotated: isRotated,
      isMirrored: isMirrored,
      isReverseRecall: isReverse,
      cognitiveLoad: cogLoad,
    );
  }

  /// Generate N random positions on a 0.0-1.0 grid with minimum spacing.
  List<Offset> _generatePositions(int count, {double minSpacing = 0.18}) {
    final positions = <Offset>[];
    int attempts = 0;
    const maxAttempts = 500;

    while (positions.length < count && attempts < maxAttempts) {
      attempts++;
      // Keep within safe margins (10% padding from edges)
      final x = 0.1 + _random.nextDouble() * 0.8;
      final y = 0.1 + _random.nextDouble() * 0.8;
      final candidate = Offset(x, y);

      // Check minimum distance from all existing positions
      bool tooClose = false;
      for (final existing in positions) {
        final dist = (candidate - existing).distance;
        if (dist < minSpacing) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        positions.add(candidate);
      }
    }

    // Fallback: if we couldn't place all nodes, use grid layout
    if (positions.length < count) {
      positions.clear();
      final cols = (sqrt(count) + 0.5).ceil();
      final rows = (count / cols).ceil();
      for (int i = 0; i < count; i++) {
        final col = i % cols;
        final row = i ~/ cols;
        positions.add(Offset(
          0.15 + (col / (cols - 1).clamp(1, cols)) * 0.7,
          0.15 + (row / (rows - 1).clamp(1, rows)) * 0.7,
        ));
      }
    }

    return positions;
  }

  /// Compute adaptive preview duration based on recent performance.
  /// Good performance → shorter preview. Struggling → longer preview.
  int computeAdaptivePreview(int baseMs, double rollingAccuracy) {
    if (rollingAccuracy >= 0.85) {
      // Performing well → reduce preview (but not below 2s)
      return (baseMs * 0.85).clamp(2000, 10000).round();
    } else if (rollingAccuracy <= 0.50) {
      // Struggling → extend preview (up to 8s)
      return (baseMs * 1.25).clamp(2000, 8000).round();
    }
    return baseMs;
  }
}
