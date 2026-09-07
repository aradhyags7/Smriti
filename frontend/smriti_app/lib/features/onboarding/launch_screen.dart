import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
class LaunchScreen extends StatefulWidget {
const LaunchScreen({super.key});
@override
State<LaunchScreen> createState() => _LaunchScreenState();
}
class _LaunchScreenState extends State<LaunchScreen> {
String _selectedDialect = 'हिन्दी';
final List<String> _dialects = [
'English', 'हिन्दी', 'অসমীয়া', 'বাংলা', 'মৈতৈলোন্', 'Mizo ṭawng', 'নাগামিজ'
];
@override
Widget build(BuildContext context) {
return Scaffold(
body: Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Color(0xFFC1E4CE), // soft mint green
Color(0xFFEDF3E8), // pale base
Color(0xFFF1F1E6),
],
),
),
child: SafeArea(
child: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
child: Column(
children: [
// Top Pill
Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
color: const Color(0xFFA1CCBA),
borderRadius: BorderRadius.circular(20),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(Icons.spa, size: 16, color: AppColors.primary),
const SizedBox(width: 8),
Text(
'COGNITIVE WELLNESS',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: AppColors.primary,
fontWeight: FontWeight.w800,
),
),
],
),
),
const SizedBox(height: 12),
// Greetings
Text(
'নমস্কাৰ • Khurumjari • Ronggila • Namaste',
style: Theme.of(context).textTheme.labelMedium?.copyWith(
color: AppColors.primary,
fontWeight: FontWeight.w600,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 32),
// Logo
Container(
width: 140,
height: 140,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.white,
border: Border.all(color: const Color(0xFFDDEEE4), width: 4),
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
return const Icon(Icons.image, size: 48, color: Colors.grey);
}
),
),
),
const SizedBox(height: 24),
// Title
Text(
'SMRITI',
style: Theme.of(context).textTheme.displaySmall?.copyWith(
color: AppColors.primary,
fontWeight: FontWeight.w800,
letterSpacing: 1.2,
),
),
const SizedBox(height: 4),
Text(
'Remember With Us',
style: Theme.of(context).textTheme.headlineMedium?.copyWith(
color: AppColors.primary,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 12),
Text(
'Remember • Reconnect • Thrive',
style: Theme.of(context).textTheme.labelMedium?.copyWith(
color: const Color(0xFF4A6B5D),
),
),
const SizedBox(height: 32),
// Main Card
Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.05),
blurRadius: 15,
offset: const Offset(0, 5),
),
],
),
child: Column(
children: [
// Buttons
ElevatedButton(
onPressed: () {
Navigator.pushReplacementNamed(context, '/login', arguments: {'role': 'patient'});
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF387E61),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
),
child: const Row(
children: [
Icon(Icons.nature_people, size: 22),
SizedBox(width: 12),
Text('Begin Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
Spacer(),
Icon(Icons.arrow_forward, size: 22),
],
),
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: () {
Navigator.pushReplacementNamed(context, '/login', arguments: {'role': 'caregiver'});
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFF1EFE3),
foregroundColor: const Color(0xFF1F4D36),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
),
child: const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.family_restroom, size: 20),
SizedBox(width: 12),
Text('Family Caregiver Portal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
],
),
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: () {
Navigator.pushReplacementNamed(context, '/login', arguments: {'role': 'asha'});
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFF1EFE3),
foregroundColor: const Color(0xFF1F4D36),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
),
child: const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.health_and_safety, size: 20),
SizedBox(width: 12),
Text('ASHA / Health Worker Portal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
],
),
),
const SizedBox(height: 28),
// Dialect section
Text(
'CHOOSE DIALECT',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: const Color(0xFF5A7264),
fontWeight: FontWeight.w800,
letterSpacing: 1.0,
),
),
const SizedBox(height: 16),
// Grid of dialects
GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
childAspectRatio: 3.5,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
),
itemCount: _dialects.length,
itemBuilder: (context, index) {
final dialect = _dialects[index];
final isSelected = _selectedDialect == dialect;
return GestureDetector(
onTap: () {
setState(() {
_selectedDialect = dialect;
});
},
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16),
decoration: BoxDecoration(
color: isSelected ? const Color(0xFF387E61) : const Color(0xFFF1EFE3),
borderRadius: BorderRadius.circular(8),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
dialect,
style: TextStyle(
color: isSelected ? Colors.white : Colors.black87,
fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
fontSize: 14,
),
),
if (isSelected)
const Icon(Icons.check_circle, color: Colors.white, size: 16),
],
),
),
);
},
),
],
),
),
const SizedBox(height: 32),
// Footer
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.shield_rounded, size: 14, color: AppColors.primary),
const SizedBox(width: 6),
Text(
'A gentle space for cherished memories and daily peace',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: const Color(0xFF4A6B5D),
fontWeight: FontWeight.w600,
),
),
],
),
const SizedBox(height: 8),
Text(
'Assamese • Bengali • English • Hindi • Manipuri • Mizo • Nagamese',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: const Color(0xFF7A8D83),
fontSize: 10,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 24),
],
),
),
),
),
),
);
}
}
