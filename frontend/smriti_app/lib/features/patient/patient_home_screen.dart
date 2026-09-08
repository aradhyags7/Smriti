import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../auth/services/auth_service.dart';
import '../reminders/reminder_model.dart';
import '../reminders/reminder_service.dart';
import 'package:flutter/services.dart';
import 'services/care_circle_service.dart';
import 'widgets/reminder_card.dart';
import '../cognitive/speed_processing/screens/pulse_trainer_home_screen.dart';
import '../cognitive/spatial_memory/screens/wayfinder_home_screen.dart';
import '../cognitive/working_memory/screens/sequence_home_screen.dart';
import '../cognitive/calibration/screens/daily_calibration_screen.dart';
import '../cognitive/telemetry/unified_data_exporter.dart';
import '../cognitive/telemetry/telemetry_engine.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'Patient';
  String _userEmail = '';
  final _authService = AuthService();
  final _reminderService = ReminderService();
  final _careCircleService = CareCircleService();

  List<ReminderItem> _reminders = [];
  bool _isLoadingReminders = false;

  CareCircleData? _careCircle;
  bool _isLoadingCareCircle = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadReminders();
    _loadCareCircle();
  }

  Future<void> _loadUserName() async {
    final savedName = await _authService.getSavedName();
    final savedEmail = await _authService.getSavedEmail();
    if (mounted) {
      setState(() {
        if (savedName != null && savedName.isNotEmpty) _userName = savedName;
        if (savedEmail != null && savedEmail.isNotEmpty) _userEmail = savedEmail;
      });
    }
    final profile = await _authService.fetchCurrentUser();
    if (profile != null && mounted) {
      setState(() {
        if (profile['full_name'] != null && (profile['full_name'] as String).isNotEmpty) {
          _userName = profile['full_name'];
        }
        if (profile['email'] != null) {
          _userEmail = profile['email'];
        }
      });
    }
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoadingReminders = true);
    final items = await _reminderService.fetchReminders();
    if (mounted) {
      setState(() {
        _reminders = items;
        _isLoadingReminders = false;
      });
    }
  }

  Future<void> _loadCareCircle() async {
    setState(() => _isLoadingCareCircle = true);
    final data = await _careCircleService.fetchCareCircle();
    if (mounted) {
      setState(() {
        _careCircle = data;
        _isLoadingCareCircle = false;
      });
    }
  }

  Future<void> _toggleAcknowledge(ReminderItem reminder) async {
    final success = await _reminderService.toggleAcknowledge(reminder.id);
    if (success && mounted) {
      setState(() {
        final idx = _reminders.indexWhere((r) => r.id == reminder.id);
        if (idx != -1) {
          _reminders[idx] = _reminders[idx].copyWith(
            isAcknowledged: !_reminders[idx].isAcknowledged,
          );
        }
      });
    }
  }

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF23654D),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_userEmail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Patient Care Portal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF23654D),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: Colors.redAccent),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text('Sign out of your account on this device'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _authService.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                      arguments: {'role': 'patient'},
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFF3EEDF), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo/smriti-logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image, size: 24, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smriti',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Gentle Memory Care',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF5A7264),
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showProfileModal(context),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF23654D),
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Content Area switched by Tabs
            Expanded(
              child: _buildBodyForSelectedTab(),
            ),
          ],
        ),
      ),
      // Custom Bottom Navigation Bar
      bottomNavigationBar: Container(
        color: const Color(0xFF23654D),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                iconData: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                iconData: Icons.sports_esports_rounded,
                label: 'Games',
              ),
              _buildNavItem(
                index: 2,
                iconData: Icons.support_agent_rounded,
                label: 'Care Circle',
              ),
              _buildNavItem(
                index: 3,
                iconData: Icons.alarm_rounded,
                label: 'Reminders',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyForSelectedTab() {
    if (_selectedIndex == 0) {
      return _buildHomeTab();
    } else if (_selectedIndex == 1) {
      return _buildGamesView();
    } else if (_selectedIndex == 2) {
      return _buildCareCircleView();
    } else {
      return _buildPatientRemindersView();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Good Morning, $_userName',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF0F5A4D),
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose what you would like to do today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1F4D36),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            // Card 1: Daily Games
            _buildActivityCard(
              context: context,
              iconColor: const Color(0xFFA6EBCF),
              iconData: Icons.sports_esports,
              badgeColor: const Color(0xFFB4EBA3),
              badgeText: 'Daily Exercises',
              badgeIcon: Icons.play_circle_filled_rounded,
              title: '1. Daily Games',
              subtitle: 'Today\'s gentle memory & cognitive exercises • Tap to open',
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            const SizedBox(height: 16),
            // Card 2: More Games / Library
            _buildActivityCard(
              context: context,
              iconColor: const Color(0xFFB4EBA3),
              iconData: Icons.extension,
              badgeColor: const Color(0xFFF3EEDF),
              badgeText: 'Explore All',
              title: '2. More Games & Calibration',
              subtitle: 'Pulse Trainer, Wayfinder, Sequence Check & Daily Baseline',
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            const SizedBox(height: 24),

            // Quick Play Games Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Play',
                  style: TextStyle(
                    color: Color(0xFF0F5A4D),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  icon: const Text(
                    'All Games',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF23654D),
                    ),
                  ),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF23654D)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickGameCard(
              title: 'Pulse Trainer',
              category: 'Speed Processing',
              icon: Icons.flash_on_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              description: 'Visual reaction speed & peripheral stimulus',
              onPlay: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PulseTrainerHomeScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildQuickGameCard(
              title: 'Wayfinder',
              category: 'Spatial Memory',
              icon: Icons.explore_rounded,
              iconBg: const Color(0xFFCCFBF1),
              iconColor: const Color(0xFF0D9488),
              description: 'Landmark path recall with regional soundscapes',
              onPlay: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WayfinderHomeScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildQuickGameCard(
              title: 'Sequence Check',
              category: 'Working Memory',
              icon: Icons.grid_view_rounded,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
              description: 'Remember & repeat progressive visual tile sequences',
              onPlay: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SequenceHomeScreen()),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memory & Focus',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: const Color(0xFF0F5A4D),
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gentle daily cognitive exercises',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF1F4D36),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFB4EBA3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_rounded, size: 16, color: Color(0xFF1F4D36)),
                    SizedBox(width: 4),
                    Text(
                      'AI Adapted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F4D36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daily Calibration Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF23654D), Color(0xFF154333)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF23654D).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.published_with_changes_rounded,
                        color: Color(0xFFB4EBA3),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Calibration Test',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '24-Hour Adaptive Baseline',
                            style: TextStyle(
                              color: Color(0xFFB4EBA3),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Quick 2-minute baseline test to adapt game speed, tremor filters, and audio to how you feel today.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4EBA3),
                      foregroundColor: const Color(0xFF1F4D36),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyCalibrationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'Start Today\'s Calibration',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Clinical Exercise Library Title
          const Text(
            'Clinical Game Library',
            style: TextStyle(
              color: Color(0xFF0F5A4D),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          // Game 1: Pulse Trainer
          _buildFullGameCard(
            title: 'Pulse Trainer',
            domain: 'Speed Processing',
            badge: 'UFOV Stimulus',
            badgeBg: const Color(0xFFFEF3C7),
            badgeColor: const Color(0xFFD97706),
            description: 'Identifies central target shapes while reacting to peripheral visual flashes.',
            icon: Icons.flash_on_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PulseTrainerHomeScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Game 2: Wayfinder
          _buildFullGameCard(
            title: 'Wayfinder',
            domain: 'Spatial Memory',
            badge: 'Soundscape Guided',
            badgeBg: const Color(0xFFCCFBF1),
            badgeColor: const Color(0xFF0D9488),
            description: 'Traverse landmark pathways and recall navigation routes with calming audio.',
            icon: Icons.explore_rounded,
            iconBg: const Color(0xFFCCFBF1),
            iconColor: const Color(0xFF0D9488),
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WayfinderHomeScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Game 3: Sequence Check
          _buildFullGameCard(
            title: 'Sequence Check',
            domain: 'Working Memory',
            badge: 'Pattern Span',
            badgeBg: const Color(0xFFF3E8FF),
            badgeColor: const Color(0xFF7C3AED),
            description: 'Observe dynamic visual sequences and replicate them in exact order.',
            icon: Icons.grid_view_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF7C3AED),
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SequenceHomeScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Telemetry & Full Hub
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: Color(0xFF23654D)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Raw Telemetry',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F4D36),
                        ),
                      ),
                      Text(
                        'View and export clinical session metrics',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23654D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _showExportDialog(context),
                  child: const Text(
                    'Export',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCareCircleView() {
    final asha = _careCircle?.ashaWorker;
    final caregiver = _careCircle?.caregiver;

    return RefreshIndicator(
      onRefresh: _loadCareCircle,
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'My Care Circle',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF0F5A4D),
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your dedicated caregiver and community health worker',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1F4D36),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            if (_isLoadingCareCircle)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(color: Color(0xFF23654D)),
                ),
              )
            else ...[
              // ASHA Worker Card
              Container(
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA6EBCF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.health_and_safety, color: Color(0xFF1F4D36), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFE3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ASHA Healthcare Guide',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF23654D),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                asha != null ? asha.name : 'Health Worker Assigned Soon',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (asha != null) ...[
                      Text(
                        'Village: ${asha.village}, ${asha.district}',
                        style: const TextStyle(color: Color(0xFF5A7264), fontSize: 13),
                      ),
                      if (asha.phone != null && asha.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Phone: ${asha.phone}',
                          style: const TextStyle(color: Color(0xFF5A7264), fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling ASHA Worker ${asha.name}...')),
                                );
                              },
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call ASHA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF23654D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Home visit requested! Your ASHA worker is notified.'),
                                    backgroundColor: Color(0xFF23654D),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.home_work, size: 18),
                              label: const Text('Request Visit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF23654D),
                                side: const BorderSide(color: Color(0xFF23654D)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Your community ASHA worker will assign to your profile to monitor your health visits and gentle check-ins.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Caregiver Card
              Container(
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB4EBA3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.family_restroom, color: Color(0xFF1F4D36), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFE3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  caregiver != null ? caregiver.relationship : 'Family Caregiver',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF23654D),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                caregiver != null ? caregiver.name : 'Caregiver Connecting Soon',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (caregiver != null) ...[
                      if (caregiver.phone != null && caregiver.phone!.isNotEmpty) ...[
                        Text(
                          'Phone: ${caregiver.phone}',
                          style: const TextStyle(color: Color(0xFF5A7264), fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                      ],
                      const Text(
                        'Managing your daily medication reminders and wellness check-ins.',
                        style: TextStyle(color: Color(0xFF5A7264), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling Caregiver ${caregiver.name}...')),
                                );
                              },
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Call Caregiver'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF23654D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sent "I Am Doing Well" message to caregiver!'),
                                    backgroundColor: Color(0xFF23654D),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.thumb_up, size: 18),
                              label: const Text("I'm Okay"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF23654D),
                                side: const BorderSide(color: Color(0xFF23654D)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Your family caregiver can connect with you using your registered email or phone.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Emergency Contact Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2DCBE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency, color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Quick Dial',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Elder Helpline: 14567 • Emergency: 112',
                            style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_forwarded, color: Colors.redAccent),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connecting to Senior Helpline 14567...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientRemindersView() {
    return RefreshIndicator(
      onRefresh: _loadReminders,
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Daily Reminders',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF0F5A4D),
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the checkmark when you complete each routine',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1F4D36),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            if (_isLoadingReminders)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(color: Color(0xFF23654D)),
                ),
              )
            else if (_reminders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA6EBCF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.done_all, color: Color(0xFF1F4D36), size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'All Clear for Today!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No pending reminders. Your caregiver will schedule any new medicines or tasks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ..._reminders.map((reminder) {
                return ReminderCard(
                  reminder: reminder,
                  isElderFriendly: true,
                  onToggle: () => _toggleAcknowledge(reminder),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGameCard({
    required String title,
    required String category,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String description,
    required VoidCallback onPlay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4D36),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A7264),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23654D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: onPlay,
            child: const Text(
              'Play',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullGameCard({
    required String title,
    required String domain,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String description,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onPlay,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F4D36),
                        ),
                      ),
                      Text(
                        domain,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A7264),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5A7264),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23654D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                'Launch $title',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
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
          backgroundColor: Color(0xFF23654D),
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Telemetry Export',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F5A4D),
                          ),
                        ),
                        Text(
                          '$sessionCount session(s) recorded',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF23654D)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonOutput));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Telemetry JSON copied to clipboard!'),
                            backgroundColor: Color(0xFF23654D),
                          ),
                        );
                      },
                      tooltip: 'Copy JSON',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      jsonOutput,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF38BDF8),
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

  Widget _buildActivityCard({
    required BuildContext context,
    required Color iconColor,
    required IconData iconData,
    required Color badgeColor,
    required String badgeText,
    IconData? badgeIcon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(iconData, color: const Color(0xFF1F4D36), size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (badgeIcon != null) ...[
                          Icon(badgeIcon, size: 14, color: const Color(0xFF1F4D36)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F4D36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1F4D36),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5A7264),
                            fontSize: 13,
                            height: 1.4,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1EFE3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF5A7264)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData iconData,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 3) {
          _loadReminders();
        } else if (index == 2) {
          _loadCareCircle();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              iconData,
              color: isSelected ? const Color(0xFF23654D) : const Color(0xFFA1CCBA),
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFA1CCBA),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
