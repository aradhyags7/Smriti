// ─────────────────────────────────────────────────────────────────────────────
// WAYFINDER RESULTS SCREEN
// Spatial memory performance summary with unified JSONL export
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../telemetry/telemetry_models.dart';
import '../../telemetry/unified_data_exporter.dart';
import '../../shared/encouragement_engine.dart';
import '../engine/spatial_scoring.dart';

class WayfinderResultsScreen extends StatefulWidget {
  final CognitiveSessionEnvelope envelope;
  final List<double> trialScores;

  const WayfinderResultsScreen({
    super.key,
    required this.envelope,
    required this.trialScores,
  });

  @override
  State<WayfinderResultsScreen> createState() => _WayfinderResultsScreenState();
}

class _WayfinderResultsScreenState extends State<WayfinderResultsScreen> {
  bool _showExportModal = false;
  String _jsonlOutput = '';
  final EncouragementEngine _encouragement = EncouragementEngine();

  void _handleExportJsonl() {
    final jsonl = UnifiedDataExporter.exportSessionToJsonl(widget.envelope);
    setState(() {
      _jsonlOutput = jsonl;
      _showExportModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.envelope.sessionSummary;
    final accuracy = (summary.accuracy * 100).round();
    final spatialAcc = ((summary.spatialAccuracy ?? 0) * 100).round();
    final headline = SpatialScoring.generateSummary(
      pathScore: summary.accuracy,
      spatialAccuracy: summary.spatialAccuracy ?? 0,
      trialsCompleted: summary.totalTrials,
      totalTrials: summary.totalTrials,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Difficulty badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.envelope.difficultyLevel.name.toUpperCase()} MODE',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Wayfinder Results',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Headline card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF2DD4BF), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.explore, size: 40,
                            color: Color(0xFF2DD4BF)),
                        const SizedBox(height: 12),
                        Text(
                          '"$headline"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Session summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spatial Memory Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Path Accuracy:', '$spatialAcc%',
                            isHighlight: true),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow(
                            'Ordering Accuracy:', '$accuracy%'),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow('Paths Completed:',
                            '${summary.totalTrials}'),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow('Avg Reaction Time:',
                            '${summary.avgReactionTimeMs.round()} ms'),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow('Fatigue Events:',
                            '${summary.fatigueEventsCount}'),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow('Rest Breaks:',
                            '${summary.restBreaksTaken}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Per-trial breakdown
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Path-by-Path Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.trialScores.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final score = (entry.value * 100).round();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Path ${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: entry.value,
                                      minHeight: 10,
                                      backgroundColor:
                                          const Color(0xFF334155),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        score >= 70
                                            ? const Color(0xFF2DD4BF)
                                            : (score >= 40
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFFF87171)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$score%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: score >= 70
                                        ? const Color(0xFF2DD4BF)
                                        : (score >= 40
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFF87171)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Session encouragement
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _encouragement.getSessionCompleteMessage(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2DD4BF),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Export button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(
                          color: Color(0xFF2DD4BF), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _handleExportJsonl,
                    child: const Text(
                      'Export Session Data (.jsonl)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // JSONL Export Modal
            if (_showExportModal)
              Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxHeight: 500),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFF2DD4BF), width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Raw JSONL Export — Wayfinder',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Unified schema v2.0 • Feed directly into your AI model',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _jsonlOutput,
                                style: const TextStyle(
                                  color: Color(0xFF2DD4BF),
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF2DD4BF),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _showExportModal = false);
                          },
                          child: const Text(
                            'Close Export',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFFCBD5E1)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 20 : 18,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.bold,
            color: isHighlight
                ? const Color(0xFF2DD4BF)
                : Colors.white,
          ),
        ),
      ],
    );
  }
}
