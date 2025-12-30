import 'dart:async';
import 'package:flutter/services.dart';
import '../models/call_log.dart';

class CallLogPlatformChannel {
  static const MethodChannel _channel =
      MethodChannel('com.example.scam_detector_app/call_log_reader');

  // Read actual call logs from device
  static Future<List<CallLogEntry>> readActualCallLogs({int limit = 50}) async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('readCallLogs', {'limit': limit});

      List<CallLogEntry> callLogs = [];
      for (var callLogData in result) {
        // Handle the type casting safely since platform channel returns _Map<Object?, Object?>
        final Map<String, dynamic> callLogMap = _safeCastToStringMap(callLogData);
        
        // Parse call type from string to enum
        CallType callType;
        final typeString = callLogMap['callType']?.toString().toLowerCase() ?? '';
        switch (typeString) {
          case 'incoming':
            callType = CallType.incoming;
            break;
          case 'outgoing':
            callType = CallType.outgoing;
            break;
          case 'missed':
            callType = CallType.missed;
            break;
          default:
            callType = CallType.incoming; // Default to incoming
        }

        callLogs.add(CallLogEntry(
          phoneNumber: callLogMap['phoneNumber']?.toString() ?? '',
          callerName: callLogMap['callerName']?.toString() ?? '',
          callDate: DateTime.fromMillisecondsSinceEpoch(
              callLogMap['callDate']?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
          duration: callLogMap['duration']?.toInt() ?? 0,
          callType: callType,
          isScamSuspected: callLogMap['isScamSuspected']?.toString().toLowerCase() == 'true',
        ));
      }

      return callLogs;
    } on PlatformException catch (e) {
      print('Failed to read call logs: ${e.message}');
      throw Exception('Failed to read call logs from device: ${e.message}');
    } catch (e) {
      print('Error reading call logs: $e');
      throw Exception('Error reading call logs: $e');
    }
  }

  // Check if call log reading is supported
  static Future<bool> isCallLogReadingSupported() async {
    try {
      final bool result = await _channel.invokeMethod('isCallLogSupported');
      return result;
    } catch (e) {
      return false;
    }
  }

  // Helper method to safely cast platform channel map to Map<String, dynamic>
  static Map<String, dynamic> _safeCastToStringMap(dynamic mapData) {
    if (mapData is Map) {
      return mapData.map((key, value) => MapEntry(
            key.toString(),
            value,
          ));
    }
    throw Exception('Expected Map but got ${mapData.runtimeType}');
  }
}