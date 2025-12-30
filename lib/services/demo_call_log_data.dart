import '../models/call_log.dart';

class DemoCallLogData {
  // Real call log-like entries for demonstration when actual call log reading fails
  static List<CallLogEntry> getDemoCallLogs() {
    return [
      CallLogEntry(
        phoneNumber: '+255712345678',
        callerName: 'MPESA Support',
        callDate: DateTime.now().subtract(const Duration(minutes: 30)),
        duration: 120, // 2 minutes
        callType: CallType.incoming,
        isScamSuspected: false,
      ),
      CallLogEntry(
        phoneNumber: '0700000000',
        callerName: 'Unknown',
        callDate: DateTime.now().subtract(const Duration(hours: 2)),
        duration: 0, // Missed call
        callType: CallType.missed,
        isScamSuspected: true, // Suspicious number pattern
      ),
      CallLogEntry(
        phoneNumber: '+255765432109',
        callerName: 'CRDB Bank',
        callDate: DateTime.now().subtract(const Duration(hours: 4)),
        duration: 180, // 3 minutes
        callType: CallType.outgoing,
        isScamSuspected: false,
      ),
      CallLogEntry(
        phoneNumber: 'Private Number',
        callerName: 'Private',
        callDate: DateTime.now().subtract(const Duration(hours: 6)),
        duration: 0, // Missed call
        callType: CallType.missed,
        isScamSuspected: true, // Private numbers are suspicious
      ),
      CallLogEntry(
        phoneNumber: '+255700111222',
        callerName: 'Telecom Tanzania',
        callDate: DateTime.now().subtract(const Duration(hours: 8)),
        duration: 90, // 1.5 minutes
        callType: CallType.incoming,
        isScamSuspected: false,
      ),
      CallLogEntry(
        phoneNumber: '0800000000',
        callerName: 'Unknown',
        callDate: DateTime.now().subtract(const Duration(hours: 12)),
        duration: 0, // Missed call
        callType: CallType.missed,
        isScamSuspected: true, // Suspicious pattern
      ),
      CallLogEntry(
        phoneNumber: '+255755555555',
        callerName: 'Airtel Tanzania',
        callDate: DateTime.now().subtract(const Duration(hours: 24)),
        duration: 240, // 4 minutes
        callType: CallType.outgoing,
        isScamSuspected: false,
      ),
      CallLogEntry(
        phoneNumber: 'Restricted',
        callerName: 'Restricted',
        callDate: DateTime.now().subtract(const Duration(days: 2)),
        duration: 0, // Missed call
        callType: CallType.missed,
        isScamSuspected: true, // Restricted numbers are suspicious
      ),
      CallLogEntry(
        phoneNumber: '+255712000999',
        callerName: 'Government Office',
        callDate: DateTime.now().subtract(const Duration(days: 3)),
        duration: 300, // 5 minutes
        callType: CallType.incoming,
        isScamSuspected: false,
      ),
      CallLogEntry(
        phoneNumber: 'unknown',
        callerName: 'Unknown',
        callDate: DateTime.now().subtract(const Duration(days: 4)),
        duration: 0, // Missed call
        callType: CallType.missed,
        isScamSuspected: true, // Unknown numbers can be suspicious
      ),
    ];
  }

  // Get specific types of call logs for testing
  static List<CallLogEntry> getIncomingCalls() {
    return getDemoCallLogs()
        .where((log) => log.callType == CallType.incoming)
        .toList();
  }

  static List<CallLogEntry> getOutgoingCalls() {
    return getDemoCallLogs()
        .where((log) => log.callType == CallType.outgoing)
        .toList();
  }

  static List<CallLogEntry> getMissedCalls() {
    return getDemoCallLogs()
        .where((log) => log.callType == CallType.missed)
        .toList();
  }

  static List<CallLogEntry> getSuspectedScamCalls() {
    return getDemoCallLogs().where((log) => log.isScamSuspected).toList();
  }

  // Get call logs from a specific time range
  static List<CallLogEntry> getCallLogsFromLast24Hours() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return getDemoCallLogs()
        .where((log) => log.callDate.isAfter(yesterday))
        .toList();
  }

  static List<CallLogEntry> getCallLogsFromLastWeek() {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return getDemoCallLogs()
        .where((log) => log.callDate.isAfter(lastWeek))
        .toList();
  }

  // Search call logs by phone number or caller name
  static List<CallLogEntry> searchCallLogs(String query) {
    final lowerQuery = query.toLowerCase();
    return getDemoCallLogs()
        .where((log) =>
            log.phoneNumber.toLowerCase().contains(lowerQuery) ||
            log.callerName.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
