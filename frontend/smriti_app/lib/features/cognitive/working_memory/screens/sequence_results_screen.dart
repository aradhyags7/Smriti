// ─────────────────────────────────────────────────────────────────────────────
// SEQUENCE CHECK RESULTS SCREEN
// Working memory performance summary with unified JSONL export
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../telemetry/telemetry_models.dart';
import '../../telemetry/unified_data_exporter.dart';
import '../../shared/encouragement_engine.dart';
import '../engine/sequence_scoring.dart';

class SequenceResultsScreen extends StatefulWidget {
  final CognitiveSessionEnvelope envelope;
  final int maxSpan;
  final List<bool> roundResults;
  final int totalInsertions;
  final int totalOmissions;
  final int totalTranspositions;

  const SequenceResultsScreen({
    super.key,
    required this.envelope,
    required this.maxSpan,
    required this.roundResults,
    required this.totalInsertions,
    required this.totalOmissions,
    required this.totalTranspositions,
  });

  @override
  State<SequenceResultsScreen> createState() => _SequenceResultsScreenState();
}

class _SequenceResultsScreenState extends State<SequenceResultsScreen> {
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
    final wmCapacity = SequenceScoring.workingMemoryCapacity(
      maxSpan: widget.maxSpan,
      accuracy: summary.accuracy,
    );
    final headline = SequenceScoring.generateSummary(
      maxSpan: widget.maxSpan,
      accuracy: summary.accuracy,
      roundsCompleted: summary.totalTrials,
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
                          color: const Color(0xFFA78BFA),
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
                      'Sequence Results',
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
                          color: const Color(0xFFA78BFA), width: 2),
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
                        const Icon(Icons.grid_view_rounded, size: 40,
                            color: Color(0xFFA78BFA)),
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

                  // Key metrics row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Max Span',
                          '${widget.maxSpan}',
                          Icons.trending_up,
                          const Color(0xFFA78BFA),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'WM Capacity',
                          wmCapacity.toStringAsFixed(1),
                          Icons.psychology,
                          const Color(0xFF2DD4BF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Accuracy',
                          '$accuracy%',
                          Icons.check_circle,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Session summary
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
                          'Working Memory Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Rounds Completed:',
                            '${summary.totalTrials}'),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow('Correct Rounds:',
                            '${summary.correctTrials}'),
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

                  // Error breakdown
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
                          'Error Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'How your memory patterns classify',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildErrorRow(
                            'Insertions',
                            widget.totalInsertions,
                            'Extra tiles tapped',
                            const Color(0xFFF87171)),
                        const SizedBox(height: 10),
                        _buildErrorRow(
                            'Omissions',
                            widget.totalOmissions,
                            'Tiles missed',
                            const Color(0xFFF59E0B)),
                        const SizedBox(height: 10),
                        _buildErrorRow(
                            'Transpositions',
                            widget.totalTranspositions,
                            'Order swaps',
                            const Color(0xFFA78BFA)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Round-by-round results
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
                          'Round-by-Round',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.roundResults
                              .asMap()
                              .entries
                              .map((entry) {
                            final isCorrect = entry.value;
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? const Color(0xFF2DD4BF)
                                        .withValues(alpha: 0.2)
                                    : const Color(0xFFF87171)
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCorrect
                                      ? const Color(0xFF2DD4BF)
                                      : const Color(0xFFF87171),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  isCorrect
                                      ? Icons.check
                                      : Icons.close,
                                  size: 20,
                                  color: isCorrect
                                      ? const Color(0xFF2DD4BF)
                                      : const Color(0xFFF87171),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Session encouragement
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFA78BFA).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _encouragement.getSessionCompleteMessage(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA78BFA),
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
                          color: Color(0xFFA78BFA), width: 2),
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
                        color: Color(0xFFA78BFA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFFA78BFA),
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
                          color: const Color(0xFFA78BFA), width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Raw JSONL Export — Sequence Check',
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
                                  color: Color(0xFFA78BFA),
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
                            backgroundColor: const Color(0xFFA78BFA),
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

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
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
                ? const Color(0xFFA78BFA)
                : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRow(
      String label, int count, String description, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
