import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Service to communicate with the Voice Translation backend API.
class TranslationApiService {
  // Permanently bypass localtunnel! The laptop's local IP address allows direct LAN connection:
  static const String _baseUrl = 'http://192.168.1.3:8000';

  /// Send an audio file to the /transcribe endpoint.
  /// Returns a map with { "original", "translated", "latency_ms" }.
  static Future<Map<String, dynamic>> transcribeAudio(String filePath) async {
    final uri = Uri.parse('$_baseUrl/transcribe');
    final request = http.MultipartRequest('POST', uri);
    
    // Header required to bypass the the localtunnel warning screen
    request.headers['Bypass-Tunnel-Reminder'] = 'true';

    if (kIsWeb) {
      // On web we get a blob URL. We need to fetch it to send bytes.
      final response = await http.get(Uri.parse(filePath));
      request.files.add(
        http.MultipartFile.fromBytes('file', response.bodyBytes, filename: 'audio.webm'),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
    }

    // Set a generous timeout for large files
    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 120),
        );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 413) {
      throw Exception('File too large. Maximum 25 MB allowed.');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limited. Please wait a moment and try again.');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Server error (${response.statusCode})');
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
    } catch (_) {
      return false;
    }
  }
}
