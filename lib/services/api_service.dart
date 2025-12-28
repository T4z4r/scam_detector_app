import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scam_result.dart';

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api'; // UPDATE TO YOUR LARAVEL URL
  // static const String baseUrl = 'https://your-metron-api.com/api';

  static Future<ScamResult> checkScam(String text, String sender) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scam/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'sender': sender,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ScamResult.fromJson(data);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
