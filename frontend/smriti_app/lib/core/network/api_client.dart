import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();

  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await _httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> get(
    String url, {
    bool requireAuth = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await _httpClient.get(
      Uri.parse(url),
      headers: headers,
    );
  }

  Future<http.Response> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await _httpClient.patch(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(
    String url, {
    bool requireAuth = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await _httpClient.delete(
      Uri.parse(url),
      headers: headers,
    );
  }
}
