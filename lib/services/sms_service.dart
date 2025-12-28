import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class SmsMessage {
  final String sender;
  final String body;
  final DateTime date;

  SmsMessage({
    required this.sender,
    required this.body,
    required this.date,
  });
}

class SmsService {
  static StreamController<SmsMessage>? _smsStreamController;
  static bool _isMonitoring = false;

  // Start monitoring incoming SMS messages
  // Note: For full SMS monitoring, native platform code is required
  // This provides the framework for SMS reading functionality
  static Stream<SmsMessage> getNewSmsStream() {
    if (_smsStreamController == null || _smsStreamController!.isClosed) {
      _smsStreamController = StreamController<SmsMessage>.broadcast();
    }
    
    // SMS monitoring would be implemented here with native code
    // For now, this provides the structure for automatic detection
    
    return _smsStreamController!.stream;
  }

  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Simulate getting recent SMS messages
  // In a real implementation, this would read from device SMS database
  static Future<List<SmsMessage>> getRecentSms({int limit = 50}) async {
    try {
      final hasPermission = await requestSmsPermission();
      if (!hasPermission) {
        throw Exception('SMS permission not granted');
      }
      
      // For demonstration purposes, return empty list
      // In production, this would read actual SMS from device
      return [];
    } catch (e) {
      throw Exception('Failed to access SMS: $e');
    }
  }

  static Future<bool> checkSmsPermissionStatus() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  static Future<void> openSmsSettings() async {
    await openAppSettings();
  }

  static Future<void> stopListening() async {
    try {
      if (_smsStreamController != null && !_smsStreamController!.isClosed) {
        await _smsStreamController!.close();
      }
      _isMonitoring = false;
    } catch (e) {
      // Error stopping SMS monitoring
    }
  }

  // Get SMS permission status
  static Future<PermissionStatus> getSmsPermissionStatus() async {
    return await Permission.sms.status;
  }

  // Check if SMS monitoring is active
  static bool get isMonitoring => _isMonitoring;

  // Utility method to validate SMS format
  static bool isValidSmsFormat(String text) {
    // Basic SMS validation - can be enhanced based on your requirements
    return text.trim().isNotEmpty && text.length >= 10;
  }

  // Extract sender information from SMS (basic implementation)
  static String extractSender(String smsText) {
    // This is a simplified implementation
    // In production, you might want more sophisticated parsing
    // For now, return "Unknown" as we can't access SMS metadata directly
    return "Unknown";
  }

  // Add a message to the stream (for testing/demo purposes)
  static void addTestMessage(SmsMessage message) {
    if (_smsStreamController != null && !_smsStreamController!.isClosed) {
      _smsStreamController!.add(message);
    }
  }
}
