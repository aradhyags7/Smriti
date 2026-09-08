import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'reminder_model.dart';
import 'reminder_notification_service.dart';
import 'reminder_service.dart';

// ============================================================================
// Smriti Design System Color Palette (Elderly-friendly, warm & calm)
// ============================================================================
class SmritiTheme {
  static const Color primaryGreen = Color(0xFF245C4A); // Deep forest / teal green
  static const Color secondaryGreen = Color(0xFFA7E8C4); // Soft mint for actions & badges
  static const Color lightMint = Color(0xFFB7EBDD); // Icon background
  static const Color softYellow = Color(0xFFF9DFA5); // Highlight pastel
  static const Color warmCream = Color(0xFFF8F6EF); // Main screen background
  static const Color cardWhite = Colors.white; // Card and dialog surfaces

  static const Color textPrimary = Color(0xFF1E2421); // Near-black for headings & titles
  static const Color textSecondary = Color(0xFF5A635E); // Muted dark gray
  static const Color cardBorder = Color(0xFFEAE7DC); // Subtle card outline
  static const Color activeGreenBg = Color(0xFFE4F7EE); // Active/Done badge background
  static const Color activeGreenText = Color(0xFF1B6344); // Active badge text
  static const Color pausedBg = Color(0xFFEEECE4); // Paused badge background
  static const Color pausedText = Color(0xFF737C77); // Paused badge text
}

/// Elderly-friendly Reminders Screen matching the Smriti visual design.
class RemindersScreen extends StatefulWidget {
  final IReminderService? reminderService;
  final IReminderNotificationService? notificationService;

