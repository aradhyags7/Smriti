import 'package:flutter/material.dart';
import '../features/cognitive/calibration/screens/daily_calibration_screen.dart';
import '../theme/smriti_theme.dart';

class DailyGamesScreen extends StatelessWidget {
  const DailyGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: SmritiTheme.backgroundWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Header Brand Section with Back Button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: SmritiTheme.forestGreen),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back to Home',
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: SmritiTheme.forestGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            size: 30,
                            color: SmritiTheme.forestGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smriti',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: SmritiTheme.forestGreen,
                                    fontSize: 30,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const Text(
                              'Gentle Memory Care',
                              style: TextStyle(
                                fontSize: 13,
                                color: SmritiTheme.textSubtle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),

              // Welcome / Daily Games Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SmritiTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SmritiTheme.cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Games \u{1F338}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: SmritiTheme.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SmritiTheme.mintSoftBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Daily Baseline',
                            style: TextStyle(
                              color: SmritiTheme.forestGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your daily gentle exercise battery to measure cognitive baseline and track memory health over time.',
                      style: TextStyle(
                        fontSize: 14,
                        color: SmritiTheme.textSubtle,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Featured Hero Card: Daily Calibration Test (ONLY game here!)
              Card(
                elevation: 0,
                color: SmritiTheme.cardWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: SmritiTheme.forestGreen, width: 2),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DailyCalibrationScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SmritiTheme.mintSoftBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stars_rounded,
                                      size: 14, color: SmritiTheme.forestGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    "Today's Primary Exercise",
                                    style: TextStyle(
                                      color: SmritiTheme.forestGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Seed: $dateString',
                              style: const TextStyle(
                                color: SmritiTheme.textSubtle,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Icon
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: SmritiTheme.mintSoftBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.published_with_changes_rounded,
                                size: 30,
                                color: SmritiTheme.forestGreen,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Calibration Test',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: SmritiTheme.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '24-Hour Seeded Baseline Test',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: SmritiTheme.forestGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        const Text(
                          'A 5-round gentle battery that refreshes every 24 hours. Evaluates spatial recall, working memory sequences, and reaction speed with soothing soundscapes.',
                          style: TextStyle(
                            fontSize: 13,
                            color: SmritiTheme.textSubtle,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rounds preview chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildRoundChip('Round 1 & 5', 'Spatial Recall',
                                Icons.explore_rounded, const Color(0xFF0D9488)),
                            _buildRoundChip('Round 2 & 4', 'Sequence Memory',
                                Icons.grid_view_rounded, const Color(0xFF7C3AED)),
                            _buildRoundChip('Round 3', 'Reaction Speed',
                                Icons.flash_on_rounded, const Color(0xFFD97706)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SmritiTheme.forestGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DailyCalibrationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_circle_filled_rounded,
                                color: Colors.white, size: 22),
                            label: const Text(
                              'Start Daily Calibration Test',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Clinician tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SmritiTheme.mintSoftBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: SmritiTheme.forestGreen.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded,
                        color: SmritiTheme.forestGreen, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completing your Daily Calibration Test once every morning provides your ASHA Worker and Caregiver with accurate clinical telemetry to support your well-being.',
                        style: TextStyle(
                          fontSize: 13,
                          color: SmritiTheme.textDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRoundChip(
      String round, String name, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$round: $name',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
