import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

/// Service to communicate with the Voice Translation backend API.
///
/// IMPORTANT: If you get "SocketException / Connection refused", run this
/// command on your laptop to find the current IP:
///   PowerShell:  ipconfig | Select-String "IPv4"
/// Then update [_baseUrl] below with the new IP address.
class TranslationApiService {
  // Your laptop's current LAN IP (run `ipconfig` to verify if connection fails):
  static const String _baseUrl = 'http://192.168.1.2:8000';

  /// Send an audio file to the /transcribe endpoint.
  /// Returns a map with { "original", "translated", "latency_ms" }.
  static Future<Map<String, dynamic>> transcribeAudio(String filePath) async {
    final uri = Uri.parse('$_baseUrl/transcribe');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Bypass-Tunnel-Reminder'] = 'true';

    if (kIsWeb) {
      final response = await http.get(Uri.parse(filePath));
      request.files.add(
        http.MultipartFile.fromBytes('file', response.bodyBytes,
            filename: 'audio.webm'),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
    }

    // ── Send with connection-error handling ──
    final http.Response response;
    try {
      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException catch (e) {
      debugPrint('⚠️ Backend unreachable at $_baseUrl — $e');
      throw Exception(
        'Cannot reach backend at $_baseUrl.\n'
        'Make sure:\n'
        '  1. The backend is running (python run.py)\n'
        '  2. Phone & laptop are on the same Wi-Fi\n'
        '  3. The IP address is correct (run ipconfig)',
      );
    } on http.ClientException catch (e) {
      debugPrint('⚠️ HTTP client error — $e');
      throw Exception(
        'Connection failed to $_baseUrl.\n'
        'Check that the backend server is running\n'
        'and your phone is on the same Wi-Fi network.',
      );
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 413) {
      throw Exception('File too large. Maximum 25 MB allowed.');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limited. Please wait a moment and try again.');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
          body['detail'] ?? 'Server error (${response.statusCode})');
    }
  }

  /// Check if the backend is reachable.
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Bypass-Tunnel-Reminder': 'true'},
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Health check failed for $_baseUrl — $e');
      return false;
    }
  }
}

