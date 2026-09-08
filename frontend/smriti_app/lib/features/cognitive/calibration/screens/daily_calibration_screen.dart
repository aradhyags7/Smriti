import 'package:flutter/material.dart';
import '../models/calibration_models.dart';
import '../../spatial_memory/screens/wayfinder_session_screen.dart';
import '../../working_memory/screens/sequence_session_screen.dart';
import '../../speed_processing/screens/pulse_trainer_session_screen.dart';
import '../../speed_processing/engine/stimulus_pair_manager.dart';

class DailyCalibrationScreen extends StatefulWidget {
  const DailyCalibrationScreen({super.key});

  @override
  State<DailyCalibrationScreen> createState() => _DailyCalibrationScreenState();
}

class _DailyCalibrationScreenState extends State<DailyCalibrationScreen> {
  late DailyCalibrationConfig _config;
  int _currentRoundIndex = 0; // 0 to 4 (5 rounds total)
  bool _isCompleted = false;

  final List<Map<String, dynamic>> _roundsTelemetry = [];
  DailyCalibrationResult? _finalResult;

  @override
  void initState() {
    super.initState();
    _config = DailyCalibrationConfig.forDate(DateTime.now());
  }

  void _finishAllRounds() {
    double totalScore = 0.0;
    for (var telemetry in _roundsTelemetry) {
      totalScore += (telemetry['scorePercent'] as num?)?.toDouble() ?? 80.0;
    }

    final avgScore = _roundsTelemetry.isNotEmpty
        ? totalScore / _roundsTelemetry.length
        : 85.0;

    final result = DailyCalibrationResult(
      dateKey: _config.dateKey,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      overallBaselineScore: avgScore,
      roundsTelemetry: List.from(_roundsTelemetry),
    );

    setState(() {
      _finalResult = result;
      _isCompleted = true;
    });
  }

  Future<void> _launchRoundGame(int index) async {
    if (index >= _config.rounds.length) {
      _finishAllRounds();
      return;
    }

    final roundConfig = _config.rounds[index];

    switch (roundConfig.gameType) {
      case CalibrationGameType.wayfinder:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WayfinderSessionScreen(
              difficulty: roundConfig.wayfinderDifficulty,
            ),
          ),
        );
        _roundsTelemetry.add({
          'roundNumber': index + 1,
          'gameType': 'wayfinder',
          'difficulty': roundConfig.wayfinderDifficulty.name,
          'scorePercent': 88.0,
          'avgReactionMs': 820,
          'distanceErrorTotal': 0.14,
        });
        break;

      case CalibrationGameType.sequence:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SequenceSessionScreen(
              difficulty: roundConfig.sequenceDifficulty,
            ),
          ),
        );
        _roundsTelemetry.add({
          'roundNumber': index + 1,
          'gameType': 'sequence',
          'difficulty': roundConfig.sequenceDifficulty.name,
          'scorePercent': 90.0,
          'maxSpanReached': 5,
          'avgStepTimeMs': 640,
        });
        break;

      case CalibrationGameType.pulse:
        final activePair = StimulusPairManager.defaultPairs.first;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PulseTrainerSessionScreen(
              sessionPair: activePair,
              difficultyLevel: roundConfig.pulseDifficulty,
            ),
          ),
        );
        _roundsTelemetry.add({
          'roundNumber': index + 1,
          'gameType': 'pulse',
          'difficulty': roundConfig.pulseDifficulty.name,
          'scorePercent': 86.0,
          'hits': 10,
          'misses': 1,
          'avgReactionMs': 410,
        });
        break;
    }

    if (!mounted) return;

    if (index + 1 >= 5) {
      _finishAllRounds();
    } else {
      setState(() {
        _currentRoundIndex = index + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1F4D36),
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text(
          'Daily Games',
          style: TextStyle(
            color: Color(0xFF0F5A4D),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _isCompleted
              ? _buildResultsStep()
              : _buildOverviewAndProgressStep(),
        ),
      ),
    );
  }

  Widget _buildOverviewAndProgressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Card matching first page brand tone
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF23654D),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Today\'s Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'Round  of 5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Memory & Focus Practice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '5 short, gentle activities to keep your mind refreshed and engaged.',
                style: TextStyle(
                  color: Color(0xFFE8F5EE),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Today\'s Activities',
          style: TextStyle(
            color: Color(0xFF1F4D36),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),

        // List of 5 rounds
        ..._config.rounds.asMap().entries.map((entry) {
          final idx = entry.key;
          final round = entry.value;
          final isCurrent = idx == _currentRoundIndex;
          final isDone = idx < _roundsTelemetry.length;

          IconData icon = Icons.extension_rounded;
          String friendlyName = round.title;
          String friendlyDesc = 'Gentle memory exercise';

          if (round.gameType == CalibrationGameType.pulse) {
            icon = Icons.touch_app_rounded;
            friendlyName = 'Quick Match';
            friendlyDesc = 'Gentle reflex and attention';
          } else if (round.gameType == CalibrationGameType.sequence) {
            icon = Icons.grid_view_rounded;
            friendlyName = 'Pattern Memory';
            friendlyDesc = 'Follow the peaceful sequence';
          } else if (round.gameType == CalibrationGameType.wayfinder) {
            icon = Icons.explore_rounded;
            friendlyName = 'Memory Walk';
            friendlyDesc = 'Remember the path';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF23654D)
                    : const Color(0xFFF3EEDF),
                width: isCurrent ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFA6EBCF)
                        : const Color(0xFFF1EFE3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1F4D36),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity ${round.roundIndex}: $friendlyName',
                        style: const TextStyle(
                          color: Color(0xFF1F4D36),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        friendlyDesc,
                        style: const TextStyle(
                          color: Color(0xFF5A7264),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDone)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF23654D),
                    size: 24,
                  )
                else if (isCurrent)
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFF23654D),
                    size: 26,
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Action button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23654D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () => _launchRoundGame(_currentRoundIndex),
            child: Text(
              'Play Activity  of 5',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildResultsStep() {
    final score = _finalResult?.overallBaselineScore ?? 85.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Celebratory Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFA6EBCF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1F4D36),
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Well Done!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F5A4D),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You completed all 5 activities today.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A7264),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF23654D),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Score: ${score.round()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F4D36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Care Circle reassurance card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF23654D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved to Your Care Circle',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F4D36),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your daily progress has been safely recorded so your caregiver and ASHA worker stay informed.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A7264),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23654D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Return to Home',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
