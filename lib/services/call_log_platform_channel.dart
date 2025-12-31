import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/call_log.dart';

class CallLogPlatformChannel {
  static const MethodChannel _channel =
      MethodChannel('com.example.scam_detector_app/call_log_reader');

  // Read actual call logs from device
  static Future<List<CallLogEntry>> readActualCallLogs({int limit = 50}) async {
    try {
      final String? result =
          await _channel.invokeMethod('readCallLogs', {'limit': limit});

      if (result == null || result.isEmpty) {
        return [];
      }

      List<CallLogEntry> callLogs = [];
      
      // Parse the JSON response from Android
      try {
        final List<dynamic> jsonList = json.decode(result);
        
        for (var callLogData in jsonList) {
          if (callLogData is Map<String, dynamic>) {
            // Parse call type from string to enum
            CallType callType;
            final typeString = callLogData['callType']?.toString().toLowerCase() ?? '';
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
              phoneNumber: callLogData['phoneNumber']?.toString() ?? '',
              callerName: callLogData['callerName']?.toString() ?? '',
              callDate: DateTime.fromMillisecondsSinceEpoch(
                  callLogData['callDate']?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
              duration: callLogData['duration']?.toInt() ?? 0,
              callType: callType,
              isScamSuspected: callLogData['isScamSuspected']?.toString().toLowerCase() == 'true',
            ));
          }
        }
      } catch (parseError) {
        print('Error parsing call log JSON: $parseError');
        throw Exception('Failed to parse call log data: $parseError');
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