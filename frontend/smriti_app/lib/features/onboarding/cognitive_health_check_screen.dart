import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
class CognitiveHealthCheckScreen extends StatelessWidget {
const CognitiveHealthCheckScreen({super.key});
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.canvas,
body: SafeArea(
child: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Header
Column(
children: [
Container(
width: 100,
height: 100,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.white,
border: Border.all(color: const Color(0xFFF3EEDF), width: 3),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: ClipOval(
child: Image.asset(
'assets/images/logo/smriti-logo.jpg',
fit: BoxFit.cover,
errorBuilder: (context, error, stackTrace) {
return const Icon(Icons.image, size: 40, color: Colors.grey);
}
),
),
),
const SizedBox(height: 24),
Text(
'Cognitive Health Check',
style: Theme.of(context).textTheme.displaySmall?.copyWith(
color: const Color(0xFF1F4D36),
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 8),
Text(
'Choose an activity to begin',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: const Color(0xFF5A7264),
),
),
],
),
const SizedBox(height: 40),
// Activities List
_buildActivityCard(
context: context,
iconColor: const Color(0xFFA6EBCF),
iconData: Icons.settings,
title: '1. Memory Match',
subtitle: 'Find matching nature pictures ...',
),
const SizedBox(height: 16),
_buildActivityCard(
context: context,
iconColor: const Color(0xFFB4EBA3),
iconData: Icons.grid_view,
title: '2. Pattern Puzzle',
subtitle: 'Connect soft shapes & pattern...',
),
const SizedBox(height: 16),
_buildActivityCard(
context: context,
iconColor: const Color(0xFFFFDBA6),
iconData: Icons.graphic_eq,
title: '3. Sound & Melody',
subtitle: 'Listen to gentle bird tunes + Ta...',
),
const SizedBox(height: 32),
// Start All Button
ElevatedButton(
onPressed: () {
// Placeholder action
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF23654D),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
padding: const EdgeInsets.symmetric(vertical: 18),
elevation: 0,
),
child: const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.play_circle_filled, size: 24),
SizedBox(width: 8),
Text('Start All Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
],
),
),
const SizedBox(height: 24),
// Footer
Row(
mainAxisAlignment: MainAxisAlignment.center,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Padding(
padding: EdgeInsets.only(top: 2.0),
child: Icon(Icons.support_agent, size: 18, color: Color(0xFF5A7264)),
),
const SizedBox(width: 8),
Expanded(
child: Text(
'Need help? A family caregiver or ASHA worker\ncan guide you.',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: const Color(0xFF5A7264),
),
textAlign: TextAlign.center,
),
),
],
),
const SizedBox(height: 32),
// Skip Button
Center(
child: OutlinedButton(
onPressed: () {
Navigator.pushReplacementNamed(context, '/home');
},
style: OutlinedButton.styleFrom(
foregroundColor: const Color(0xFF1F4D36),
side: const BorderSide(color: Color(0xFF1F4D36)),
padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
child: const Text(
'Go to Home Screen',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
),
),
const SizedBox(height: 24),
],
),
),
),
),
);
}
Widget _buildActivityCard({
required BuildContext context,
required Color iconColor,
required IconData iconData,
required String title,
required String subtitle,
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
offset: const Offset(0, 4),
),
],
),
child: Row(
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
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: Theme.of(context).textTheme.titleMedium?.copyWith(
color: const Color(0xFF1F4D36),
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 4),
Text(
subtitle,
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: const Color(0xFF7A8D83),
fontSize: 12,
),
),
],
),
),
const SizedBox(width: 8),
Container(
width: 32,
height: 32,
decoration: const BoxDecoration(
color: Color(0xFFF1EFE3),
shape: BoxShape.circle,
),
child: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF5A7264)),
),
],
),
);
}
}
