import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pulse_trainer_screen.dart';
import '../features/cognitive/spatial_memory/screens/wayfinder_home_screen.dart';
import '../features/cognitive/working_memory/screens/sequence_home_screen.dart';
import '../features/cognitive/telemetry/unified_data_exporter.dart';
import '../features/cognitive/telemetry/telemetry_engine.dart';
import '../features/cognitive/calibration/screens/daily_calibration_screen.dart';
import '../theme/smriti_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmritiTheme.backgroundWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // ── Header Brand Section ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: SmritiTheme.forestGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 32,
                      color: SmritiTheme.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smriti',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: SmritiTheme.forestGreen,
                              fontSize: 32,
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
              const SizedBox(height: 24),

              // Welcome Banner
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
                          'Good Morning 🌸',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: SmritiTheme.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SmritiTheme.mintSoftBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Calm Care',
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
                      'Choose a gentle cognitive exercise below to keep your mind sharp and active.',
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

              // ── 24-Hour Daily Calibration Test Card ──
              _buildGameCard(
                context,
                title: 'Daily Calibration Test',
                subtitle: '24-Hour Seeded Baseline Test',
                description: 'Randomized game variants & soundscapes changing every 24h for AI baseline modeling',
                icon: Icons.published_with_changes_rounded,
                iconBgColor: SmritiTheme.mintSoftBg,
                iconColor: SmritiTheme.forestGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DailyCalibrationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Game Cards ──
              _buildGameCard(
                context,
                title: 'Pulse Trainer',
                subtitle: 'Speed Processing',
                description: 'React to gentle visual stimuli to measure processing speed',
                icon: Icons.flash_on_rounded,
                iconBgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PulseTrainerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildGameCard(
                context,
                title: 'Wayfinder',
                subtitle: 'Spatial Memory',
                description: 'Navigate landmark paths from memory with calming soundscapes',
                icon: Icons.explore_rounded,
                iconBgColor: const Color(0xFFCCFBF1),
                iconColor: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WayfinderHomeScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildGameCard(
                context,
                title: 'Sequence Check',
                subtitle: 'Working Memory',
                description: 'Watch visual patterns and recall sequences in order',
                icon: Icons.grid_view_rounded,
                iconBgColor: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SequenceHomeScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Export All Data Button ──
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: SmritiTheme.forestGreen, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: SmritiTheme.cardWhite,
                ),
                onPressed: () => _showExportDialog(context),
                icon: const Icon(Icons.download_rounded, color: SmritiTheme.forestGreen),
                label: const Text(
                  'Export AI Raw Telemetry (JSON)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: SmritiTheme.forestGreen,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: SmritiTheme.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SmritiTheme.cardBorder, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
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
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SmritiTheme.textSubtle,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SmritiTheme.backgroundWarm,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: SmritiTheme.forestGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final allSessions = TelemetryEngine().getAllSessions();
    final sessionCount = allSessions.length;

    if (sessionCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sessions to export yet. Play a game first!'),
          backgroundColor: SmritiTheme.forestGreen,
        ),
      );
      return;
    }

    final jsonOutput = UnifiedDataExporter.exportAllSessionsToJson();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: SmritiTheme.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SmritiTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Raw Telemetry ($sessionCount sessions)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SmritiTheme.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: SmritiTheme.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SmritiTheme.backgroundWarm,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SmritiTheme.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonOutput,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: SmritiTheme.textDark,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SmritiTheme.forestGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonOutput));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Raw Telemetry JSON copied to clipboard!'),
                          backgroundColor: SmritiTheme.forestGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: Colors.white),
                    label: const Text(
                      'Copy JSON Payload',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
