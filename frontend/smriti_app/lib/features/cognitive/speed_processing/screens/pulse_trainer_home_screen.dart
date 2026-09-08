import 'package:flutter/material.dart';
import '../engine/stimulus_pair_manager.dart';
import '../models/pulse_trainer_models.dart';
import 'pulse_trainer_session_screen.dart';
import '../../../../theme/smriti_theme.dart';

class PulseTrainerHomeScreen extends StatefulWidget {
  const PulseTrainerHomeScreen({super.key});

  @override
  State<PulseTrainerHomeScreen> createState() => _PulseTrainerHomeScreenState();
}

class _PulseTrainerHomeScreenState extends State<PulseTrainerHomeScreen> {
  late StimulusPair _activePair;
  DifficultyLevel _selectedLevel = DifficultyLevel.moderate;

  @override
  void initState() {
    super.initState();
    final manager = StimulusPairManager();
    _activePair = manager.getNextSessionPair();
  }

  void _handleStart(DifficultyLevel level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PulseTrainerSessionScreen(
          sessionPair: _activePair,
          difficultyLevel: level,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmritiTheme.backgroundWarm,
      appBar: AppBar(
        title: const Text('Pulse Trainer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: SmritiTheme.forestGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  size: 40,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Pulse Trainer',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: SmritiTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'React to gentle visual stimuli to measure and improve processing speed',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: SmritiTheme.textSubtle),
                ),
              ),
              const SizedBox(height: 24),

              // Difficulty Cards Selection
              _buildDifficultyCard(
                level: DifficultyLevel.simple,
                title: 'Easy — Calm Reflexes',
                badgeColor: const Color(0xFF0D9488),
                trialsText: '10 Gentle Trials',
                speedText: 'Relaxed pace (1200ms → 700ms)',
                description: '4 cardinal positions. Pure visual recognition, no distractors.',
                brainBenefit: '🧠 Trains reaction time & visual attention',
                icon: Icons.looks_one_rounded,
              ),
              const SizedBox(height: 14),

              _buildDifficultyCard(
                level: DifficultyLevel.moderate,
                title: 'Moderate — Steady Focus',
                badgeColor: const Color(0xFFD97706),
                trialsText: '12 Focus Trials',
                speedText: 'Comfortable pace (900ms → 550ms)',
                description: '4 positions with gentle stop signals & mild distractors.',
                brainBenefit: '🧠 Builds inhibitory control & focus',
                icon: Icons.looks_two_rounded,
              ),
              const SizedBox(height: 14),

              _buildDifficultyCard(
                level: DifficultyLevel.harder,
                title: 'Hard — Sharp Mind',
                badgeColor: const Color(0xFF7C3AED),
                trialsText: '15 Challenge Trials',
                speedText: 'Brisk pace (700ms → 400ms)',
                description: '8 ring positions with stop signals & distractors.',
                brainBenefit: '🧠 Sharpens processing speed & attention',
                icon: Icons.looks_3_rounded,
              ),

              const SizedBox(height: 28),

              // Action Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmritiTheme.forestGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _handleStart(_selectedLevel),
                  child: Text(
                    'Start ${_selectedLevel.name.toUpperCase()} Session',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard({
    required DifficultyLevel level,
    required String title,
    required Color badgeColor,
    required String trialsText,
    required String speedText,
    required String description,
    required String brainBenefit,
    required IconData icon,
  }) {
    final isSelected = _selectedLevel == level;

    return Card(
      elevation: 0,
      color: SmritiTheme.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? SmritiTheme.forestGreen : SmritiTheme.cardBorder,
          width: isSelected ? 2.5 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLevel = level;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: badgeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: SmritiTheme.textDark,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: SmritiTheme.forestGreen, size: 22),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$trialsText • $speedText',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SmritiTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      brainBenefit,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
