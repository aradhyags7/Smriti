import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../auth/services/auth_service.dart';
import '../reminders/reminder_model.dart';
import '../reminders/reminder_service.dart';
import 'services/care_circle_service.dart';
import 'widgets/reminder_card.dart';
import '../../screens/home_screen.dart';
import '../../screens/daily_games_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'Aita';
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

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } catch (_) {
      return raw.isNotEmpty ? raw : '11:30 AM';
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
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
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
      backgroundColor: const Color(0xFFF9F8F4),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  if (_selectedIndex != 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F4D36)),
                      onPressed: () => setState(() => _selectedIndex = 0),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (_selectedIndex != 0)
                    const SizedBox(width: 12),
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
                          return const Icon(Icons.eco_rounded, size: 24, color: Color(0xFF23654D));
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
                              fontWeight: FontWeight.w600,
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
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
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
      // Custom Bottom Navigation Bar matching Image 2
      bottomNavigationBar: Container(
        color: const Color(0xFF23654D),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 1,
                iconData: Icons.support_agent_rounded,
                label: 'ASHA Worker',
              ),
              _buildNavItem(
                index: 2,
                iconData: Icons.alarm_on_rounded,
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
      return _buildCareCircleView();
    } else {
      return _buildPatientRemindersView();
    }
  }

  Widget _buildHomeTab() {
    final displayName = (_userName.isNotEmpty && _userName != 'Patient') ? _userName : 'Aita';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Good Morning, $displayName \u{1F338}',
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

                    // Card 1: 1. Daily Games (Only Daily Calibration Test)
          _buildActivityCard(
            context: context,
            iconColor: const Color(0xFFA6EBCF),
            iconData: Icons.published_with_changes_rounded,
            badgeColor: const Color(0xFFB4EBA3),
            badgeText: '1 Daily Test',
            badgeIcon: Icons.check_circle_rounded,
            title: '1. Daily Games',
            subtitle: 'Daily Calibration Test \u2022 Tap to open',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyGamesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

                    // Card 2: 2. More Games (Pulse Trainer, Wayfinder, Sequence Check)
          _buildActivityCard(
            context: context,
            iconColor: const Color(0xFFB4EBA3),
            iconData: Icons.extension_rounded,
            badgeColor: const Color(0xFFEFECE1),
            badgeText: '3 Available',
            title: '2. More Games',
            subtitle: 'Pulse Trainer, Wayfinder & Sequence Check \u2022 Tap to browse',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Card 3: 3. Reminders
          _buildActivityCard(
            context: context,
            iconColor: const Color(0xFFFED7AA),
            iconData: Icons.alarm_rounded,
            badgeColor: const Color(0xFFE5DEC9),
            badgeText: _reminders.isNotEmpty
                ? 'Next: ${_formatTime(_reminders.first.scheduledTime)}'
                : 'Next: 11:30 AM',
            title: '3. Reminders',
            subtitle: 'Medicines, hydration & daily routine • Tap to view',
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              _loadReminders();
            },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      'Your dedicated caregiver & ASHA worker',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF1F4D36),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  icon: const Icon(Icons.home_rounded, size: 18, color: Color(0xFF23654D)),
                  label: const Text('Home', style: TextStyle(color: Color(0xFF23654D), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Community Health Worker',
                                  style: TextStyle(
                                    color: Color(0xFF23654D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                asha != null ? asha.name : 'Unassigned',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F4D36),
                                ),
                              ),
                              if (asha != null)
                                Text(
                                  '${asha.village}, ${asha.district}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF5A7264)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (asha?.phone != null) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Color(0xFF23654D)),
                          const SizedBox(width: 8),
                          Text(
                            asha!.phone!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F4D36),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFE3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  caregiver?.relationship ?? 'Family Caregiver',
                                  style: const TextStyle(
                                    color: Color(0xFF23654D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                caregiver != null ? caregiver.name : 'Unassigned',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F4D36),
                                ),
                              ),
                              if (caregiver?.email != null)
                                Text(
                                  caregiver!.email!,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF5A7264)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (caregiver?.phone != null) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Color(0xFF23654D)),
                          const SizedBox(width: 8),
                          Text(
                            caregiver!.phone!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F4D36),
                            ),
                          ),
                        ],
                      ),
                    ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      'Tap checkmark when completed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF1F4D36),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  icon: const Icon(Icons.home_rounded, size: 18, color: Color(0xFF23654D)),
                  label: const Text('Home', style: TextStyle(color: Color(0xFF23654D), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
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
                              color: Color(0xFF1F4D36),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1F4D36),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
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
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF5A7264)),
                    ),
                  ],
                ),
              ],
            ),
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
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 2) {
          _loadReminders();
        } else if (index == 1) {
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
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFA1CCBA),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
