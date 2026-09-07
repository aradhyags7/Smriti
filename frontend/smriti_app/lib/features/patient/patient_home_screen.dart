import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
class PatientHomeScreen extends StatefulWidget {
const PatientHomeScreen({super.key});
@override
State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}
class _PatientHomeScreenState extends State<PatientHomeScreen> {
int _selectedIndex = 0;
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
}
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
iconData: Icons.home,
label: 'Home',
),
_buildNavItem(
index: 1,
iconData: Icons.support_agent,
label: 'ASHA Worker',
),
_buildNavItem(
index: 2,
iconData: Icons.alarm,
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
return SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 24.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 16),
Text(
'Good Morning, Aita 🌸',
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
// Card 1
_buildActivityCard(
context: context,
iconColor: const Color(0xFFA6EBCF),
iconData: Icons.sports_esports,
badgeColor: const Color(0xFFB4EBA3),
badgeText: '1 of 3 Done',
badgeIcon: Icons.check_circle,
title: '1. Daily Games',
subtitle: 'Today\'s gentle memory exercises • Tap to open',
),
const SizedBox(height: 16),
// Card 2
_buildActivityCard(
context: context,
iconColor: const Color(0xFFB4EBA3),
iconData: Icons.extension,
badgeColor: const Color(0xFFF3EEDF),
badgeText: '6 Available',
title: '2. More Games',
subtitle: 'Folklore, melodies & visual puzzles • Tap to browse',
),
const SizedBox(height: 32),
],
),
),
);
} else if (_selectedIndex == 1) {
return const Center(
child: Text('ASHA Worker Contact / Help Page (Coming Soon)', style: TextStyle(color: AppColors.primary)),
);
} else {
return const Center(
child: Text('Reminders Page (Coming Soon)', style: TextStyle(color: AppColors.primary)),
);
}
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
}) {
return Container(
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
