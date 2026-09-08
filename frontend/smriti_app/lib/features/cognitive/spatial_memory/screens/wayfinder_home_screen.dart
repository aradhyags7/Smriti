import 'package:flutter/material.dart';
import '../models/wayfinder_models.dart';
import 'wayfinder_session_screen.dart';
import '../../../../theme/smriti_theme.dart';

class WayfinderHomeScreen extends StatelessWidget {
  const WayfinderHomeScreen({super.key});

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
                  color: SmritiTheme.mintSoftBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 40,
                  color: SmritiTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Wayfinder',
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
                  'Navigate landmark paths from memory\nwith calming soundscapes',
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
                    color: SmritiTheme.mintSoftBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SmritiTheme.mintAccent),
                  ),
                  child: const Text(
                    '🧠 Trains: Spatial Memory & Orientation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: SmritiTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Difficulty cards
              _buildDifficultyCard(
                context,
                difficulty: WayfinderDifficulty.simple,
                title: 'Easy — Gentle Walk',
                subtitle: 'Start your brain journey',
                description: '3 landmarks · 8s preview · No decoys · 5 rounds',
                brainBenefit: '🧠 Builds spatial recall & confidence',
                icon: Icons.directions_walk_rounded,
                accentColor: const Color(0xFF0D9488),
                bgColor: const Color(0xFFE6F4F1),
              ),
              const SizedBox(height: 16),

              _buildDifficultyCard(
                context,
                difficulty: WayfinderDifficulty.moderate,
                title: 'Moderate — Neighbourhood Explorer',
                subtitle: 'A little more to remember',
                description: '4 landmarks · 6s preview · 2 decoys · 6 rounds',
                brainBenefit: '🧠 Strengthens landmark discrimination',
                icon: Icons.map_rounded,
                accentColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
              ),
              const SizedBox(height: 16),

              _buildDifficultyCard(
                context,
                difficulty: WayfinderDifficulty.harder,
                title: 'Hard — City Navigator',
                subtitle: 'Your spatial memory challenge',
                description: '5 landmarks · 5s preview · 2 decoys · mild rotation · 8 rounds',
                brainBenefit: '🧠 Sharpens orientation & route planning',
                icon: Icons.explore_rounded,
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
    required WayfinderDifficulty difficulty,
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
              builder: (context) => WayfinderSessionScreen(difficulty: difficulty),
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
