import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    try {
      final cleanName = fullName.trim();
      final body = <String, dynamic>{
        'full_name': cleanName,
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
        'role': role.toLowerCase().trim(),
        'preferred_language': preferredLanguage ?? 'en',
      };
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        String formattedPhone = phoneNumber.trim();
        if (!formattedPhone.startsWith('+')) {
          formattedPhone = formattedPhone.length == 10 ? '+91$formattedPhone' : '+$formattedPhone';
        }
        body['phone_number'] = formattedPhone;
      }

      final response = await _apiClient.post(
        ApiEndpoints.signup,
        body: body,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('full_name', cleanName);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = data['detail'] ?? 'Registration failed with status ${response.statusCode}';
        return {'success': false, 'error': errorMsg.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {
          'email': cleanEmail,
          'password': cleanPassword,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token'] ?? '');
        await prefs.setString('user_id', data['user_id'] ?? '');
        await prefs.setString('role', data['role'] ?? '');
        await prefs.setString('email', cleanEmail);
        if (data['full_name'] != null && (data['full_name'] as String).isNotEmpty) {
          await prefs.setString('full_name', data['full_name']);
        }
        return {'success': true, 'data': data};
      } else {
        final errorMsg = data['detail'] ?? 'Login failed. Please check your credentials.';
        return {'success': false, 'error': errorMsg.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me, requireAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['full_name'];
        if (name != null && (name as String).isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('full_name', name);
        }
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('full_name');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('role');
    await prefs.remove('email');
    await prefs.remove('phone_number');
    await prefs.remove('full_name');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token')?.isNotEmpty == true;
  }

  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }
}