  const RemindersScreen({
    super.key,
    this.reminderService,
    this.notificationService,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final IReminderService _reminderService;
  late final IReminderNotificationService _notificationService;

  bool _isLoading = true;
  List<ReminderModel> _reminders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _reminderService = widget.reminderService ?? ReminderService();
    _notificationService = widget.notificationService ?? ReminderNotificationService();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _reminderService.initialize();
      final list = await _reminderService.getAllReminders();
      if (mounted) {
        setState(() {
          _reminders = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load reminders. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateOrUpdate(ReminderModel reminder, {required bool isNew}) async {
    try {
      if (isNew) {
        await _reminderService.createReminder(reminder);
      } else {
        await _reminderService.updateReminder(reminder);
      }

      // Schedule or update local notification
      bool scheduled = false;
      try {
        if (isNew) {
          scheduled = await _notificationService.scheduleReminder(reminder);
        } else {
          scheduled = await _notificationService.rescheduleReminder(reminder);
        }
      } catch (_) {
        scheduled = false;
      }

      await _loadReminders();

      if (mounted && reminder.isEnabled && !scheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reminder saved, but notification could not be scheduled.',
              style: TextStyle(fontSize: 15),
            ),
            backgroundColor: SmritiTheme.primaryGreen,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save reminder. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleEnable(ReminderModel reminder) async {
    final newEnabled = !reminder.isEnabled;
    try {
      if (newEnabled) {
        await _reminderService.enableReminder(reminder.id);
        await _notificationService.scheduleReminder(reminder.copyWith(isEnabled: true));
      } else {
        await _reminderService.disableReminder(reminder.id);
        await _notificationService.cancelReminder(reminder.id);
      }
      await _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update reminder status.')),
        );
      }
    }
  }

  Future<void> _handleAcknowledge(ReminderModel reminder) async {
    try {
      await _reminderService.acknowledgeReminder(reminder.id);
      await _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked "${reminder.title}" as done.'),
            backgroundColor: SmritiTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not mark as done.')),
        );
      }
    }
  }

  Future<void> _handleDelete(ReminderModel reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SmritiTheme.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Reminder',
          style: TextStyle(
            color: SmritiTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"?',
          style: const TextStyle(
            color: SmritiTheme.textSecondary,
            fontSize: 17,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(80, 48),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: SmritiTheme.textSecondary, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(100, 48),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reminderService.deleteReminder(reminder.id);
        await _notificationService.cancelReminder(reminder.id);
        await _loadReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${reminder.title}".'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete reminder.')),
          );
        }
      }
    }
  }

  void _openReminderForm([ReminderModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReminderFormSheet(
        existing: existing,
        onSave: (reminder) {
          Navigator.of(ctx).pop();
          _handleCreateOrUpdate(reminder, isNew: existing == null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _reminders.length;
    final doneCount = _reminders.where((r) => r.acknowledgedAt != null).length;

    return Scaffold(
      backgroundColor: SmritiTheme.warmCream,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: SmritiTheme.primaryGreen),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 18,
                              color: SmritiTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadReminders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SmritiTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // App Bar / Top Header
                      SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reminders',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: SmritiTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your gentle daily routine',
                            style: TextStyle(
                              fontSize: 17,
                              color: SmritiTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Progress Badge & Add Button Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Progress Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: SmritiTheme.secondaryGreen.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: SmritiTheme.secondaryGreen.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 20,
                                      color: SmritiTheme.primaryGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$doneCount of $totalCount Done',
                                      key: const Key('progress_badge_text'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: SmritiTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Add Action
                              ElevatedButton.icon(
                                key: const Key('add_reminder_top_button'),
                                onPressed: () => _openReminderForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SmritiTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text(
                                  'Add',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content: Empty State or Reminder List
                  if (_reminders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final reminder = _reminders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _ReminderCard(
                                reminder: reminder,
                                onDone: () => _handleAcknowledge(reminder),
                                onToggle: () => _handleToggleEnable(reminder),
                                onEdit: () => _openReminderForm(reminder),
                                onDelete: () => _handleDelete(reminder),
                              ),
                            );
                          },
                          childCount: _reminders.length,
                        ),
                      ),
                    ),

                  // Bottom padding for scroll comfort
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: SmritiTheme.lightMint.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 48,
                color: SmritiTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nothing planned yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SmritiTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Add a reminder for medicines, hydration, or your daily routine.',
              style: TextStyle(
                fontSize: 16,
                color: SmritiTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                key: const Key('empty_add_reminder_button'),
                onPressed: () => _openReminderForm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmritiTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Add Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Reminder Card Component
// ============================================================================
class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onDone;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onDone,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _resolveIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('med') || t.contains('pill') || t.contains('tablet') || t.contains('rx')) {
      return Icons.medication_rounded;
    }
    if (t.contains('water') || t.contains('drink') || t.contains('hydrat')) {
      return Icons.water_drop_rounded;
    }
    if (t.contains('walk') || t.contains('exercise') || t.contains('step')) {
      return Icons.directions_walk_rounded;
    }
    if (t.contains('call') || t.contains('family') || t.contains('doctor')) {
      return Icons.phone_in_talk_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _resolveIconBg(String title) {
    final t = title.toLowerCase();
    if (t.contains('water') || t.contains('drink')) {
      return SmritiTheme.lightMint;
    }
    if (t.contains('med') || t.contains('pill')) {
      return SmritiTheme.secondaryGreen.withValues(alpha: 0.5);
    }
    return SmritiTheme.softYellow;
  }

  String _formatScheduledTime(DateTime dt) {
    final now = DateTime.now();
    final timeStr = DateFormat.jm().format(dt);

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today • $timeStr';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day) {
      return 'Tomorrow • $timeStr';
    }
    return '${DateFormat('EEE, d MMM').format(dt)} • $timeStr';
  }

  String _formatRecurrence(ReminderRecurrence recurrence) {
    switch (recurrence) {
      case ReminderRecurrence.none:
        return 'One-time';
      case ReminderRecurrence.daily:
        return 'Daily';
      case ReminderRecurrence.weekly:
        return 'Weekly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAcknowledged = reminder.acknowledgedAt != null;
    final isEnabled = reminder.isEnabled;

    return Container(
      decoration: BoxDecoration(
        color: SmritiTheme.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SmritiTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Icon + Status Tag + Overflow Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _resolveIconBg(reminder.title),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _resolveIcon(reminder.title),
                  size: 28,
                  color: SmritiTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Description Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? SmritiTheme.textPrimary : SmritiTheme.textSecondary,
                        decoration: isAcknowledged ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: SmritiTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Menu Options Button
              PopupMenuButton<String>(
                key: Key('menu_${reminder.id}'),
                icon: const Icon(Icons.more_vert_rounded, color: SmritiTheme.textSecondary, size: 26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'toggle') onToggle();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: SmritiTheme.textPrimary),
                        SizedBox(width: 12),
                        Text('Edit', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isEnabled ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          size: 20,
                          color: SmritiTheme.textPrimary,
                        ),
                        SizedBox(width: 12),
                        Text(isEnabled ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(fontSize: 16, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1EFE6), thickness: 1, height: 1),
          const SizedBox(height: 14),

          // Bottom Meta Row: Time, Recurrence, and Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time & Recurrence Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: SmritiTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _formatScheduledTime(reminder.scheduledAt),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: SmritiTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Status Badge: Done, Active, or Paused
                        if (isAcknowledged)
                          _buildBadge(
                            icon: Icons.check_circle_rounded,
                            label: 'Done',
                            bg: SmritiTheme.activeGreenBg,
                            fg: SmritiTheme.activeGreenText,
                          )
                        else if (isEnabled)
                          _buildBadge(
                            icon: Icons.notifications_active_rounded,
                            label: 'Active',
                            bg: SmritiTheme.activeGreenBg,
                            fg: SmritiTheme.activeGreenText,
                          )
                        else
                          _buildBadge(
                            icon: Icons.pause_circle_filled_rounded,
                            label: 'Paused',
                            bg: SmritiTheme.pausedBg,
                            fg: SmritiTheme.pausedText,
                          ),
                        const SizedBox(width: 8),

                        // Recurrence Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SmritiTheme.warmCream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SmritiTheme.cardBorder),
                          ),
                          child: Text(
                            _formatRecurrence(reminder.recurrence),
                            style: const TextStyle(
                              fontSize: 13,
                              color: SmritiTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Target (Done button)
              if (!isAcknowledged)
                ElevatedButton.icon(
                  key: Key('done_${reminder.id}'),
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmritiTheme.secondaryGreen,
                    foregroundColor: SmritiTheme.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    minimumSize: const Size(80, 48),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20, color: SmritiTheme.primaryGreen),
                  label: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SmritiTheme.primaryGreen,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: SmritiTheme.activeGreenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: SmritiTheme.activeGreenText),
                      SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: SmritiTheme.activeGreenText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Add / Edit Reminder Bottom Sheet Form
// ============================================================================
class _ReminderFormSheet extends StatefulWidget {
  final ReminderModel? existing;
  final ValueChanged<ReminderModel> onSave;

  const _ReminderFormSheet({
    this.existing,
    required this.onSave,
  });

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderRecurrence _selectedRecurrence;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleController = TextEditingController(text: ex?.title ?? '');
    _descController = TextEditingController(text: ex?.description ?? '');

    final initialScheduled = ex?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    _selectedDate = DateTime(initialScheduled.year, initialScheduled.month, initialScheduled.day);
    _selectedTime = TimeOfDay(hour: initialScheduled.hour, minute: initialScheduled.minute);
    _selectedRecurrence = ex?.recurrence ?? ReminderRecurrence.none;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SmritiTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: SmritiTheme.cardWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SmritiTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: SmritiTheme.cardWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final model = ReminderModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      scheduledAt: scheduledDateTime,
      recurrence: _selectedRecurrence,
      isEnabled: widget.existing?.isEnabled ?? true,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      acknowledgedAt: widget.existing?.acknowledgedAt,
      lastTriggeredAt: widget.existing?.lastTriggeredAt,
    );

    widget.onSave(model);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Container(
      decoration: const BoxDecoration(
        color: SmritiTheme.warmCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Form Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Reminder' : 'Add Reminder',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: SmritiTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 28, color: SmritiTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title Input
              const Text(
                'Reminder Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SmritiTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('reminder_title_field'),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 17, color: SmritiTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Morning Blood Pressure Medicine',
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
                  filled: true,
                  fillColor: SmritiTheme.cardWhite,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: SmritiTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: SmritiTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: SmritiTheme.primaryGreen, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a reminder title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Description Input
              const Text(
                'Instructions or notes (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SmritiTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('reminder_desc_field'),
                controller: _descController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16, color: SmritiTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Take 1 tablet after breakfast with warm water',
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
                  filled: true,
                  fillColor: SmritiTheme.cardWhite,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: SmritiTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: SmritiTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: SmritiTheme.primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date & Time Row
              Row(
                children: [
                  // Date Picker Card
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: SmritiTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          key: const Key('pick_date_button'),
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: SmritiTheme.cardWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: SmritiTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: SmritiTheme.primaryGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Time Picker Card
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: SmritiTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          key: const Key('pick_time_button'),
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: SmritiTheme.cardWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: SmritiTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: SmritiTheme.primaryGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    formattedTime,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recurrence / Repeat Selector
              const Text(
                'Repeat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SmritiTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: SmritiTheme.cardWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SmritiTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReminderRecurrence>(
                    key: const Key('recurrence_dropdown'),
                    value: _selectedRecurrence,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: SmritiTheme.primaryGreen),
                    borderRadius: BorderRadius.circular(18),
                    items: const [
                      DropdownMenuItem(
                        value: ReminderRecurrence.none,
                        child: Text('Does not repeat (One-time)', style: TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: ReminderRecurrence.daily,
                        child: Text('Every day (Daily)', style: TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: ReminderRecurrence.weekly,
                        child: Text('Every week (Weekly)', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRecurrence = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SmritiTheme.textSecondary,
                        side: const BorderSide(color: SmritiTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(0, 52),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('save_reminder_button'),
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SmritiTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: const Size(0, 52),
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Save Reminder',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
