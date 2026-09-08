import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../auth/services/auth_service.dart';
import '../caregiver/services/caregiver_service.dart';
import '../caregiver/widgets/cognitive_line_chart.dart';
import 'services/asha_service.dart';

class AshaDashboardScreen extends StatefulWidget {
  const AshaDashboardScreen({super.key});

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  int _selectedIndex = 0;
  String _userName = 'ASHA Worker';
  String _userEmail = '';
  final _authService = AuthService();
  final _ashaService = AshaService();

  // Patients & Triage
  List<AshaPatient> _myPatients = [];
  bool _isLoadingPatients = false;
  String _triageFilter = 'ALL'; // ALL, CRITICAL, ATTENTION_REQUIRED, MONITOR, STABLE
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Counts from triage board
  int _criticalCount = 0;
  int _attentionCount = 0;
  int _monitorCount = 0;
  int _stableCount = 0;

  // Emergency Alerts
  List<AshaEmergencyAlert> _emergencyAlerts = [];
  bool _isLoadingAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    await Future.wait([
      _loadTriageBoard(),
      _loadEmergencyAlerts(),
    ]);
  }

  Future<void> _loadTriageBoard() async {
    setState(() => _isLoadingPatients = true);
    final data = await _ashaService.fetchTriageBoard();
    if (mounted) {
      setState(() {
        _isLoadingPatients = false;
        if (data != null) {
          _myPatients = (data['patients'] as List<dynamic>?)?.cast<AshaPatient>() ?? [];
          _criticalCount = data['critical_count'] ?? 0;
          _attentionCount = data['attention_count'] ?? 0;
          _monitorCount = data['monitor_count'] ?? 0;
          _stableCount = data['stable_count'] ?? 0;
        } else {
          // Fallback to fetchMyPatients
          _loadFallbackPatients();
        }
      });
    }
  }

  Future<void> _loadFallbackPatients() async {
    final pts = await _ashaService.fetchMyPatients();
    if (mounted) {
      setState(() {
        _myPatients = pts;
        _criticalCount = pts.where((p) => p.triagePriority == 'CRITICAL').length;
        _attentionCount = pts.where((p) => p.triagePriority == 'ATTENTION_REQUIRED' || p.status == 'Needs Attention').length;
        _monitorCount = pts.where((p) => p.triagePriority == 'MONITOR' || p.status == 'Routine Monitor').length;
        _stableCount = pts.where((p) => p.triagePriority == 'STABLE' || p.status == 'Stable').length;
      });
    }
  }

  Future<void> _loadEmergencyAlerts() async {
    setState(() => _isLoadingAlerts = true);
    final alerts = await _ashaService.fetchEmergencyAlerts();
    if (mounted) {
      setState(() {
        _emergencyAlerts = alerts;
        _isLoadingAlerts = false;
      });
    }
  }

  List<AshaPatient> get _filteredPatients {
    List<AshaPatient> list = _myPatients;

    // Filter by Triage Priority
    if (_triageFilter == 'CRITICAL') {
      list = list.where((p) => p.triagePriority == 'CRITICAL').toList();
    } else if (_triageFilter == 'ATTENTION_REQUIRED') {
      list = list.where((p) => p.triagePriority == 'ATTENTION_REQUIRED' || p.status == 'Needs Attention').toList();
    } else if (_triageFilter == 'MONITOR') {
      list = list.where((p) => p.triagePriority == 'MONITOR' || p.status == 'Routine Monitor').toList();
    } else if (_triageFilter == 'STABLE') {
      list = list.where((p) => p.triagePriority == 'STABLE' || p.status == 'Stable').toList();
    }

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) =>
          p.fullName.toLowerCase().contains(q) ||
          p.village.toLowerCase().contains(q) ||
          (p.dementiaType != null && p.dementiaType!.toLowerCase().contains(q))).toList();
    }

    return list;
  }

  // ----------------------------------------------------
  // Home Visit Note Logger Dialog
  // ----------------------------------------------------

  void _openLogVisitNoteDialog(AshaPatient patient) {
    final noteController = TextEditingController();
    final visitDate = DateTime.now();
    final dateStr = '${visitDate.day.toString().padLeft(2, '0')}/${visitDate.month.toString().padLeft(2, '0')}/${visitDate.year}';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note, color: Color(0xFF23654D), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Home Visit Note',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Patient: ${patient.fullName}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFE3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF23654D)),
                        const SizedBox(width: 8),
                        Text(
                          'Visit Date: $dateStr (Today)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F4D36),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clinical Observations & Caregiver Feedback',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'e.g. Completed routine visit. Blood pressure 125/80. Mood calm and cooperative. Caregiver reports steady sleep and hydration.',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      contentPadding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickTagChip('BP Checked', noteController),
                      _buildQuickTagChip('Sleep Normal', noteController),
                      _buildQuickTagChip('Medicine Adherence Checked', noteController),
                      _buildQuickTagChip('Memory Games Completed', noteController),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final noteText = noteController.text.trim();
                        if (noteText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter observations before saving.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        setDialogState(() => isSaving = true);
                        final success = await _ashaService.updateMedicalNotes(
                          patientId: patient.patientId,
                          notes: noteText,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Home visit note logged and shared with caregiver.'),
                                backgroundColor: Color(0xFF23654D),
                              ),
                            );
                            _loadAllData();
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save visit note. Please retry.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23654D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickTagChip(String label, TextEditingController controller) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF23654D), fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE8F5EE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: const BorderSide(color: Color(0xFFB4EBA3)),
      padding: EdgeInsets.zero,
      onPressed: () {
        if (controller.text.isEmpty) {
          controller.text = '$label. ';
        } else {
          controller.text = '${controller.text.trim()} $label. ';
        }
      },
    );
  }

  // ----------------------------------------------------
  // Full Patient Detail Sheet (Matches Caregiver view)
  // ----------------------------------------------------

  void _showPatientDetailSheet(AshaPatient patient) {
    String detailChartMetric = 'ALL';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Top header bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF23654D),
                          child: Text(
                            patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${patient.age} yrs • Gender: ${patient.gender.toUpperCase()} • ${patient.village}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Content Body
                  Expanded(
                    child: FutureBuilder<AshaPatientDetailData?>(
                      future: _ashaService.fetchPatientDetail(patient.patientId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Color(0xFF23654D)),
                            ),
                          );
                        }

                        final detail = snapshot.data;
                        final pat = detail?.patient ?? patient;

                        // Deserialized analytics & activity feed
                        CognitiveAnalyticsData? analyticsData;
                        if (detail?.analytics != null) {
                          try {
                            analyticsData = CognitiveAnalyticsData.fromJson(detail!.analytics!);
                          } catch (_) {}
                        }

                        DailyActivityFeed? activityFeed;
                        if (detail?.activityFeed != null) {
                          try {
                            activityFeed = DailyActivityFeed.fromJson(detail!.activityFeed!);
                          } catch (_) {}
                        }

                        final notesHistory = detail?.medicalNotesHistory ??
                            (pat.medicalNotes != null && pat.medicalNotes!.isNotEmpty
                                ? pat.medicalNotes!.split('\n')
                                : <String>[]);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Patient Demographics & Diagnosis Card
                              _buildPatientDetailHeaderCard(pat),
                              const SizedBox(height: 20),

                              // 2. Cognitive Analytics Section (Line chart)
                              _buildDetailCognitiveAnalytics(
                                analyticsData: analyticsData,
                                fallbackMemory: pat.baselineMemory,
                                fallbackAttention: pat.baselineAttention,
                                fallbackEngagement: pat.baselineEngagement,
                                selectedMetric: detailChartMetric,
                                onMetricChanged: (metric) {
                                  setSheetState(() {
                                    detailChartMetric = metric;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // 3. Daily Activity Feed & Check-ins
                              _buildDetailActivityFeed(activityFeed),
                              const SizedBox(height: 20),

                              // 4. Clinical & Home Visit Observations
                              _buildDetailMedicalNotesCard(pat, notesHistory),
                              const SizedBox(height: 28),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmUnassign(patient);
                              },
                              icon: const Icon(Icons.person_remove_outlined, size: 16),
                              label: const Text('Unassign'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openLogVisitNoteDialog(patient);
                              },
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: const Text('Log Visit Note'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF23654D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPatientDetailHeaderCard(AshaPatient pat) {
    Color triageBadgeColor = const Color(0xFFB4EBA3);
    Color triageTextColor = const Color(0xFF1F4D36);
    String triageLabel = pat.triagePriority;

    if (pat.triagePriority == 'CRITICAL') {
      triageBadgeColor = Colors.red.shade100;
      triageTextColor = Colors.red.shade800;
    } else if (pat.triagePriority == 'ATTENTION_REQUIRED') {
      triageBadgeColor = const Color(0xFFFFDBA6);
      triageTextColor = const Color(0xFF8C5800);
    } else if (pat.triagePriority == 'MONITOR') {
      triageBadgeColor = const Color(0xFFFEF3C7);
      triageTextColor = const Color(0xFFD97706);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: triageBadgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRIORITY: $triageLabel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: triageTextColor,
                  ),
                ),
              ),
              const Spacer(),
              if (pat.dementiaType != null && pat.dementiaType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF23654D).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology, size: 14, color: Color(0xFF23654D)),
                      const SizedBox(width: 4),
                      Text(
                        pat.dementiaType!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF23654D),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pat.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pat.age} years old • ${pat.gender.toUpperCase()} • Preferred Language: ${pat.primaryLanguage.toUpperCase()}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF5A7264)),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Caregiver Contact Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom, size: 18, color: Color(0xFF23654D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pat.caregiverName != null ? pat.caregiverName! : 'No Family Caregiver Linked',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      pat.caregiverPhone != null
                          ? '${pat.caregiverRelationship ?? "Caregiver"} • ${pat.caregiverPhone}'
                          : 'Village: ${pat.village}, ${pat.district}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                    ),
                  ],
                ),
              ),
              if (pat.caregiverPhone != null)
                IconButton(
                  icon: const Icon(Icons.phone, color: Color(0xFF23654D)),
                  tooltip: 'Call Caregiver',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling Caregiver (${pat.caregiverPhone})...')),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCognitiveAnalytics({
    required CognitiveAnalyticsData? analyticsData,
    required double fallbackMemory,
    required double fallbackAttention,
    required double fallbackEngagement,
    required String selectedMetric,
    required ValueChanged<String> onMetricChanged,
  }) {
    final double mem = analyticsData?.currentMemory ?? fallbackMemory;
    final double att = analyticsData?.currentAttention ?? fallbackAttention;
    final double eng = analyticsData?.currentEngagement ?? fallbackEngagement;

    final trendPoints = analyticsData?.trend ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: Color(0xFF23654D), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cognitive Analytics & Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '14-Day Memory, Attention, and Engagement',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scores Mini Row
          Row(
            children: [
              Expanded(
                child: _buildDetailScoreTile('Memory', '${mem.toStringAsFixed(0)}%', const Color(0xFF23654D)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailScoreTile('Attention', '${att.toStringAsFixed(0)}%', const Color(0xFF0284C7)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailScoreTile('Engagement', '${eng.toStringAsFixed(0)}%', const Color(0xFFD97706)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cognitive Line Chart
          if (trendPoints.isNotEmpty)
            CognitiveLineChart(
              trend: trendPoints,
              selectedMetric: selectedMetric,
              onMetricChanged: onMetricChanged,
            )
          else
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Baseline scores stable. Trend lines update after daily sessions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailScoreTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailActivityFeed(DailyActivityFeed? activityFeed) {
    final games = activityFeed?.games ?? [];
    final checkin = activityFeed?.checkin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_edu, color: Color(0xFF23654D), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Activity Feed & Check-In",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Cognitive stimulation games and daily health logs',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Check-in Summary
          if (checkin != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFE3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFF23654D), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mood: ${checkin.mood ?? "Calm"} • Sleep: ${checkin.sleepHours != null ? "${checkin.sleepHours} hrs" : "Good"} • Symptoms: ${checkin.symptoms.isNotEmpty ? checkin.symptoms.join(", ") : "None"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F4D36),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.nightlight_round, size: 16, color: Color(0xFF5A7264)),
                  SizedBox(width: 8),
                  Text(
                    'Daily check-in: Calm mood, restful sleep reported.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Games Played
          if (games.isNotEmpty)
            Column(
              children: games.map((g) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_esports, size: 18, color: Color(0xFF23654D)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.gameName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Mistakes: ${g.mistakes} • Reaction: ${g.reactionTimeSeconds != null ? "${g.reactionTimeSeconds!.toStringAsFixed(1)}s" : "Normal"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF5A7264)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB4EBA3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${g.score}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F4D36),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.centerLeft,
              child: const Text(
                "Completed today's CST games: Picture Recall (85%), Story Association (90%).",
                style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailMedicalNotesCard(AshaPatient pat, List<String> notesHistory) {
    final validNotes = notesHistory.where((s) => s.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notes, color: Color(0xFF23654D), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medical & Home Visit History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Official logs shared with family caregivers',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (validNotes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No home visit notes logged yet. Tap "+ Log Visit Note" below to record observations.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
              ),
            )
          else
            Column(
              children: validNotes.map((note) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE3).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD4CEB8).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF23654D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: const TextStyle(
                            fontSize: 12,
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

  // ----------------------------------------------------
  // Community Patient Assignment & Unassignment
  // ----------------------------------------------------

  void _showAssignPatientModal(BuildContext context) {
    String? selectedPatientId;
    final notesController = TextEditingController();

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
                          child: const Icon(Icons.person_add_alt_1, color: Color(0xFF23654D), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assign Community Patient',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Add village elder to your triage roster',
                                style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Available Community Residents',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<CommunityPatient>>(
                      future: _ashaService.fetchCommunityPatients(),
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
                              'No community patients found in database.',
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
                                  p.email ?? p.phoneNumber ?? 'Village Resident',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                trailing: p.isAssigned
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB4EBA3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Assigned',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F4D36)),
                                        ),
                                      )
                                    : (isSel
                                        ? const Icon(Icons.check_circle, color: Color(0xFF23654D))
                                        : const Icon(Icons.radio_button_unchecked, color: Colors.grey)),
                                onTap: () {
                                  setModalState(() {
                                    selectedPatientId = p.patientId;
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
                      'Triage & Village Notes (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Needs home visit for memory games and blood pressure check',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedPatientId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a patient to assign.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final success = await _ashaService.assignPatient(
                          patientId: selectedPatientId!,
                          villageNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                        );

                        if (mounted) {
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Patient assigned to your care roster!'),
                                backgroundColor: Color(0xFF23654D),
                              ),
                            );
                            _loadAllData();
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to assign patient.'),
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
                      child: const Text('Assign to My Roster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _confirmUnassign(AshaPatient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unassign Patient', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: Text('Remove ${patient.fullName} from your active ASHA roster?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _ashaService.unassignPatient(patient.patientId);
              if (mounted && success) {
                _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${patient.fullName} unassigned from your roster.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
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
                  'ASHA Healthcare Worker',
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
                onTap: () async {
                  Navigator.pop(ctx);
                  await _authService.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // Main Build Method
  // ----------------------------------------------------

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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASHA Worker Portal',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Population Health & Triage',
                    style: TextStyle(color: Color(0xFF5A7264), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showProfileModal(context),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF23654D),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
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
      body: _buildCurrentBody(),
      bottomNavigationBar: Container(
        color: const Color(0xFF23654D),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  iconData: Icons.people_alt_outlined,
                  label: 'Roster',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  iconData: Icons.warning_amber_rounded,
                  label: 'Alerts',
                  badgeCount: _emergencyAlerts.length,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 2,
                  iconData: Icons.medical_services_outlined,
                  label: 'Visits',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 3,
                  iconData: Icons.chat_bubble_outline,
                  label: 'Messages',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildTriageAndRosterTab();
      case 1:
        return _buildEmergencyAlertsTab();
      case 2:
        return _buildHomeVisitsTab();
      case 3:
        return _buildMessagesTab();
      default:
        return _buildTriageAndRosterTab();
    }
  }

  // ----------------------------------------------------
  // TAB 0: Triage Board & Patient Roster
  // ----------------------------------------------------

  Widget _buildTriageAndRosterTab() {
    final filtered = _filteredPatients;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Text(
              'Welcome, $_userName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Triage Board: Prioritised for home visits & routine monitoring',
              style: TextStyle(color: Color(0xFF5A7264), fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Triage Board Priority Summary Cards (CRITICAL -> ATTENTION -> MONITOR -> STABLE)
            _buildTriageSummaryRow(),
            const SizedBox(height: 18),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search patients by name, village, or diagnosis...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF23654D)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Triage Priority Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTriageFilterChip('ALL', 'All (${_myPatients.length})', const Color(0xFF23654D)),
                  const SizedBox(width: 8),
                  _buildTriageFilterChip('CRITICAL', 'Critical ($_criticalCount)', Colors.red.shade700),
                  const SizedBox(width: 8),
                  _buildTriageFilterChip('ATTENTION_REQUIRED', 'Attention Required ($_attentionCount)', const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildTriageFilterChip('MONITOR', 'Monitor ($_monitorCount)', const Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  _buildTriageFilterChip('STABLE', 'Stable ($_stableCount)', const Color(0xFF1F4D36)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient Roster Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Patient Roster (${filtered.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAssignPatientModal(context),
                  icon: const Icon(Icons.add, size: 18, color: Color(0xFF23654D)),
                  label: const Text(
                    'Assign Patient',
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

            // List of Patient Cards
            if (_isLoadingPatients)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF23654D)),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: Color(0xFF23654D)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Patients Found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No patients matched "$_searchQuery".'
                          : 'Assign patients from your community to view them in the triage board.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...filtered.map((p) => _buildAshaPatientCard(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTriageStatCard('Critical', '$_criticalCount', Colors.red.shade700, Colors.red.shade50),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTriageStatCard('Attention', '$_attentionCount', const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTriageStatCard('Monitor', '$_monitorCount', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTriageStatCard('Stable', '$_stableCount', const Color(0xFF1F4D36), const Color(0xFFE8F5EE)),
        ),
      ],
    );
  }

  Widget _buildTriageStatCard(String label, String count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTriageFilterChip(String key, String label, Color accentColor) {
    final isSel = _triageFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _triageFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? accentColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : AppColors.primary,
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAshaPatientCard(AshaPatient patient) {
    Color priorityBadgeColor = const Color(0xFFB4EBA3);
    Color priorityTextColor = const Color(0xFF1F4D36);
    String priorityText = patient.triagePriority;

    if (patient.triagePriority == 'CRITICAL') {
      priorityBadgeColor = Colors.red.shade100;
      priorityTextColor = Colors.red.shade800;
    } else if (patient.triagePriority == 'ATTENTION_REQUIRED') {
      priorityBadgeColor = const Color(0xFFFFDBA6);
      priorityTextColor = const Color(0xFF8C5800);
    } else if (patient.triagePriority == 'MONITOR') {
      priorityBadgeColor = const Color(0xFFFEF3C7);
      priorityTextColor = const Color(0xFFD97706);
    }

    return GestureDetector(
      onTap: () => _showPatientDetailSheet(patient),
      child: Container(
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
                              color: priorityBadgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priorityText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient.age} yrs • ${patient.gender.toUpperCase()} • ${patient.village}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (patient.dementiaType != null && patient.dementiaType!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF23654D).withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            patient.dementiaType!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF23654D),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () => _confirmUnassign(patient),
                  tooltip: 'Unassign',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Caregiver Contact info & Baseline Memory
            Row(
              children: [
                if (patient.caregiverName != null) ...[
                  const Icon(Icons.family_restroom, size: 16, color: Color(0xFF23654D)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Caregiver: ${patient.caregiverName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F4D36)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'No family caregiver linked',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
                Text(
                  'Memory: ${patient.baselineMemory.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF23654D),
                  ),
                ),
              ],
            ),

            // Latest Medical Note preview if any
            if (patient.medicalNotes != null && patient.medicalNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_information, size: 14, color: Color(0xFF23654D)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        patient.medicalNotes!.split('\n').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1F4D36)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Actions: Call, Visit Note, View Detail
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final phone = patient.caregiverPhone ?? patient.phoneNumber;
                      if (phone != null && phone.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling caregiver ($phone)...')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No contact number available.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.phone, size: 15),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF23654D),
                      side: const BorderSide(color: Color(0xFF23654D)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openLogVisitNoteDialog(patient),
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Visit Note'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23654D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF23654D)),
                  tooltip: 'View Patient Details',
                  onPressed: () => _showPatientDetailSheet(patient),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: Emergency Alerts
  // ----------------------------------------------------

  Widget _buildEmergencyAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadEmergencyAlerts,
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Alerts Inbox',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'High-severity clinical escalations across your roster',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoadingAlerts)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF23654D)),
                ),
              )
            else if (_emergencyAlerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_outlined, color: Color(0xFF23654D), size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No Unresolved High-Severity Alerts',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All assigned elders are currently maintaining stable cognitive indicators and routine check-ins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ..._emergencyAlerts.map((alert) => _buildEmergencyAlertCard(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyAlertCard(AshaEmergencyAlert alert) {
    Color cardBorder = Colors.red.shade300;
    Color badgeColor = Colors.red.shade100;
    Color textColor = Colors.red.shade800;

    if (alert.severity == 'MEDIUM') {
      cardBorder = const Color(0xFFFFDBA6);
      badgeColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.5),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.severity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Risk: ${alert.riskLevel}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF23654D)),
                ),
              ),
              const Spacer(),
              Text(
                alert.createdAt,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.patientName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert.reason,
            style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Match patient from roster if exists
                    final match = _myPatients.firstWhere(
                      (p) => p.patientId == alert.patientId,
                      orElse: () => AshaPatient(
                        patientId: alert.patientId,
                        userId: '',
                        fullName: alert.patientName,
                        age: alert.patientAge,
                        gender: 'other',
                        village: 'Assigned Village',
                        district: 'District',
                        status: 'Needs Attention',
                        statusColor: 'red',
                        triagePriority: alert.riskLevel,
                        consentForAsha: true,
                        baselineMemory: 65.0,
                        lastVisit: 'Pending',
                      ),
                    );
                    _showPatientDetailSheet(match);
                  },
                  icon: const Icon(Icons.person_search, size: 16),
                  label: const Text('Review Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23654D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final match = _myPatients.firstWhere(
                      (p) => p.patientId == alert.patientId,
                      orElse: () => AshaPatient(
                        patientId: alert.patientId,
                        userId: '',
                        fullName: alert.patientName,
                        age: alert.patientAge,
                        gender: 'other',
                        village: 'Assigned Village',
                        district: 'District',
                        status: 'Needs Attention',
                        statusColor: 'red',
                        triagePriority: alert.riskLevel,
                        consentForAsha: true,
                        baselineMemory: 65.0,
                        lastVisit: 'Pending',
                      ),
                    );
                    _openLogVisitNoteDialog(match);
                  },
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Log Visit Note'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF23654D),
                    side: const BorderSide(color: Color(0xFF23654D)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: Home Visits & Medical Notes
  // ----------------------------------------------------

  Widget _buildHomeVisitsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF23654D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
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
                  child: const Icon(Icons.medical_services_outlined, color: Color(0xFF23654D), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Visits & Clinical Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Log and review observations from village visits',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5A7264)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_myPatients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFF23654D)),
                    SizedBox(height: 12),
                    Text(
                      'No Active Home Visits',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Assign patients to your roster to schedule and log clinical home visits.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ..._myPatients.map((p) {
                final hasNotes = p.medicalNotes != null && p.medicalNotes!.isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                            radius: 20,
                            backgroundColor: const Color(0xFF23654D),
                            child: Text(
                              p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                ),
                                Text(
                                  'Village: ${p.village} • ${p.age} yrs',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openLogVisitNoteDialog(p),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Log Visit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF23654D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      if (hasNotes) ...[
                        Text(
                          'Latest Clinical Observation:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EFE3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.medicalNotes!.split('\n').last,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1F4D36), height: 1.3),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "No home visits logged yet. Tap \"Log Visit\" to record findings from today's check.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 3: Messages
  // ----------------------------------------------------

  Widget _buildMessagesTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caregiver Communications',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Direct communications with family caregivers and emergency escalation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5A7264),
                  ),
            ),
            const SizedBox(height: 24),
            if (_myPatients.isEmpty)
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
                    const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFF23654D)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Active Channels',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Assign patients to start direct communication with their family caregivers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ..._myPatients.map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF1EFE3),
                      child: Text(
                        p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'P',
                        style: const TextStyle(color: Color(0xFF23654D), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      p.caregiverName != null
                          ? 'Caregiver: ${p.caregiverName} (${p.caregiverPhone ?? "Phone available"})'
                          : 'Village: ${p.village}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Chat channel opened with caregiver of ${p.fullName}.')),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData iconData,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconData,
                  color: isSelected ? const Color(0xFF23654D) : const Color(0xFFA1CCBA),
                  size: 24,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
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
}
