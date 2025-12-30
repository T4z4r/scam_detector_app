import 'lib/services/sms_service.dart';

void main() async {
  print('Testing SMS service fix...');
  
  try {
    // Test SMS service getRecentSms method
    print('Testing SMS service with demo data fallback...');
    final messages = await SmsService.getRecentSms(limit: 5);
    
    print('✅ Successfully retrieved ${messages.length} SMS messages');
    if (messages.isNotEmpty) {
      final firstMessage = messages.first;
      final preview = firstMessage.body.length > 50 
          ? '${firstMessage.body.substring(0, 50)}...' 
          : firstMessage.body;
      print('Sample message: ${firstMessage.sender} - $preview');
    }
    
    print('✅ SMS service fix verification complete!');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}