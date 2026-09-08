import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/language_selection_modal.dart';
import '../auth/services/auth_service.dart';
import '../patient/widgets/reminder_card.dart';
import '../reminders/reminder_model.dart';
import '../reminders/reminder_service.dart';
import 'services/caregiver_service.dart';
import 'widgets/cognitive_line_chart.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  int _selectedIndex = 0;
  String _userName = 'Caregiver';
  String _userEmail = '';
  final _authService = AuthService();
  final _reminderService = ReminderService();
  final _caregiverService = CaregiverService();

  // Patients & Focused Patient
  List<CaregiverPatient> _myPatients = [];
  CaregiverPatient? _selectedPatient;
  bool _isLoadingPatients = false;

  // Reminders
  List<ReminderItem> _reminders = [];
  bool _isLoadingReminders = false;
  String _reminderFilter = 'ALL'; // ALL, MEDICINE, HYDRATION, OTHER

  // Analytics
  CognitiveAnalyticsData? _analyticsData;
  bool _isLoadingAnalytics = false;
  int _analyticsDays = 14;
  String _selectedChartMetric = 'ALL'; // ALL, MEMORY, ATTENTION, ENGAGEMENT

  // Activity Feed
  DailyActivityFeed? _activityFeed;
  bool _isLoadingFeed = false;

  // Alerts
  List<CaregiverAlert> _alerts = [];
  bool _isLoadingAlerts = false;

  // Reminiscence Vault
  List<ReminiscenceVaultItem> _reminiscences = [];
  bool _isLoadingReminiscences = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadAllData();
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

  Future<void> _loadAllData() async {
    await _loadPatients();
    await _loadReminders();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoadingPatients = true);
    final pts = await _caregiverService.fetchMyPatients();
    if (mounted) {
      setState(() {
        _myPatients = pts;
        _isLoadingPatients = false;
        if (pts.isNotEmpty) {
          if (_selectedPatient == null || !pts.any((p) => p.patientId == _selectedPatient!.patientId)) {
            _selectedPatient = pts.first;
          } else {
            _selectedPatient = pts.firstWhere((p) => p.patientId == _selectedPatient!.patientId);
          }
        } else {
          _selectedPatient = null;
        }
      });
      if (_selectedPatient != null) {
        _loadPatientDetails(_selectedPatient!.patientId);
      }
    }
  }

  Future<void> _loadPatientDetails(String patientId) async {
    _loadAnalytics(patientId);
    _loadActivityFeed(patientId);
    _loadAlerts(patientId);
    _loadReminiscences(patientId);
  }

  Future<void> _loadAnalytics(String patientId) async {
    setState(() => _isLoadingAnalytics = true);
    final data = await _caregiverService.fetchAnalytics(patientId, days: _analyticsDays);
    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoadingAnalytics = false;
      });
    }
  }

  Future<void> _loadActivityFeed(String patientId) async {
    setState(() => _isLoadingFeed = true);
    final feed = await _caregiverService.fetchActivityFeed(patientId);
    if (mounted) {
      setState(() {
        _activityFeed = feed;
        _isLoadingFeed = false;
      });
    }
  }

  Future<void> _loadAlerts(String patientId) async {
    setState(() => _isLoadingAlerts = true);
    final alerts = await _caregiverService.fetchAlerts(patientId);
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _isLoadingAlerts = false;
      });
    }
  }

  Future<void> _acknowledgeAlert(CaregiverAlert alert) async {
    final success = await _caregiverService.acknowledgeAlert(alert.id);
    if (success && mounted) {
      setState(() {
        final idx = _alerts.indexWhere((a) => a.id == alert.id);
        if (idx != -1) {
          _alerts[idx] = _alerts[idx].copyWith(isAcknowledged: true);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert acknowledged and marked reviewed.'),
          backgroundColor: Color(0xFF23654D),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadReminiscences(String patientId) async {
    setState(() => _isLoadingReminiscences = true);
    final list = await _caregiverService.fetchReminiscences(patientId);
    if (mounted) {
      setState(() {
        _reminiscences = list;
        _isLoadingReminiscences = false;
      });
    }
  }

  Future<void> _deleteReminiscence(String memoryId) async {
    final success = await _caregiverService.deleteReminiscence(memoryId);
    if (success && mounted) {
      setState(() {
        _reminiscences.removeWhere((r) => r.id == memoryId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory deleted from vault.'),
          duration: Duration(seconds: 2),
        ),
      );
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

  Future<void> _deleteReminder(ReminderItem reminder) async {
    final success = await _reminderService.deleteReminder(reminder.id);
    if (success && mounted) {
      setState(() {
        _reminders.removeWhere((r) => r.id == reminder.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ----------------------------------------------------
  // Modals & Bottom Sheets
  // ----------------------------------------------------

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
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
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
              if (_userEmail.isNotEmpty)
                Text(
                  _userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Caregiver Portal Active',
                  style: TextStyle(
                    color: Color(0xFF23654D),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_add_outlined, color: Color(0xFF23654D)),
                title: const Text('Connect Another Loved One', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showConnectPatientModal(context);
                },
              ),
                            ValueListenableBuilder<String>(
                valueListenable: AppLanguage.languageNotifier,
                builder: (context, langCode, _) {
                  final curLang = AppLanguage.currentLanguage;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.translate_rounded, color: Color(0xFF1E3A8A)),
                    ),
                    title: Text(
                      AppLanguage.tr('change_language'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${curLang.nativeName} (${curLang.englishName})'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(ctx);
                      showLanguageSelectionSheet(context);
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(AppLanguage.tr('sign_out'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text('Sign out of your account on this device'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _authService.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                      arguments: {'role': 'caregiver'},
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

  void _showConnectPatientModal(BuildContext context) {
    String selectedRelation = 'Mother';
    String? selectedPatientId;
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFE3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.family_restroom, color: Color(0xFF23654D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect Loved One',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Link to monitor cognitive & daily routines',
                              style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Relationship',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final rel in ['Mother', 'Father', 'Spouse', 'Grandmother', 'Grandfather', 'Relative'])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(rel),
                                selected: selectedRelation == rel,
                                onSelected: (sel) {
                                  if (sel) setModalState(() => selectedRelation = rel);
                                },
                                selectedColor: const Color(0xFF23654D),
                                backgroundColor: const Color(0xFFF1EFE3),
                                labelStyle: TextStyle(
                                  color: selectedRelation == rel ? Colors.white : const Color(0xFF1F4D36),
                                  fontWeight: selectedRelation == rel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select from Registered Patients',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<AvailablePatient>>(
                      future: _caregiverService.fetchAvailablePatients(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: Color(0xFF23654D)),
                            ),
                          );
                        }
                        final available = snapshot.data ?? [];
                        if (available.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EFE3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No unassigned registered patients found. You can enter patient email below.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF5A7264)),
                            ),
                          );
                        }
                        return Column(
                          children: available.map((p) {
                            final isSel = selectedPatientId == p.patientId;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFFE8F5EE) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF23654D) : Colors.grey.shade200,
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF23654D),
                                  child: Text(
                                    p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'P',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                title: Text(
                                  p.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  p.email ?? p.phoneNumber ?? 'Patient Account',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                trailing: p.isConnected
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB4EBA3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Connected',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F4D36)),
                                        ),
                                      )
                                    : (isSel
                                        ? const Icon(Icons.check_circle, color: Color(0xFF23654D))
                                        : const Icon(Icons.radio_button_unchecked, color: Colors.grey)),
                                onTap: () {
                                  setModalState(() {
                                    selectedPatientId = p.patientId;
                                    emailController.clear();
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Or Connect by Patient Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'patient@example.com',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF23654D), width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          setModalState(() => selectedPatientId = null);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final email = emailController.text.trim();
                        if (selectedPatientId == null && email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select or enter a patient to connect.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final success = await _caregiverService.connectPatient(
                          patientId: selectedPatientId,
                          patientEmail: email.isNotEmpty ? email : null,
                          relationship: selectedRelation,
                        );

                        if (success) {
                          await _loadPatients();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Loved one connected successfully!'),
                              backgroundColor: Color(0xFF23654D),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Could not connect. Please check credentials or email.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23654D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Connect Loved One', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddReminderModal() {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    String selectedType = 'MEDICINE';
    String selectedFrequency = 'DAILY';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formatTime(TimeOfDay t) {
              final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
              final minute = t.minute.toString().padLeft(2, '0');
              final period = t.period == DayPeriod.am ? 'AM' : 'PM';
              return '${hour.toString().padLeft(2, '0')}:$minute $period';
            }

            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFE3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.alarm_add, color: Color(0xFF23654D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Daily Reminder',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Track medicine, hydration, or meals',
                              style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Reminder Title',
                        hintText: 'e.g. Morning Blood Pressure Tablet',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                            icon: const Icon(Icons.schedule, color: Color(0xFF23654D)),
                            label: Text(
                              'Time: ${formatTime(selectedTime)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F4D36)),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF23654D)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('MEDICINE', 'Medicine', Icons.medication, selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildChoiceChip('HYDRATION', 'Water/Drink', Icons.water_drop, selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildChoiceChip('MEAL', 'Meal', Icons.restaurant, selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildChoiceChip('EXERCISE', 'Exercise', Icons.directions_walk, selectedType, (v) => setModalState(() => selectedType = v)),
                        _buildChoiceChip('GAME', 'Daily Games', Icons.sports_esports, selectedType, (v) => setModalState(() => selectedType = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final freq in ['DAILY', 'WEEKLY', 'ONCE'])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedFrequency = freq),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedFrequency == freq ? const Color(0xFF23654D) : const Color(0xFFF1EFE3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  freq[0] + freq.substring(1).toLowerCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: selectedFrequency == freq ? Colors.white : const Color(0xFF1F4D36),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a reminder title.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final hourStr = selectedTime.hour.toString().padLeft(2, '0');
                        final minStr = selectedTime.minute.toString().padLeft(2, '0');
                        final timeString = '$hourStr:$minStr:00';

                        final created = await _reminderService.createRemoteReminder(
                          title: title,
                          reminderType: selectedType,
                          scheduledTime: timeString,
                          frequency: selectedFrequency,
                        );

                        if (created != null && mounted) {
                          setState(() {
                            _reminders.insert(0, created);
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Reminder created successfully!'),
                              backgroundColor: Color(0xFF23654D),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23654D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMemoryModal() {
    if (_selectedPatient == null) return;
    final titleCtrl = TextEditingController();
    final captionCtrl = TextEditingController();
    String selectedTag = 'Family';
    String mediaType = 'PHOTO';
    final mediaUrlCtrl = TextEditingController(text: 'assets/images/games/reminiscence_memory.jpg');

    final tags = ['Family', 'Spouse', 'Grandchildren', 'Childhood', 'Festivals', 'Home', 'Travel'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFE3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.photo_library, color: Color(0xFF23654D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add to Reminiscence Vault',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text(
                              'For ${_selectedPatient!.fullName}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Memory Title',
                        hintText: 'e.g. Grandma with newborn grandchild',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: captionCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Story / Caption',
                        hintText: 'A comforting note or context to spark nostalgic recall',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Media Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.photo, size: 16),
                          label: const Text('Photo'),
                          selected: mediaType == 'PHOTO',
                          selectedColor: const Color(0xFF23654D),
                          backgroundColor: const Color(0xFFF1EFE3),
                          labelStyle: TextStyle(color: mediaType == 'PHOTO' ? Colors.white : const Color(0xFF1F4D36), fontWeight: FontWeight.bold),
                          onSelected: (sel) {
                            if (sel) setModalState(() => mediaType = 'PHOTO');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.mic, size: 16),
                          label: const Text('Audio Story'),
                          selected: mediaType == 'AUDIO',
                          selectedColor: const Color(0xFF23654D),
                          backgroundColor: const Color(0xFFF1EFE3),
                          labelStyle: TextStyle(color: mediaType == 'AUDIO' ? Colors.white : const Color(0xFF1F4D36), fontWeight: FontWeight.bold),
                          onSelected: (sel) {
                            if (sel) setModalState(() => mediaType = 'AUDIO');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Relationship Tag', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final isSel = selectedTag == tag;
                        return ChoiceChip(
                          label: Text(tag),
                          selected: isSel,
                          selectedColor: const Color(0xFF23654D),
                          backgroundColor: const Color(0xFFF1EFE3),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF1F4D36),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (sel) {
                            if (sel) setModalState(() => selectedTag = tag);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please provide a title for this memory.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final item = await _caregiverService.createReminiscence(
                          patientId: _selectedPatient!.patientId,
                          title: title,
                          caption: captionCtrl.text.trim().isNotEmpty ? captionCtrl.text.trim() : null,
                          mediaType: mediaType,
                          mediaUrl: mediaUrlCtrl.text.trim(),
                          relationshipTag: selectedTag,
                        );

                        if (item != null && mounted) {
                          setState(() {
                            _reminiscences.insert(0, item);
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Memory saved to Reminiscence Vault!'),
                              backgroundColor: Color(0xFF23654D),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23654D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save to Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDisconnect(CaregiverPatient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disconnect Loved One', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to disconnect ${patient.fullName} from your caregiver account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _caregiverService.disconnectPatient(patient.patientId);
              if (mounted && success) {
                _loadPatients();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${patient.fullName} disconnected.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String value,
    String label,
    IconData icon,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF1F4D36)),
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) onSelected(value);
      },
      selectedColor: const Color(0xFF23654D),
      backgroundColor: const Color(0xFFF1EFE3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1F4D36),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF23654D) : Colors.transparent,
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Main Build & Navigation
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.languageNotifier,
      builder: (context, langCode, _) {
        return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/logo/smriti-logo.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smriti Caregiver',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Loved One Cognitive Wellness',
                  style: TextStyle(color: Color(0xFF5A7264), fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none, color: AppColors.primary),
                if (_alerts.any((a) => !a.isAcknowledged))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() => _selectedIndex = 0);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showProfileModal(context),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF23654D),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        color: const Color(0xFF23654D),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(index: 0, iconData: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: AppLanguage.tr('caregiver_dashboard')),
              _buildNavItem(index: 1, iconData: Icons.photo_library_outlined, activeIcon: Icons.photo_library, label: 'Vault'),
              _buildNavItem(index: 2, iconData: Icons.alarm_outlined, activeIcon: Icons.alarm, label: AppLanguage.tr('daily_reminders')),
              _buildNavItem(index: 3, iconData: Icons.diversity_1_outlined, activeIcon: Icons.diversity_1, label: 'Care Circle'),
            ],
          ),
        ),
      ),
    );
    },
  );
  }

  Widget _buildNavItem({
    required int index,
    required IconData iconData,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 2) {
          _loadReminders();
        } else if (index == 0 && _selectedPatient != null) {
          _loadPatientDetails(_selectedPatient!.patientId);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? activeIcon : iconData,
              color: isSelected ? const Color(0xFF23654D) : const Color(0xFFA1CCBA),
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
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

  Widget _buildBody() {
    if (_isLoadingPatients) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF23654D)));
    }

    if (_myPatients.isEmpty) {
      return _buildNoPatientsState();
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildReminiscenceVaultTab();
      case 2:
        return _buildRemindersTab();
      case 3:
        return _buildCareCircleTab();
      default:
        return _buildDashboardTab();
    }
  }

  // ----------------------------------------------------
  // Empty State: No Patients Connected
  // ----------------------------------------------------

  Widget _buildNoPatientsState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
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
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF1EFE3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.family_restroom, color: Color(0xFF23654D), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Loved Ones Connected Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your parent, grandparent, or family member to monitor daily calibration tests, cognitive trends, reminders, and gentle memory vaults.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showConnectPatientModal(context),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Connect a Loved One'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23654D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 0: Focused Patient Dashboard (Sections 1, 2, 3, 4)
  // ----------------------------------------------------

  Widget _buildDashboardTab() {
    final patient = _selectedPatient!;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadPatients();
      },
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Switcher (if > 1) + Connect action
            _buildPatientSwitcher(),
            const SizedBox(height: 16),

            // SECTION 1: Patient Profile Header
            _buildPatientProfileHeader(patient),
            const SizedBox(height: 20),

            // ASHA Medical & Home Visit Notes (Visible to Caregiver)
            _buildAshaMedicalNotesSection(patient),
            const SizedBox(height: 20),

            // SECTION 2: Cognitive Analytics (Line chart + Risk Level + Filter pills)
            _buildCognitiveAnalyticsSection(),
            const SizedBox(height: 20),

            // SECTION 3: Daily Activity Feed (Today's games + Daily Check-in)
            _buildDailyActivityFeedSection(),
            const SizedBox(height: 20),

            // SECTION 4: Alerts Inbox (System alerts + Acknowledge action)
            _buildAlertsInboxSection(),
            const SizedBox(height: 24),

            // Quick Shortcut Row for Vault & Reminders
            _buildQuickShortcutsRow(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSwitcher() {
    return Row(
      children: [
        const Icon(Icons.people_alt, size: 18, color: Color(0xFF23654D)),
        const SizedBox(width: 8),
        const Text(
          'Loved One Focus:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._myPatients.map((p) {
                  final isSelected = p.patientId == _selectedPatient?.patientId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPatient = p;
                      });
                      _loadPatientDetails(p.patientId);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF23654D) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF23654D) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        p.fullName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF1F4D36),
                        ),
                      ),
                    ),
                  );
                }),
                IconButton(
                  onPressed: () => _showConnectPatientModal(context),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF23654D), size: 22),
                  tooltip: 'Connect Another Loved One',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // SECTION 1: Patient Profile Header
  
  Widget _buildAshaMedicalNotesSection(CaregiverPatient patient) {
    final notes = patient.medicalNotes;
    final List<String> notesList = (notes != null && notes.trim().isNotEmpty)
        ? notes.split('\n').where((s) => s.trim().isNotEmpty).toList()
        : [];

    return Container(
      width: double.infinity,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.health_and_safety, color: Color(0xFF23654D), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASHA Medical & Home Visit Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      patient.ashaName != null
                          ? 'Assigned Worker: ${patient.ashaName}'
                          : 'Community healthcare observations',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                    ),
                  ],
                ),
              ),
              if (patient.ashaPhone != null)
                IconButton(
                  icon: const Icon(Icons.phone, color: Color(0xFF23654D)),
                  tooltip: 'Call ASHA Worker',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ASHA Worker (${patient.ashaPhone})...')),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          if (notesList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_outlined, color: Color(0xFF5A7264), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No clinical notes recorded yet by the ASHA worker. Home visit observations will appear here.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: notesList.map((note) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE3).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4CEB8).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt_outlined, color: Color(0xFF23654D), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientProfileHeader(CaregiverPatient patient) {
    // Risk level styling
    final riskLevel = _analyticsData?.riskLevel ?? 'STABLE';
    Color riskBgColor = const Color(0xFFE8F5EE);
    Color riskTextColor = const Color(0xFF23654D);
    IconData riskIcon = Icons.check_circle_outline;
    String riskLabel = 'STABLE TREND';

    if (riskLevel == 'MONITOR') {
      riskBgColor = const Color(0xFFFEF3C7);
      riskTextColor = const Color(0xFFD97706);
      riskIcon = Icons.visibility_outlined;
      riskLabel = 'MONITOR ROUTINE';
    } else if (riskLevel == 'ATTENTION_REQUIRED') {
      riskBgColor = const Color(0xFFFEE2E2);
      riskTextColor = const Color(0xFFDC2626);
      riskIcon = Icons.warning_amber_rounded;
      riskLabel = 'ATTENTION REQUIRED';
    }

    // Language display map
    final langMap = {
      'en': 'English',
      'as': 'অসমীয়া (Assamese)',
      'bn': 'বাংলা (Bengali)',
      'mni': 'মৈতৈলোন্ (Manipuri)',
      'lus': 'Mizo ṭawng',
      'nag': 'Nagamese',
    };
    final langDisplay = langMap[patient.preferredLanguage] ?? patient.preferredLanguage.toUpperCase();

    return Container(
      width: double.infinity,
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
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF1EFE3),
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Color(0xFF23654D),
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            patient.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB4EBA3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            patient.relationship,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F4D36),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${patient.age} yrs • Gender: ${patient.gender.toUpperCase()}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (patient.dementiaType != null && patient.dementiaType!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EFE3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4CEB8)),
                            ),
                            child: Text(
                              patient.dementiaType!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF23654D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Status and Metrics row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (patient.dementiaType != null && patient.dementiaType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF23654D).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology, color: Color(0xFF23654D), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Diagnosis: ${patient.dementiaType}',
                        style: const TextStyle(
                          color: Color(0xFF23654D),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              // Risk level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: riskBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(riskIcon, color: riskTextColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      riskLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: riskTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Preferred Language pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, color: Color(0xFF23654D), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      langDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F4D36),
                      ),
                    ),
                  ],
                ),
              ),
              // Baseline Memory pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology, color: Color(0xFF23654D), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Baseline: ${patient.baselineMemory.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A7264),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (patient.ashaName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFE3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Color(0xFF23654D), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned ASHA: ${patient.ashaName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F4D36),
                    ),
                  ),
                  const Spacer(),
                  if (patient.ashaPhone != null)
                    Text(
                      patient.ashaPhone!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5A7264)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // SECTION 2: Cognitive Analytics
  Widget _buildCognitiveAnalyticsSection() {
    return Container(
      width: double.infinity,
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cognitive Analytics',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Memory, Attention & Engagement Trends',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5A7264)),
                  ),
                ],
              ),
              // Period selector (7d, 14d, 30d)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [7, 14, 30].map((d) {
                    final isSel = _analyticsDays == d;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _analyticsDays = d);
                        if (_selectedPatient != null) {
                          _loadAnalytics(_selectedPatient!.patientId);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF23654D) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${d}d',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF1F4D36),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Current Score Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniCard(
                  label: 'Memory',
                  value: _analyticsData != null ? '${_analyticsData!.currentMemory.toStringAsFixed(0)}%' : '--',
                  icon: Icons.psychology,
                  color: const Color(0xFF23654D),
                  bgColor: const Color(0xFFE8F5EE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricMiniCard(
                  label: 'Attention',
                  value: _analyticsData != null ? '${_analyticsData!.currentAttention.toStringAsFixed(0)}%' : '--',
                  icon: Icons.remove_red_eye_outlined,
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricMiniCard(
                  label: 'Engagement',
                  value: _analyticsData != null ? '${_analyticsData!.currentEngagement.toStringAsFixed(0)}%' : '--',
                  icon: Icons.bolt,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Line Chart
          if (_isLoadingAnalytics)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFF23654D)),
              ),
            )
          else
            CognitiveLineChart(
              trend: _analyticsData?.trend ?? [],
              selectedMetric: _selectedChartMetric,
              onMetricChanged: (val) {
                setState(() => _selectedChartMetric = val);
              },
            ),
          const SizedBox(height: 12),
          // Non-diagnostic clinical disclaimer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Non-diagnostic: Cognitive metrics are generated from daily calibration tests and interaction patterns to track personal trends over time.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  // SECTION 3: Daily Activity Feed
  Widget _buildDailyActivityFeedSection() {
    final feed = _activityFeed;

    return Container(
      width: double.infinity,
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Activity Feed',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Games, mistakes, reaction time & check-in',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5A7264)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF23654D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingFeed)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFF23654D)),
              ),
            )
          else ...[
            // Daily Checkin Summary Card
            _buildDailyCheckinCard(feed?.checkin),
            const SizedBox(height: 14),
            const Text(
              "Today's Calibration Games",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            if (feed == null || feed.games.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports_outlined, color: Colors.grey, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No calibration games played yet today',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          Text(
                            'Scheduled reminder can encourage your loved one to play.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...feed.games.map((g) => _buildGameFeedItem(g)),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyCheckinCard(DailyCheckinSummary? checkin) {
    if (checkin == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.self_improvement, color: Color(0xFF23654D), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Wellness Check-in Pending',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F4D36)),
                  ),
                  Text(
                    'Mood and sleep status will appear once recorded today.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Determine mood icon & text
    final mood = checkin.mood ?? 'Good';
    IconData moodIcon = Icons.sentiment_satisfied;
    Color moodColor = const Color(0xFF23654D);
    if (mood.toLowerCase().contains('happy') || mood.toLowerCase().contains('great')) {
      moodIcon = Icons.sentiment_very_satisfied;
      moodColor = const Color(0xFF10B981);
    } else if (mood.toLowerCase().contains('confused') || mood.toLowerCase().contains('anxious')) {
      moodIcon = Icons.sentiment_dissatisfied;
      moodColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(moodIcon, color: moodColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Mood: $mood',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: moodColor),
              ),
              const Spacer(),
              if (checkin.sleepHours != null)
                Row(
                  children: [
                    const Icon(Icons.bedtime, size: 14, color: Color(0xFF0284C7)),
                    const SizedBox(width: 4),
                    Text(
                      '${checkin.sleepHours!.toStringAsFixed(1)} hrs sleep',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
            ],
          ),
          if (checkin.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: checkin.symptoms.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                );
              }).toList(),
            ),
          ],
          if (checkin.notes != null && checkin.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note: "${checkin.notes}"',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameFeedItem(GameActivityItem g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_esports, color: Color(0xFF23654D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.gameName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Score: ${g.score} pts',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF23654D)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${g.mistakes} mistakes',
                      style: TextStyle(
                        fontSize: 11,
                        color: g.mistakes > 2 ? Colors.redAccent : Colors.grey.shade600,
                        fontWeight: g.mistakes > 2 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (g.reactionTimeSeconds != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${g.reactionTimeSeconds!.toStringAsFixed(1)}s rxn',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 4: Alerts Inbox
  Widget _buildAlertsInboxSection() {
    final unacknowledged = _alerts.where((a) => !a.isAcknowledged).toList();

    return Container(
      width: double.infinity,
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
                  const Text(
                    'Alerts Inbox',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (unacknowledged.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${unacknowledged.length} New',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF23654D)),
                onPressed: () {
                  if (_selectedPatient != null) _loadAlerts(_selectedPatient!.patientId);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'System triggers based on 7-day memory variance & missed routines',
            style: TextStyle(fontSize: 11, color: Color(0xFF5A7264)),
          ),
          const SizedBox(height: 14),
          if (_isLoadingAlerts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Color(0xFF23654D)),
              ),
            )
          else if (_alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF23654D), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All clear! No alerts recorded for this loved one.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F4D36)),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._alerts.map((a) => _buildAlertCard(a)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(CaregiverAlert alert) {
    Color bg = const Color(0xFFF9F8F4);
    Color border = const Color(0xFFE5E7EB);
    Color tagColor = const Color(0xFF0284C7);
    IconData icon = Icons.info_outline;

    if (alert.severity == 'CRITICAL') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      tagColor = const Color(0xFFDC2626);
      icon = Icons.warning_rounded;
    } else if (alert.severity == 'WARNING') {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFCD34D);
      tagColor = const Color(0xFFD97706);
      icon = Icons.priority_high_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.isAcknowledged ? Colors.grey.shade50 : bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alert.isAcknowledged ? Colors.grey.shade300 : border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alert.isAcknowledged ? Icons.check_circle : icon,
            color: alert.isAcknowledged ? Colors.grey : tagColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: alert.isAcknowledged ? Colors.grey.shade600 : AppColors.primary,
                          decoration: alert.isAcknowledged ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: alert.isAcknowledged ? Colors.grey.shade200 : tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.severity,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: alert.isAcknowledged ? Colors.grey.shade600 : tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: alert.isAcknowledged ? Colors.grey.shade500 : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                if (!alert.isAcknowledged)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _acknowledgeAlert(alert),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Acknowledge'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(60, 28),
                        side: BorderSide(color: tagColor),
                        foregroundColor: tagColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                else
                  Text(
                    'Reviewed & acknowledged',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickShortcutsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.photo_library, color: Color(0xFF23654D)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Memories & Stories', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 2),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.alarm, color: Color(0xFF23654D)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Medicine & Care', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 1: Section 5: Reminiscence Vault
  // ----------------------------------------------------

  Widget _buildReminiscenceVaultTab() {
    final patient = _selectedPatient;

    return RefreshIndicator(
      onRefresh: () async {
        if (patient != null) await _loadReminiscences(patient.patientId);
      },
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reminiscence Vault',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (patient != null)
                      Text(
                        'Preserving memories for ${patient.fullName}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                      ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddMemoryModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Memory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23654D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingReminiscences)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF23654D)),
                ),
              )
            else if (_reminiscences.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1EFE3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_album, color: Color(0xFF23654D), size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Vault is Empty',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add cherished family photos, audio voice notes, and milestone stories to strengthen recall.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddMemoryModal,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add First Memory'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23654D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._reminiscences.map((mem) => _buildReminiscenceCard(mem)),
          ],
        ),
      ),
    );
  }

  Widget _buildReminiscenceCard(ReminiscenceVaultItem mem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory banner or picture placeholder
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EFE3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: (mem.mediaUrl != null && mem.mediaUrl!.isNotEmpty && !mem.mediaUrl!.startsWith('http'))
                  ? DecorationImage(
                      image: AssetImage(mem.mediaUrl!),
                      fit: BoxFit.cover,
                      onError: (err, stack) {},
                    )
                  : null,
            ),
            child: (mem.mediaUrl == null || mem.mediaUrl!.isEmpty || mem.mediaUrl!.startsWith('http'))
                ? Center(
                    child: Icon(
                      mem.mediaType == 'AUDIO' ? Icons.mic : Icons.photo_camera,
                      size: 48,
                      color: const Color(0xFF23654D).withValues(alpha: 0.5),
                    ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4EBA3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mem.relationshipTag,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F4D36)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () => _deleteReminiscence(mem.id),
                      tooltip: 'Delete Memory',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mem.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                if (mem.caption != null && mem.caption!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mem.caption!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      mem.mediaType == 'AUDIO' ? Icons.audiotrack : Icons.image,
                      size: 14,
                      color: const Color(0xFF23654D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mem.mediaType == 'AUDIO' ? 'Voice Memo' : 'Photo Memory',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF23654D)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: Section 6: Reminder Scheduler
  // ----------------------------------------------------

  Widget _buildRemindersTab() {
    final filtered = _reminders.where((r) {
      if (_reminderFilter == 'ALL') return true;
      return r.reminderType.toUpperCase() == _reminderFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadReminders,
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Reminders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Medicine, Hydration & Routine tracking',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddReminderModal,
                  icon: const Icon(Icons.add_alarm, size: 16),
                  label: const Text('New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23654D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildReminderFilterChip('ALL', 'All (${_reminders.length})'),
                  const SizedBox(width: 8),
                  _buildReminderFilterChip('MEDICINE', 'Medicine'),
                  const SizedBox(width: 8),
                  _buildReminderFilterChip('HYDRATION', 'Hydration'),
                  const SizedBox(width: 8),
                  _buildReminderFilterChip('MEAL', 'Meals'),
                  const SizedBox(width: 8),
                  _buildReminderFilterChip('GAME', 'Games'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingReminders)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF23654D)),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1EFE3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.alarm_off, color: Color(0xFF23654D), size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Reminders in this Filter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "New" to schedule medication times or hydration intervals.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...filtered.map((reminder) {
                return ReminderCard(
                  reminder: reminder,
                  onToggle: () => _toggleAcknowledge(reminder),
                  onDelete: () => _deleteReminder(reminder),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderFilterChip(String key, String label) {
    final isSel = _reminderFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _reminderFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF23654D) : const Color(0xFFF1EFE3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: isSel ? Colors.white : const Color(0xFF1F4D36),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 3: Care Circle & ASHA Coordination
  // ----------------------------------------------------

  Widget _buildCareCircleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Care Circle',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Connected family members, healthcare workers, and patients',
            style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Loved Ones (${_myPatients.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
              ),
              TextButton.icon(
                onPressed: () => _showConnectPatientModal(context),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF23654D)),
                label: const Text('Connect', style: TextStyle(color: Color(0xFF23654D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._myPatients.map((patient) => _buildConnectedPatientCard(patient)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connected to Community ASHA health network.'),
                  backgroundColor: Color(0xFF23654D),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text('Message ASHA Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF23654D),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConnectedPatientCard(CaregiverPatient patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF1EFE3),
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
                  style: const TextStyle(color: Color(0xFF23654D), fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                    ),
                    Text(
                      '${patient.relationship} • ${patient.age} yrs',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () => _confirmDisconnect(patient),
                tooltip: 'Disconnect',
              ),
            ],
          ),
          if (patient.ashaName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFE3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Color(0xFF23654D), size: 14),
                  const SizedBox(width: 6),
                  Text('ASHA: ${patient.ashaName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
