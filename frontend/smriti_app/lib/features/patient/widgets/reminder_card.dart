import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../reminders/reminder_model.dart';

class ReminderCard extends StatelessWidget {
  final ReminderItem reminder;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final bool isElderFriendly;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onToggle,
    this.onDelete,
    this.isElderFriendly = false,
  });

  IconData _getIcon() {
    switch (reminder.reminderType.toUpperCase()) {
      case 'MEDICINE':
      case 'MEDICATION':
        return Icons.medication;
      case 'HYDRATION':
        return Icons.water_drop;
      case 'CHECKIN':
        return Icons.favorite;
      case 'GAME_SESSION':
        return Icons.sports_esports;
      default:
        return Icons.alarm;
    }
  }

  Color _getIconBgColor() {
    switch (reminder.reminderType.toUpperCase()) {
      case 'MEDICINE':
      case 'MEDICATION':
        return const Color(0xFFA6EBCF);
      case 'HYDRATION':
        return const Color(0xFFA6D4EB);
      case 'CHECKIN':
        return const Color(0xFFFFDBA6);
      case 'GAME_SESSION':
        return const Color(0xFFE2A6EB);
      default:
        return const Color(0xFFF1EFE3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(isElderFriendly ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: reminder.isAcknowledged
            ? Border.all(color: const Color(0xFF23654D).withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isElderFriendly ? 52 : 44,
            height: isElderFriendly ? 52 : 44,
            decoration: BoxDecoration(
              color: _getIconBgColor(),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(),
              color: const Color(0xFF1F4D36),
              size: isElderFriendly ? 28 : 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: isElderFriendly ? 18 : 15,
                    fontWeight: FontWeight.bold,
                    color: reminder.isAcknowledged ? Colors.grey.shade600 : AppColors.primary,
                    decoration: reminder.isAcknowledged ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isElderFriendly ? 16 : 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reminder.scheduledTime,
                      style: TextStyle(
                        fontSize: isElderFriendly ? 15 : 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF23654D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFE3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reminder.frequency,
                        style: TextStyle(
                          fontSize: isElderFriendly ? 12 : 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onToggle != null)
            IconButton(
              icon: Icon(
                reminder.isAcknowledged ? Icons.check_circle : Icons.radio_button_unchecked,
                color: reminder.isAcknowledged ? const Color(0xFF23654D) : Colors.grey.shade400,
                size: isElderFriendly ? 32 : 26,
              ),
              onPressed: onToggle,
            ),
          if (onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade300,
                size: 20,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
