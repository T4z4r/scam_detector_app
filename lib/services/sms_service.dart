import 'package:permission_handler/permission_handler.dart';
import 'package:sms_retriever/sms_retriever.dart';

class SmsService {
  static Stream<String?> getNewSmsStream() {
    return SmsRetriever.startSmsListener();
  }

  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<List<String>> getRecentSms() async {
    // Simplified: Get last 10 SMS for manual checking
    // In production: Use sms_advanced package or content resolver
    return await SmsRetriever.getMessagesFromInterval(
      SmsQueryKind.last10,
    );
  }
}
