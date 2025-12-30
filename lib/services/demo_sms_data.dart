import 'sms_service.dart';

class DemoSmsData {
  // Real SMS-like messages for demonstration when actual SMS reading fails
  static List<SmsMessage> getDemoMessages() {
    return [
      SmsMessage(
        sender: 'MPESA',
        body:
            'You have received Ksh 2,500.00 from JOHN DOE 0712345678 on 15/12/25 at 2:30 PM. New M-PESA balance is Ksh 15,750.50',
        date: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      SmsMessage(
        sender: 'BANK_TZ',
        body:
            'Your account has been temporarily suspended due to suspicious activity. Please call 0712345678 immediately to restore your account.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SmsMessage(
        sender: 'TIGO_MONEY',
        body:
            'Godi reversal pending your account 1234. Enter PIN to confirm transaction. Transaction ID: TXN789456123',
        date: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      SmsMessage(
        sender: 'AMAZON',
        body:
            'Your order #12345 has been shipped. Tracking number: AB123456. Expected delivery: Tomorrow by 6 PM.',
        date: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      SmsMessage(
        sender: 'CRYPTO_BOT',
        body:
            'Earn 300% returns on Bitcoin investment. Register now for guaranteed profits! Visit www.tz-crypto.com',
        date: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      SmsMessage(
        sender: 'FRIEND',
        body:
            'Hey! Hope you are doing well. Let\'s meet for lunch tomorrow at 1 PM. Looking forward to seeing you!',
        date: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      SmsMessage(
        sender: 'AIRTEL_TZ',
        body:
            'Sim swap detected for your number 0712345678. Enter PIN to cancel immediately.',
        date: DateTime.now().subtract(const Duration(hours: 24)),
      ),
      SmsMessage(
        sender: 'GOVERNMENT',
        body:
            'Huduma za serikali: Malipo ya ruzuku ya 50000 Tsh yanahitaji utambulisho. Bonyeza link hii: gov.tz/apply',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SmsMessage(
        sender: 'HOSPITAL',
        body:
            'Your appointment with Dr. Smith is confirmed for tomorrow at 10:00 AM. Please arrive 15 minutes early.',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      SmsMessage(
        sender: 'PRIZE_NOTIFY',
        body:
            'Congratulations! You won \$1000! Click here: http://fake.com to claim your prize',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }
}
