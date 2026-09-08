import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/google_auth_service.dart';

class GoogleDevFallbackSheet extends StatefulWidget {
  final String role;
  final Function(Map<String, dynamic> data) onSuccess;

  const GoogleDevFallbackSheet({
    super.key,
    required this.role,
    required this.onSuccess,
  });

  static void show(
    BuildContext context, {
    required String role,
    required Function(Map<String, dynamic> data) onSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoogleDevFallbackSheet(
        role: role,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<GoogleDevFallbackSheet> createState() => _GoogleDevFallbackSheetState();
}

class _GoogleDevFallbackSheetState extends State<GoogleDevFallbackSheet> {
  late TextEditingController _emailController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSetupDetails = false;

  final String _packageName = 'com.example.smriti_app';
  final String _sha1 = 'EA:C9:53:FB:9D:CD:1B:91:A1:32:2E:FA:5D:F0:0E:4D:BF:44:B3:A2';

  @override
  void initState() {
    super.initState();
    final defaultEmail = widget.role == 'caregiver'
        ? 'caregiver.google@smriti.care'
        : (widget.role == 'asha'
            ? 'asha.google@smriti.care'
            : 'patient.google@smriti.care');
    _emailController = TextEditingController(text: defaultEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitDevGoogleLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid Google email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await GoogleAuthService().continueWithGoogle(
      role: widget.role,
      devEmail: email,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onSuccess(result['data'] ?? {});
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Sign in failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EFE3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF23654D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Sign-In',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF0F5A4D),
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Development & Testing Mode',
                        style: TextStyle(
                          color: Color(0xFF5A7264),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFE3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5DEC9)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF23654D), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This device\'s SHA-1 is not yet registered in your Google Cloud Console for the system popup. You can sign in immediately below:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F4D36),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Email input
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Google Account Email',
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF23654D)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF23654D), width: 2),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),

            // Sign In Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23654D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submitDevGoogleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Continue as Google ${widget.role.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Setup credentials accordion
            GestureDetector(
              onTap: () => setState(() => _showSetupDetails = !_showSetupDetails),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Google Cloud Console Setup (SHA-1)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F4D36),
                      ),
                    ),
                    Icon(
                      _showSetupDetails
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF23654D),
                    ),
                  ],
                ),
              ),
            ),
            if (_showSetupDetails) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Package Name:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _packageName,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _packageName));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Package name copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'SHA-1 Fingerprint:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _sha1,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _sha1));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SHA-1 copied!')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add this Android Client ID to Google Cloud Console (APIs & Services > Credentials) to enable the native Google account popup.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
