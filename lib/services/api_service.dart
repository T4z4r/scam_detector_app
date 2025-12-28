import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/scam_result.dart';

class ApiService {
  // Replace with your actual API URL
  static const String baseUrl = 'https://your-api-domain.com/api';
  
  static const int timeoutDuration = 30; // seconds

  static Future<ScamResult> checkScam(String text, String sender) async {
    // Validate input
    if (text.trim().isEmpty) {
      throw Exception('SMS text cannot be empty');
    }

    // Check internet connection
    final isConnected = await InternetConnectionChecker().hasConnection;
    if (!isConnected) {
      throw Exception('No internet connection. Please check your network.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scam/check'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text': text.trim(),
          'sender': sender.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validate API response
        if (data == null || data['result'] == null) {
          throw Exception('Invalid API response format');
        }
        
        return ScamResult.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check your configuration.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please check your connection and try again.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        rethrow;
      }
    }
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
}
