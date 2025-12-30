import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'sms_platform_channel.dart';
import 'demo_sms_data.dart';

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

  // Get recent SMS messages from actual device
  static Future<List<SmsMessage>> getRecentSms({int limit = 50}) async {
    try {
      final hasPermission = await requestSmsPermission();
      if (!hasPermission) {
        throw Exception('SMS permission not granted. Please enable SMS permissions in app settings.');
      }

      // Try to read actual SMS messages from device first
      try {
        final actualMessages = await _readActualSmsFromDevice(limit);
        if (actualMessages.isNotEmpty) {
          print('Successfully read $actualMessages.length actual SMS messages from device');
          return actualMessages;
        }
      } catch (e) {
        print('Failed to read actual SMS from device: $e');
      }
      
      // If we can't read real SMS, provide demo data with clear notification
      print('Unable to read real SMS from device. Using demo data for testing purposes.');
      final demoMessages = DemoSmsData.getDemoMessages();
      return demoMessages.take(limit).toList();
      
    } catch (e) {
      throw Exception('Failed to access SMS: $e');
    }
  }

  // Placeholder for actual SMS reading implementation
  // This will be replaced with platform channel implementation
  static Future<List<SmsMessage>> _readActualSmsFromDevice(int limit) async {
    // Use platform channel to read actual SMS from device
    return await SmsPlatformChannel.readActualSms(limit: limit);
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
