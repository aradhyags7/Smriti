import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();
  bool _useLocalFallback = false;

  String _resolveUrl(String url) {
    if (_useLocalFallback) {
      final live = ApiEndpoints.liveBackendUrl;
      final local = ApiEndpoints.localFallbackUrl;
      if (url.startsWith(live)) {
        return url.replaceFirst(live, local);
      }
    }
    return url;
  }

  Future<http.Response> _executeWithFallback(
    String url,
    Future<http.Response> Function(String resolvedUrl) requestFn,
  ) async {
    final targetUrl = _resolveUrl(url);
    try {
      final response = await requestFn(targetUrl);
      // If live backend returned 404 or 405 (e.g. new routes before Render deployment)
      // seamlessly retry against local backend in debug mode
      if (!kReleaseMode && !_useLocalFallback && (response.statusCode == 404 || response.statusCode == 405)) {
        _useLocalFallback = true;
        final fallbackUrl = _resolveUrl(url);
        return await requestFn(fallbackUrl);
      }
      return response;
    } on SocketException catch (_) {
      // If live Render host lookup failed (e.g. Android Emulator DNS bug),
      // seamlessly retry against local backend!
      if (!_useLocalFallback) {
        _useLocalFallback = true;
        final fallbackUrl = _resolveUrl(url);
        return await requestFn(fallbackUrl);
      }
      rethrow;
    } on http.ClientException catch (_) {
      if (!_useLocalFallback) {
        _useLocalFallback = true;
        final fallbackUrl = _resolveUrl(url);
        return await requestFn(fallbackUrl);
      }
      rethrow;
    }
  }

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
    return await _executeWithFallback(url, (resolvedUrl) {
      return _httpClient.post(
        Uri.parse(resolvedUrl),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<http.Response> get(
    String url, {
    bool requireAuth = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await _executeWithFallback(url, (resolvedUrl) {
      return _httpClient.get(
        Uri.parse(resolvedUrl),
        headers: headers,
      );
    });
  }

  Future<http.Response> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await _executeWithFallback(url, (resolvedUrl) {
      return _httpClient.patch(
        Uri.parse(resolvedUrl),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<http.Response> delete(
    String url, {
    bool requireAuth = false,
  }) async {
    final headers = await _getHeaders(requireAuth: requireAuth);
    return await _executeWithFallback(url, (resolvedUrl) {
      return _httpClient.delete(
        Uri.parse(resolvedUrl),
        headers: headers,
      );
    });
  }
}
