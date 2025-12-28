import 'package:permission_handler/permission_handler.dart';

class SmsService {
  // Note: SMS monitoring is implemented without third-party plugins
  // due to privacy restrictions and plugin compatibility issues
  static Stream<String?> getNewSmsStream() {
    // Return empty stream - SMS monitoring requires manual implementation
    // or using platform-specific code with content resolver
    return const Stream.empty();
  }

  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<List<String>> getRecentSms() async {
    try {
      final hasPermission = await requestSmsPermission();
      if (!hasPermission) {
        throw Exception('SMS permission not granted');
      }
      
      // For privacy and security reasons, direct SMS access is restricted
      // Users will need to manually paste SMS text for analysis
      // This approach ensures better security and user control
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
    // No-op for manual SMS approach
  }

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
}
