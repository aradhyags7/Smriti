import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final ApiClient _apiClient = ApiClient();
  bool _isInitialized = false;

  // Configured via build-time define: flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
  static const String _envClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  // Can be configured or updated dynamically if needed
  static String configuredServerClientId = _envClientId.isNotEmpty ? _envClientId : '774835268437-jcs3faluugumdcjq44gjifota2rhupunf.apps.googleusercontent.com';

  /// Initialize GoogleSignIn exactly once before authentication calls
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: configuredServerClientId.isNotEmpty ? configuredServerClientId : null,
      );
      _isInitialized = true;
    } catch (_) {
      // In tests or unsupported environments, record initialized state
      _isInitialized = true;
    }
  }

  /// Initiates Google OAuth authentication flow and verifies ID token with SMRITI backend
  Future<Map<String, dynamic>> continueWithGoogle({String role = 'patient'}) async {
    try {
      await ensureInitialized();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        return {
          'success': false,
          'error': 'Google authentication did not provide an ID token. Ensure your Google Cloud Web Client ID is configured.',
        };
      }

      final response = await _apiClient.post(
        ApiEndpoints.googleLogin,
        body: {
          'id_token': idToken,
          'role': role.toLowerCase().trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token'] ?? '');
        await prefs.setString('user_id', data['user_id'] ?? '');
        await prefs.setString('role', data['role'] ?? role);
        if (data['email'] != null) {
          await prefs.setString('email', data['email']);
        }
        if (data['full_name'] != null) {
          await prefs.setString('full_name', data['full_name']);
        }
        return {'success': true, 'data': data};
      } else if (response.statusCode == 409) {
        // Account collision with existing LOCAL password account
        return {
          'success': false,
          'error': data['detail'] ?? 'An account with this email already exists with password authentication. Please sign in with your password.',
          'collision': true,
        };
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Google authentication rejected with status ${response.statusCode}.',
        };
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        return {'cancelled': true};
      }
      return {
        'success': false,
        'error': 'Google Sign-In: ${e.description ?? e.code.name}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Authentication failed: ${e.toString()}',
      };
    }
  }

  /// Sign out cleanly from Google authentication
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
