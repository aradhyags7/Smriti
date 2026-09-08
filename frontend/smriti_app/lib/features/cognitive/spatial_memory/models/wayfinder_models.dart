// ─────────────────────────────────────────────────────────────────────────────
// WAYFINDER MODELS
// Data contracts for spatial memory / navigation recall game
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Difficulty tiers for Wayfinder.
enum WayfinderDifficulty {
  simple,
  moderate,
  harder,
}

/// A landmark node on the spatial map.
class MapNode {
  final int index;
  final String label; // e.g., "Home", "Market", "Temple"
  final IconData icon;
  final double relX; // 0.0 - 1.0 relative X position
  final double relY; // 0.0 - 1.0 relative Y position
  final bool isDecoy; // Decoy nodes don't belong to the target path

  const MapNode({
    required this.index,
    required this.label,
    required this.icon,
    required this.relX,
    required this.relY,
    this.isDecoy = false,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'label': label,
        'relX': relX,
        'relY': relY,
        'isDecoy': isDecoy,
      };
}

/// Configuration for a single Wayfinder trial (one round of recall).
class WayfinderTrialConfig {
  final int trialIndex;
  final List<MapNode> allNodes; // All visible nodes (including decoys)
  final List<int> targetPath; // Correct order of node indices to recall
  final int previewDurationMs;
  final bool isRotated; // Harder mode: map rotation
  final bool isMirrored; // Harder mode: map mirroring
  final bool isReverseRecall; // Harder mode: recall in reverse order
  final int cognitiveLoad; // 1-10

  const WayfinderTrialConfig({
    required this.trialIndex,
    required this.allNodes,
    required this.targetPath,
    required this.previewDurationMs,
    this.isRotated = false,
    this.isMirrored = false,
    this.isReverseRecall = false,
    required this.cognitiveLoad,
  });
}

/// A single tap event during Wayfinder recall.
class SpatialTapEvent {
  final String tapId;
  final int timestamp;
  final double tapX;
  final double tapY;
  final double targetX;
  final double targetY;
  final double distanceError; // Euclidean distance from target center
  final int tappedNodeIndex;
  final int expectedNodeIndex;
  final bool isCorrectNode;
  final int reactionTimeMs; // Time since recall phase started or last tap

  const SpatialTapEvent({
    required this.tapId,
    required this.timestamp,
    required this.tapX,
    required this.tapY,
    required this.targetX,
    required this.targetY,
    required this.distanceError,
    required this.tappedNodeIndex,
    required this.expectedNodeIndex,
    required this.isCorrectNode,
    required this.reactionTimeMs,
  });

  Map<String, dynamic> toJson() => {
        'tapId': tapId,
        'timestamp': timestamp,
        'tapX': tapX,
        'tapY': tapY,
        'targetX': targetX,
        'targetY': targetY,
        'distanceError': distanceError,
        'tappedNodeIndex': tappedNodeIndex,
        'expectedNodeIndex': expectedNodeIndex,
        'isCorrectNode': isCorrectNode,
        'reactionTimeMs': reactionTimeMs,
      };
}

/// Difficulty parameters for each tier.
class WayfinderDifficultyParams {
  final int pathLength; // How many nodes in the target path
  final int totalNodes; // Total visible nodes (path + decoys)
  final int previewDurationMs;
  final bool enableRotation;
  final bool enableMirror;
  final bool enableReverseRecall;
  final int trialsPerSession;
  final String tierLabel;

  const WayfinderDifficultyParams({
    required this.pathLength,
    required this.totalNodes,
    required this.previewDurationMs,
    required this.enableRotation,
    required this.enableMirror,
    required this.enableReverseRecall,
    required this.trialsPerSession,
    required this.tierLabel,
  });

  /// Get the preset parameters for each difficulty level.
  /// Tuned for users aged 55+ — generous preview times, manageable node counts,
  /// and shorter sessions to support consistent, low-stress brain engagement.
  static WayfinderDifficultyParams forDifficulty(WayfinderDifficulty diff) {
    switch (diff) {
      case WayfinderDifficulty.simple:
        // Easy: 3 landmark path, no decoys, long 8s preview, short 5-trial session.
        // Success rate target: ~90% — builds confidence and habit.
        return const WayfinderDifficultyParams(
          pathLength: 3,
          totalNodes: 3, // No decoys — pure recall, zero confusion
          previewDurationMs: 8000, // 8s — comfortable for 55+ processing speed
          enableRotation: false,
          enableMirror: false,
          enableReverseRecall: false,
          trialsPerSession: 5,
          tierLabel: 'Gentle Walk',
        );
      case WayfinderDifficulty.moderate:
        // Moderate: 4-node path, 2 gentle decoys, 6s preview, 6-trial session.
        // Adds mild discrimination challenge without frustration.
        return const WayfinderDifficultyParams(
          pathLength: 4,
          totalNodes: 6, // 2 decoy nodes
          previewDurationMs: 6000, // 6s — still generous
          enableRotation: false,
          enableMirror: false,
          enableReverseRecall: false,
          trialsPerSession: 6,
          tierLabel: 'Neighbourhood Explorer',
        );
      case WayfinderDifficulty.harder:
        // Hard: 5-node path, 2 decoys, 5s preview, occasional map rotation.
        // Rotation alone adds spatial challenge — mirror + reverse are NOT stacked.
        return const WayfinderDifficultyParams(
          pathLength: 5,
          totalNodes: 7, // 2 decoy nodes
          previewDurationMs: 5000, // 5s — still manageable
          enableRotation: true,  // Mild orientation challenge
          enableMirror: false,   // Kept off — too disorienting for 55+
          enableReverseRecall: false, // Kept off — avoids dual-load spike
          trialsPerSession: 8,
          tierLabel: 'City Navigator',
        );
    }
  }
}

/// Predefined landmark sets for real-world spatial context.
class WayfinderLandmarks {
  static const List<Map<String, dynamic>> landmarks = [
    {'label': 'Home', 'icon': 'home'},
    {'label': 'Market', 'icon': 'shopping_cart'},
    {'label': 'Temple', 'icon': 'temple_hindu'},
    {'label': 'Hospital', 'icon': 'local_hospital'},
    {'label': 'Park', 'icon': 'park'},
    {'label': 'School', 'icon': 'school'},
    {'label': 'Library', 'icon': 'local_library'},
    {'label': 'Bank', 'icon': 'account_balance'},
    {'label': 'Post Office', 'icon': 'local_post_office'},
    {'label': 'Station', 'icon': 'train'},
    {'label': 'Pharmacy', 'icon': 'local_pharmacy'},
    {'label': 'Restaurant', 'icon': 'restaurant'},
  ];

  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'temple_hindu': return Icons.temple_hindu;
      case 'local_hospital': return Icons.local_hospital;
      case 'park': return Icons.park;
      case 'school': return Icons.school;
      case 'local_library': return Icons.local_library;
      case 'account_balance': return Icons.account_balance;
      case 'local_post_office': return Icons.local_post_office;
      case 'train': return Icons.train;
      case 'local_pharmacy': return Icons.local_pharmacy;
      case 'restaurant': return Icons.restaurant;
      default: return Icons.place;
    }
  }
}
