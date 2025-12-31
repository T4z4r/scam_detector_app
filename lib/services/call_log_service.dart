import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../models/call_log.dart';
import 'call_log_platform_channel.dart';
// import 'demo_call_log_data.dart';

class CallLogService {
  static StreamController<CallLogEntry>? _callLogStreamController;
  static bool _isMonitoring = false;

  // Sample scam call patterns for detection
  static final List<String> _scamCallPatterns = [
    '0700000000',
    '0711111111',
    '0755555555',
    '0800000000',
    'unknown',
    'private',
    'restricted',
    'telemarketing',
    'suspicious',
  ];

  // Start monitoring incoming call logs
  static Stream<CallLogEntry> getNewCallLogStream() {
    if (_callLogStreamController == null || _callLogStreamController!.isClosed) {
      _callLogStreamController = StreamController<CallLogEntry>.broadcast();
    }

    // Call log monitoring would be implemented here with native code
    // For now, this provides the structure for automatic detection

    return _callLogStreamController!.stream;
  }

  static Future<bool> requestCallLogPermission() async {
    // For Android, call log permissions need special handling
    // The permission_handler package doesn't directly support READ_CALL_LOG
    // We'll request READ_PHONE_STATE as a fallback and handle the permission check
    try {
      // Request READ_PHONE_STATE permission as it's often required for call log access
      final phoneStateStatus = await Permission.phone.request();
      
      if (phoneStateStatus.isGranted) {
        return true;
      } else if (phoneStateStatus.isPermanentlyDenied) {
        // Open app settings for manual permission grant
        await openAppSettings();
        return false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error requesting call log permission: $e');
      return false;
    }
  }

  // Get recent call logs from actual device
  static Future<List<CallLogEntry>> getRecentCallLogs({int limit = 50}) async {
    try {
      final hasPermission = await requestCallLogPermission();
      if (!hasPermission) {
        throw Exception('Call log permission not granted. Please enable call log permissions in app settings.');
      }

      // Try to read actual call logs from device first
      try {
        final actualCallLogs = await _readActualCallLogsFromDevice(limit);
        if (actualCallLogs.isNotEmpty) {
          print('Successfully read ${actualCallLogs.length} actual call logs from device');
          return actualCallLogs;
        }
      } catch (e) {
        print('Failed to read actual call logs from device: $e');
      }
      
      // If we can't read real call logs, provide demo data with clear notification
      print('Unable to read real call logs from device. Using demo data for testing purposes.');
      final demoCallLogs = _getDemoCallLogs();
      return demoCallLogs.take(limit).toList();
      
    } catch (e) {
      throw Exception('Failed to access call logs: $e');
    }
  }

  // Placeholder for actual call log reading implementation
  // This will be replaced with platform channel implementation
  static Future<List<CallLogEntry>> _readActualCallLogsFromDevice(int limit) async {
    try {
      // Use platform channel to read actual call logs from device
      final callLogs = await CallLogPlatformChannel.readActualCallLogs(limit: limit);
      print('Successfully read ${callLogs.length} call logs from platform channel');
      return callLogs;
    } catch (e) {
      print('Failed to read call logs from platform channel: $e');
      return []; // Return empty list for now
    }
  }

  static Future<bool> checkCallLogPermissionStatus() async {
    try {
      // Check READ_PHONE_STATE permission as a proxy for call log access
      final status = await Permission.phone.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking call log permission status: $e');
      return false;
    }
  }

  static Future<void> openCallLogSettings() async {
    await openAppSettings();
  }

  static Future<void> stopListening() async {
    try {
      if (_callLogStreamController != null && !_callLogStreamController!.isClosed) {
        await _callLogStreamController!.close();
      }
      _isMonitoring = false;
    } catch (e) {
      // Error stopping call log monitoring
    }
  }

  // Get call log permission status
  static Future<PermissionStatus> getCallLogPermissionStatus() async {
    return await Permission.phone.status;
  }

  // Check if call log monitoring is active
  static bool get isMonitoring => _isMonitoring;

  // Utility method to validate call log format
  static bool isValidCallLogFormat(String phoneNumber) {
    // Basic phone number validation - can be enhanced based on your requirements
    return phoneNumber.trim().isNotEmpty && phoneNumber.length >= 10;
  }

  // Extract caller information from call log (basic implementation)
  static String extractCallerName(String phoneNumber) {
    // This is a simplified implementation
    // In production, you might want more sophisticated parsing or contact lookup
    if (_scamCallPatterns.contains(phoneNumber.toLowerCase())) {
      return 'Suspected Scam Caller';
    }
    return phoneNumber; // Return phone number as name if no specific name found
  }

  // Add a call log entry to the stream (for testing/demo purposes)
  static void addTestCallLog(CallLogEntry callLog) {
    if (_callLogStreamController != null && !_callLogStreamController!.isClosed) {
      _callLogStreamController!.add(callLog);
    }
  }

  // Check if a phone number is suspected to be a scam
  static bool isScamSuspected(String phoneNumber) {
    final normalizedNumber = phoneNumber.toLowerCase().trim();
    
    // Check against known scam patterns
    if (_scamCallPatterns.contains(normalizedNumber)) {
      return true;
    }
    
    // Check for suspicious patterns
    if (normalizedNumber.contains('private') || 
        normalizedNumber.contains('restricted') ||
        normalizedNumber == 'unknown') {
      return true;
    }
    
    // Check for repeated digits (suspicious pattern)
    final digitsOnly = normalizedNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 10) {
      // Check if all digits are the same (e.g., 0700000000)
      final uniqueDigits = digitsOnly.split('').toSet();
      if (uniqueDigits.length <= 2) {
        return true;
      }
    }
    
    return false;
  }

