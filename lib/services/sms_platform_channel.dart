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
        final smsMap = smsData as Map<String, dynamic>;
        messages.add(SmsMessage(
          sender: smsMap['sender']?.toString() ?? 'Unknown',
          body: smsMap['body']?.toString() ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(
              smsMap['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
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
