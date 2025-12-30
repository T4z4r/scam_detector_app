import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/scam_result.dart';
import '../models/scam_result_db.dart';
import 'local_scam_detection_service.dart';
import 'database_helper.dart';

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

  static Future<ScamResult> checkScam(String text, String sender, {bool forceApiCall = false}) async {
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

    // For explicit scan requests, always try API first unless offline
    if (forceApiCall) {
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (isConnected) {
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

            // Handle new API response format
            final apiResponse = ApiResponse<ScamResult>.fromJson(data);
            
            if (apiResponse.isSuccess && apiResponse.data != null) {
              final result = apiResponse.data!;
              
              // Store result in database
              try {
                final dbResult = ScamResultDB.fromScamResult(
                  result,
                  text,
                  sender,
                  detectionMethod: 'api',
                );
                await DatabaseHelper().insertScamResult(dbResult);
              } catch (e) {
                print('Failed to store result in database: $e');
              }
              
              return result;
            } else {
              throw Exception('API returned error: ${apiResponse.message}');
            }
          } else if (response.statusCode == 422) {
            // Validation error - parse error details
            final data = jsonDecode(response.body);
            final apiResponse = ApiResponse<ScamResult>.fromJson(data);
            throw Exception('Validation error: ${apiResponse.message}');
          } else {
            throw Exception('HTTP ${response.statusCode}: API request failed');
          }
        } catch (e) {
          // If API fails, fall back to local detection but indicate the failure
          print('API call failed, using local detection fallback: $e');
          final fallbackResult = LocalScamDetectionService.detectScam(text, sender);
          
          // Store fallback result in database
          try {
            final dbResult = ScamResultDB.fromScamResult(
              fallbackResult,
              text,
              sender,
              detectionMethod: 'local_fallback',
            );
            await DatabaseHelper().insertScamResult(dbResult);
          } catch (dbError) {
            print('Failed to store fallback result in database: $dbError');
          }
          
          return fallbackResult;
        }
      } else {
        // No internet connection, use local detection
        final offlineResult = LocalScamDetectionService.detectScam(text, sender);
        
        // Store offline result in database
        try {
          final dbResult = ScamResultDB.fromScamResult(
            offlineResult,
            text,
            sender,
            detectionMethod: 'local_offline',
          );
          await DatabaseHelper().insertScamResult(dbResult);
        } catch (e) {
          print('Failed to store offline result in database: $e');
        }
        
        return offlineResult;
      }
    }

    // Default behavior (for automatic SMS monitoring): hybrid approach
    ScamResult finalResult = LocalScamDetectionService.detectScam(text, sender); // Default fallback
    String detectionMethod = 'unknown';

    // Use local detection if enabled and preferred
    if (enableLocalDetection && preferLocalDetection) {
      try {
        final localResult = LocalScamDetectionService.detectScam(text, sender);
        // Return local result if it has high confidence
        if (localResult.confidence >= 70.0) {
          finalResult = localResult;
          detectionMethod = 'local';
        } else {
          // Continue to API call for verification
          detectionMethod = 'hybrid';
        }
      } catch (e) {
        // Continue to API call if local detection fails
      }
    }

    // If we don't have a high-confidence local result, try API
    if (detectionMethod == 'unknown' || detectionMethod == 'hybrid') {
      // Check internet connection
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (isConnected) {
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

            // Handle new API response format
            final apiResponse = ApiResponse<ScamResult>.fromJson(data);
            
            if (apiResponse.isSuccess && apiResponse.data != null) {
              finalResult = apiResponse.data!;
              detectionMethod = 'api';
            } else {
              // API returned error, use local detection as fallback
              finalResult = LocalScamDetectionService.detectScam(text, sender);
              detectionMethod = 'local_fallback';
            }
          } else if (response.statusCode == 422) {
            // Validation error - parse error details
            final data = jsonDecode(response.body);
            final apiResponse = ApiResponse<ScamResult>.fromJson(data);
            throw Exception('Validation error: ${apiResponse.message}');
          } else {
            // API failed, use local detection as fallback
            finalResult = LocalScamDetectionService.detectScam(text, sender);
            detectionMethod = 'local_fallback';
          }
        } catch (e) {
          // API failed, use local detection as fallback
          finalResult = LocalScamDetectionService.detectScam(text, sender);
          detectionMethod = 'local_fallback';
        }
      } else {
        // No internet, use local detection
        finalResult = LocalScamDetectionService.detectScam(text, sender);
        detectionMethod = 'local_offline';
      }
    }

    // Store result in database
    try {
      final dbResult = ScamResultDB.fromScamResult(
        finalResult,
        text,
        sender,
        detectionMethod: detectionMethod,
      );
      await DatabaseHelper().insertScamResult(dbResult);
    } catch (e) {
      // Log database error but don't fail the detection
      print('Failed to store result in database: $e');
    }

    return finalResult;
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

  // Training Management Methods

  /// Get current training status
  static Future<TrainingStatus> getTrainingStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/training/status'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(data);
        
        if (apiResponse.isSuccess && apiResponse.data != null) {
          return TrainingStatus.fromJson(apiResponse.data!);
        } else {
          throw Exception('Failed to get training status: ${apiResponse.message}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get training status');
      }
    } catch (e) {
      throw Exception('Failed to get training status: $e');
    }
  }

  /// Get training data statistics
  static Future<TrainingData> getTrainingData() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/training/data'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(data);
        
        if (apiResponse.isSuccess && apiResponse.data != null) {
          return TrainingData.fromJson(apiResponse.data!);
        } else {
          throw Exception('Failed to get training data: ${apiResponse.message}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Training data not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get training data');
      }
    } catch (e) {
      throw Exception('Failed to get training data: $e');
    }
  }

  /// Get model performance metrics
  static Future<ModelMetrics> getModelMetrics() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/training/metrics'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(data);
        
        if (apiResponse.isSuccess && apiResponse.data != null) {
          return ModelMetrics.fromJson(apiResponse.data!);
        } else {
          throw Exception('Failed to get model metrics: ${apiResponse.message}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get model metrics');
      }
    } catch (e) {
      throw Exception('Failed to get model metrics: $e');
    }
  }

  /// Delete training data
  static Future<void> deleteTrainingData() async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/training/data'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(data);
        
        if (!apiResponse.isSuccess) {
          throw Exception('Failed to delete training data: ${apiResponse.message}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Training data not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to delete training data');
      }
    } catch (e) {
      throw Exception('Failed to delete training data: $e');
    }
  }

  /// Start model training
  static Future<void> startTraining() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/training/train'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'action': 'train'}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(data);
        
        if (!apiResponse.isSuccess) {
          throw Exception('Failed to start training: ${apiResponse.message}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('No training data available. Please upload training data first.');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to start training');
      }
    } catch (e) {
      throw Exception('Failed to start training: $e');
    }
  }

  /// Upload training data file
  static Future<void> uploadTrainingData(List<int> fileBytes, String fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/training/upload'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'training_file',
          fileBytes,
          filename: fileName,
        ),
      );

      final response = await request.send()
          .timeout(const Duration(seconds: 60));

      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(data);
        
        if (!apiResponse.isSuccess) {
          throw Exception('Failed to upload training data: ${apiResponse.message}');
        }
      } else if (response.statusCode == 422) {
        final data = jsonDecode(responseBody);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(data);
        throw Exception('Validation error: ${apiResponse.message}');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to upload training data');
      }
    } catch (e) {
      throw Exception('Failed to upload training data: $e');
    }
  }
}
