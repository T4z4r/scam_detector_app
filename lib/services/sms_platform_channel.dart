import 'dart:async';
import 'package:flutter/services.dart';
import 'sms_service.dart';

class SmsPlatformChannel {
  static const MethodChannel _channel =
      MethodChannel('com.example.scam_detector_app/sms_reader');

  // Read actual SMS messages from device
  static Future<List<SmsMessage>> readActualSms({int limit = 50}) async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('readSms', {'limit': limit});

      List<SmsMessage> messages = [];
      for (var smsData in result) {
        // Handle the type casting safely since platform channel returns _Map<Object?, Object?>
        final Map<String, dynamic> smsMap = _safeCastToStringMap(smsData);
        messages.add(SmsMessage(
          sender: smsMap['sender']?.toString() ?? 'Unknown',
          body: smsMap['body']?.toString() ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(
              smsMap['timestamp']?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
        ));
      }

      return messages;
    } on PlatformException catch (e) {
      print('Failed to read SMS: ${e.message}');
      throw Exception('Failed to read SMS from device: ${e.message}');
    } catch (e) {
      print('Error reading SMS: $e');
      throw Exception('Error reading SMS: $e');
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

  // Check if SMS reading is supported
  static Future<bool> isSmsReadingSupported() async {
    try {
      final bool result = await _channel.invokeMethod('isSmsSupported');
      return result;
    } catch (e) {
      return false;
    }
  }
}
