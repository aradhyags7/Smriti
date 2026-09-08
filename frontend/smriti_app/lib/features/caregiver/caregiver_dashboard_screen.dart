import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../auth/services/auth_service.dart';
import '../patient/widgets/reminder_card.dart';
import '../reminders/reminder_model.dart';
import '../reminders/reminder_service.dart';
import 'services/caregiver_service.dart';

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

  List<ReminderItem> _reminders = [];
  bool _isLoadingReminders = false;

  List<CaregiverPatient> _myPatients = [];
  bool _isLoadingPatients = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadReminders();
    _loadPatients();
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

  Future<void> _loadPatients() async {
    setState(() => _isLoadingPatients = true);
    final pts = await _caregiverService.fetchMyPatients();
    if (mounted) {
      setState(() {
        _myPatients = pts;
        _isLoadingPatients = false;
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
                  'Family Caregiver',
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
    final List<String> relationOptions = [
      'Mother',
      'Father',
      'Spouse',
      'Grandmother',
      'Grandfather',
      'Relative',
      'Family Caregiver'
    ];

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
                          child: const Icon(Icons.person_add, color: Color(0xFF23654D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect a Loved One',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Select a registered family member to care for',
                              style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Relationship',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: relationOptions.map((rel) {
                        final isSel = selectedRelation == rel;
                        return ChoiceChip(
                          label: Text(rel),
                          selected: isSel,
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedRelation = rel);
                          },
                          selectedColor: const Color(0xFF23654D),
                          backgroundColor: const Color(0xFFF1EFE3),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF1F4D36),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSel ? const Color(0xFF23654D) : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose from Registered Patients',
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
                              'No registered patients found. You can enter patient email below.',
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

                        if (mounted) {
                          if (success) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Connected to loved one as $selectedRelation!'),
                                backgroundColor: const Color(0xFF23654D),
                              ),
                            );
                            _loadPatients();
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to connect patient. Please verify the account.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
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
              if (mounted) {
                if (success) {
                  _loadPatients();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${patient.fullName} disconnected.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Disconnect'),
          ),
        ],
      ),
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
                              'Set medication, routine or hydration for loved one',
                              style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Reminder Title',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Morning Blood Pressure Tablet',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF23654D), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scheduled Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              formatTime(selectedTime),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reminder Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('MEDICINE', 'Medication', Icons.medication, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                        _buildChoiceChip('ROUTINE', 'Routine', Icons.alarm, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                        _buildChoiceChip('HYDRATION', 'Hydration', Icons.water_drop, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                        _buildChoiceChip('EXERCISE', 'Exercise', Icons.directions_walk, selectedType, (val) {
                          setModalState(() => selectedType = val);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Frequency',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
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

                        final created = await _reminderService.createReminder(
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

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(width: 12),
            const Text(
              'Family Caregiver Portal',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primary),
            onPressed: () {},
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
      body: _selectedIndex == 0 ? _buildOverviewView() : _buildRemindersView(),
      bottomNavigationBar: Container(
        color: const Color(0xFF23654D),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                iconData: Icons.dashboard,
                label: 'Overview',
              ),
              _buildNavItem(
                index: 1,
                iconData: Icons.alarm_add,
                label: 'Reminders',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewView() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadPatients();
        await _loadReminders();
      },
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $_userName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitoring care & daily routines',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5A7264),
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Loved Ones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                TextButton.icon(
                  onPressed: () => _showConnectPatientModal(context),
                  icon: const Icon(Icons.add, size: 18, color: Color(0xFF23654D)),
                  label: const Text(
                    'Connect Loved One',
                    style: TextStyle(
                      color: Color(0xFF23654D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingPatients)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFF23654D)),
                ),
              )
            else if (_myPatients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1EFE3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.family_restroom, color: Color(0xFF23654D), size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Loved Ones Connected Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connect your family member to monitor daily routines, reminders, and gentle memory check-ins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showConnectPatientModal(context),
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Connect a Loved One'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23654D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._myPatients.map((patient) => _buildConnectedPatientCard(patient)),
            const SizedBox(height: 32),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Memory Match Game Played', 'Today, 10:30 AM', Icons.sports_esports, const Color(0xFFA6EBCF)),
            const SizedBox(height: 12),
            _buildActivityItem('Cognitive Health Check', 'Yesterday', Icons.health_and_safety, const Color(0xFFFFDBA6)),
            const SizedBox(height: 32),
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
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedPatientCard(CaregiverPatient patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFF1EFE3),
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Color(0xFF23654D),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
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
                    Text(
                      '${patient.age} yrs • Gender: ${patient.gender.toUpperCase()}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF23654D), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      patient.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF23654D),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Baseline Memory: ${patient.baselineMemory.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A7264),
                ),
              ),
            ],
          ),
          if (patient.ashaName != null) ...[
            const SizedBox(height: 10),
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemindersView() {
    return RefreshIndicator(
      onRefresh: _loadReminders,
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Reminders',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create reminders for your loved ones (medication, games, checkups).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5A7264),
                  ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddReminderModal,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Add New Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23654D),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Active Reminders (${_reminders.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
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
            else if (_reminders.isEmpty)
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
                      'No Reminders Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Add New Reminder" above to set medication times, hydration, or daily activities.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ..._reminders.map((reminder) {
                return ReminderCard(
                  reminder: reminder,
                  onToggle: () => _toggleAcknowledge(reminder),
                  onDelete: () => _deleteReminder(reminder),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1F4D36), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
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
        if (index == 1) {
          _loadReminders();
        } else if (index == 0) {
          _loadPatients();
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
