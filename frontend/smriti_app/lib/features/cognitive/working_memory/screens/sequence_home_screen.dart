import 'package:flutter/material.dart';
import '../models/sequence_check_models.dart';
import 'sequence_session_screen.dart';
import '../../../../theme/smriti_theme.dart';

class SequenceHomeScreen extends StatelessWidget {
  const SequenceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmritiTheme.backgroundWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: SmritiTheme.forestGreen, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 8),

              // Header
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  size: 40,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Sequence Check',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: SmritiTheme.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Watch visual patterns, then repeat\nthem in correct sequence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: SmritiTheme.textSubtle,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Text(
                    '🧠 Trains: Working Memory & Pattern Span',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Difficulty cards
              _buildDifficultyCard(
                context,
                difficulty: SequenceDifficulty.simple,
                title: 'Easy — Pattern Start',
                subtitle: 'Build memory gently',
                description: '3×3 grid · 2–4 tiles · 900ms flash · 8 rounds',
                brainBenefit: '🧠 Activates short-term memory pathways',
                icon: Icons.looks_one_rounded,
                accentColor: const Color(0xFF0D9488),
                bgColor: const Color(0xFFE6F4F1),
              ),
              const SizedBox(height: 16),

              _buildDifficultyCard(
                context,
                difficulty: SequenceDifficulty.moderate,
                title: 'Moderate — Pattern Builder',
                subtitle: 'A satisfying stretch',
                description: '3×3 grid · 3–5 tiles · 700ms flash · 10 rounds',
                brainBenefit: '🧠 Expands working memory span',
                icon: Icons.looks_two_rounded,
                accentColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
              ),
              const SizedBox(height: 16),

              _buildDifficultyCard(
                context,
                difficulty: SequenceDifficulty.harder,
                title: 'Hard — Pattern Challenge',
                subtitle: 'Push your recall further',
                description: '3×3 grid · 3–6 tiles · 550ms flash · 12 rounds',
                brainBenefit: '🧠 Strengthens concentration & recall speed',
                icon: Icons.looks_3_rounded,
                accentColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF3E8FF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context, {
    required SequenceDifficulty difficulty,
    required String title,
    required String subtitle,
    required String description,
    required String brainBenefit,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Card(
      elevation: 0,
      color: SmritiTheme.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SmritiTheme.cardBorder, width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SequenceSessionScreen(difficulty: difficulty),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: SmritiTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
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
                    const SizedBox(height: 6),
                    Text(
                      brainBenefit,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: SmritiTheme.forestGreen),
            ],
          ),
        ),
      ),
    );
  }
}
