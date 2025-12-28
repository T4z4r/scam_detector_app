import 'package:flutter/material.dart';
import '../models/scam_result.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';

class ScamProvider with ChangeNotifier {
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = false;
  String? _lastSms;

  List<Map<String, dynamic>> get recentScans => _recentScans;
  bool get isLoading => _isLoading;
  String? get lastSms => _lastSms;

  Future<void> checkScam(String text, {String sender = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.checkScam(text, sender);

      _recentScans.insert(0, {
        'text': text,
        'sender': sender,
        'result': result,
        'timestamp': DateTime.now(),
      });

      if (result.label == 'scam' && result.confidence > 0.8) {
        await NotificationService.showScamAlert(
          title: '🚨 SCAM DETECTED!',
          body:
              '${result.alert}\nConfidence: ${result.confidence.toStringAsFixed(1)}%',
          payload: text,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> startSmsMonitoring() async {
    final hasPermission = await SmsService.requestSmsPermission();
    if (!hasPermission) return;

    SmsService.getNewSmsStream().listen((sms) async {
      if (sms != null && sms.isNotEmpty) {
        _lastSms = sms;
        notifyListeners();

        // Auto-check new SMS
        await checkScam(sms, sender: 'Unknown');
      }
    });
  }

  void clearHistory() {
    _recentScans.clear();
    notifyListeners();
  }
}