  // Get statistics about call logs
  static Map<String, int> getCallLogStatistics(List<CallLogEntry> callLogs) {
    int totalCalls = callLogs.length;
    int incomingCalls = callLogs.where((log) => log.callType == CallType.incoming).length;
    int outgoingCalls = callLogs.where((log) => log.callType == CallType.outgoing).length;
    int missedCalls = callLogs.where((log) => log.callType == CallType.missed).length;
    int suspectedScamCalls = callLogs.where((log) => log.isScamSuspected).length;

    return {
      'total': totalCalls,
      'incoming': incomingCalls,
      'outgoing': outgoingCalls,
      'missed': missedCalls,
      'scam_suspected': suspectedScamCalls,
    };
  }

  // Filter call logs by date range
  static List<CallLogEntry> filterByDateRange(
    List<CallLogEntry> callLogs, 
    DateTime startDate, 
    DateTime endDate
  ) {
    return callLogs.where((log) => 
      log.callDate.isAfter(startDate) && log.callDate.isBefore(endDate)
    ).toList();
  }

  // Search call logs by phone number or caller name
  static List<CallLogEntry> searchCallLogs(
    List<CallLogEntry> callLogs, 
    String query
  ) {
    final lowerQuery = query.toLowerCase();
    return callLogs.where((log) =>
      log.phoneNumber.toLowerCase().contains(lowerQuery) ||
      log.callerName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get demo call logs for testing when real call logs cannot be accessed
  static List<CallLogEntry> _getDemoCallLogs() {
    final now = DateTime.now();
    return [
      CallLogEntry(
        phoneNumber: "0701234567",
        callerName: "John Doe",
        callDate: now.subtract(const Duration(minutes: 30)),
        duration: 120,
        callType: CallType.incoming,
        isScamSuspected: false,
      ),
      CallLogEntry(
        phoneNumber: "0755555555",
        callerName: "Suspected Scam Caller",
        callDate: now.subtract(const Duration(hours: 2)),
        duration: 0,
        callType: CallType.missed,
        isScamSuspected: true,
      ),
      CallLogEntry(
        phoneNumber: "0711111111",
        callerName: "Unknown",
        callDate: now.subtract(const Duration(hours: 4)),
        duration: 45,
        callType: CallType.outgoing,
        isScamSuspected: true,
      ),
      CallLogEntry(
        phoneNumber: "0709876543",
        callerName: "Jane Smith",
        callDate: now.subtract(const Duration(days: 1)),
        duration: 300,
        callType: CallType.incoming,
        isScamSuspected: false,
      ),
      CallLogEntry(
        phoneNumber: "Private",
        callerName: "Private Number",
        callDate: now.subtract(const Duration(days: 2)),
        duration: 0,
        callType: CallType.missed,
        isScamSuspected: true,
      ),
    ];
  }
}