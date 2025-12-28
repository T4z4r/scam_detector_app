import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/scam_result.dart';
import 'local_scam_detection_service.dart';

class ApiService {
  // Tanzania Scam Detector API Configuration
  // Update baseUrl to match your environment
  // Development: http://localhost:8000/api/v1
  // Production: https://api.your-domain.com/v1
  static const String baseUrl = 'https://detector.flex.co.tz/api';

  // Enable local detection as fallback
  static const bool enableLocalDetection = true;
  static const bool preferLocalDetection = true; // Use local first, then API

  static const int timeoutDuration = 30; // seconds
  static const int maxTextLength = 1000;
  static const int maxSenderLength = 50;

  static Future<ScamResult> checkScam(String text, String sender) async {
    // Validate input according to API specification
    if (text.trim().isEmpty) {
      throw Exception('SMS text cannot be empty');
    }

    if (text.length > maxTextLength) {
      throw Exception('SMS text exceeds $maxTextLength character limit');
    }

    if (sender.length > maxSenderLength) {
      throw Exception('Sender name exceeds $maxSenderLength character limit');
    }

    // Use local detection if enabled and preferred
    if (enableLocalDetection && preferLocalDetection) {
      try {
        final localResult = LocalScamDetectionService.detectScam(text, sender);
        // Return local result if it has high confidence
        if (localResult.confidence >= 70.0) {
          return localResult;
        }
      } catch (e) {
        // Continue to API call if local detection fails
      }
    }

    // Check internet connection
    final isConnected = await InternetConnectionChecker().hasConnection;
    if (!isConnected) {
      // Fallback to local detection if no internet
      if (enableLocalDetection) {
        return LocalScamDetectionService.detectScam(text, sender);
      }
      throw Exception('No internet connection. Please check your network.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/scam/check'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'text': text.trim(),
              'sender': sender.trim(),
            }),
          )
          .timeout(const Duration(seconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Validate API response
        if (data == null || data['result'] == null) {
          throw Exception('Invalid API response format');
        }

        return ScamResult.fromJson(data);
      } else if (response.statusCode == 400) {
        throw Exception('Bad Request: Invalid JSON format');
      } else if (response.statusCode == 422) {
        throw Exception('Validation Error: ${response.body}');
      } else if (response.statusCode == 404) {
        throw Exception(
            'API endpoint not found. Please check your configuration.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // If API fails and local detection is enabled, use local fallback
      if (enableLocalDetection) {
        try {
          return LocalScamDetectionService.detectScam(text, sender);
        } catch (localError) {
          throw Exception(
              'Both API and local detection failed. Please check your connection.');
        }
      }

      if (e.toString().contains('TimeoutException')) {
        throw Exception(
            'Request timed out. Please check your connection and try again.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      } else {
        rethrow;
      }
    }

    // This point should never be reached due to the above logic
  }

  // Health check method to test API connectivity
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get rate limit status for monitoring
  static Map<String, String> getRateLimitHeaders() {
    return {
      'X-RateLimit-Remaining': '100', // per minute
      'X-RateLimit-Reset':
          DateTime.now().add(const Duration(minutes: 1)).toIso8601String(),
    };
  }

  // Force local detection (bypass API)
  static ScamResult checkScamLocalOnly(String text, String sender) {
    // Validate input first
    if (text.trim().isEmpty) {
      throw Exception('SMS text cannot be empty');
    }

    if (text.length > maxTextLength) {
      throw Exception('SMS text exceeds $maxTextLength character limit');
    }

    if (sender.length > maxSenderLength) {
      throw Exception('Sender name exceeds $maxSenderLength character limit');
    }

    return LocalScamDetectionService.detectScam(text, sender);
  }

  // Get detection statistics for a message
  static Map<String, int> getDetectionStatistics(String text) {
    return LocalScamDetectionService.getPatternStatistics(text);
  }
}
