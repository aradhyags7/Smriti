import 'package:flutter/material.dart';
import '../models/pulse_trainer_models.dart';
import '../storage/data_exporter.dart';

class PulseTrainerResultsScreen extends StatefulWidget {
  final PulseTrainerSessionData sessionData;

  const PulseTrainerResultsScreen({super.key, required this.sessionData});

  @override
  State<PulseTrainerResultsScreen> createState() =>
      _PulseTrainerResultsScreenState();
}

class _PulseTrainerResultsScreenState
    extends State<PulseTrainerResultsScreen> {
  bool _showExportModal = false;
  String _jsonlOutput = '';

  String _getHeadlineMessage(int ms) {
    if (ms <= 150) {
      return 'You can now spot something flashing for just ${ms}ms — as fast as a camera shutter!';
    }
    if (ms <= 200) {
      return 'You can now spot something flashing for just ${ms}ms — faster than an eye blink.';
    }
    if (ms <= 300) {
      return 'You can spot something flashing for ${ms}ms — sharp reaction time!';
    }
    if (ms <= 500) {
      return 'You noticed quick flashes at ${ms}ms — steady speed!';
    }
    return 'Great effort! You tracked flashes at ${ms}ms. Practice builds speed!';
  }

  void _handleExportJsonl() {
    final jsonl = DataExporter.exportSessionToJsonl(widget.sessionData);
    setState(() {
      _jsonlOutput = jsonl;
      _showExportModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trials = widget.sessionData.trials;
    final totalTrials = trials.length;
    final fullyCorrectCount = trials.where((t) => t.isCorrect).length;
    final overallAccuracy =
        totalTrials > 0 ? ((fullyCorrectCount / totalTrials) * 100).round() : 0;
    final headline = _getHeadlineMessage(widget.sessionData.thresholdMs);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.sessionData.difficultyLevel.name.toUpperCase()} MODE',
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
                      'Your Results',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // P11 Plain Language Headline Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Text(
                      '"$headline"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Research Session Breakdown Card
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
                          'Research Session Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Processing Speed Threshold:',
                          '${widget.sessionData.thresholdMs} ms',
                          isHighlight: true,
                        ),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow(
                          'Combined Overall Accuracy:',
                          '$overallAccuracy%',
                        ),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow(
                          'Raw Event Logs Captured:',
                          '$totalTrials events',
                        ),
                        const Divider(color: Color(0xFF334155), height: 24),
                        _buildStatRow(
                          'Difficulty Level:',
                          widget.sessionData.difficultyLevel.name.toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Color(0xFF00F0FF), width: 2),
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
                        color: Color(0xFF00F0FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF00F0FF),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // P9 JSONL Export Modal Dialog
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
                      border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Raw JSONL Event Export',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Offline raw event stream (1 event per line). No cloud uploads.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
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
                                  color: Color(0xFF00F0FF),
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF00F0FF),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showExportModal = false;
                            });
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
      {bool isHighlight = false, bool isSubtle = false}) {
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
                ? const Color(0xFF00F0FF)
                : (isSubtle ? const Color(0xFF94A3B8) : Colors.white),
          ),
        ),
      ],
    );
  }
}
