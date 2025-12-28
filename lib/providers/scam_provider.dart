import 'dart:async';
import 'package:flutter/material.dart';
import '../models/scam_result.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';

class ScamProvider with ChangeNotifier {
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = false;
  String? _lastSms;
  String? _error;
  StreamSubscription<String?>? _smsSubscription;

  List<Map<String, dynamic>> get recentScans => _recentScans;
  bool get isLoading => _isLoading;
  String? get lastSms => _lastSms;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> checkScam(String text, {String sender = ''}) async {
    // Clear previous error
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Validate input
      if (text.trim().isEmpty) {
        throw Exception('Please enter an SMS text to analyze');
      }

      final result = await ApiService.checkScam(text.trim(), sender.trim());

      _recentScans.insert(0, {
        'text': text.trim(),
        'sender': sender.trim(),
        'result': result,
        'timestamp': DateTime.now(),
      });

      // Keep only last 50 scans to prevent memory issues
      if (_recentScans.length > 50) {
        _recentScans = _recentScans.take(50).toList();
      }

      // Show notification for high-confidence scam detection
      if (result.label == 'scam' && result.confidence > 80.0) {
        await NotificationService.showScamAlert(
          title: '🚨 HIGH RISK SCAM DETECTED!',
          body:
              '${result.alert}\nConfidence: ${result.confidence.toStringAsFixed(1)}%\n\nSender: $sender',
          payload: text,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();

      // Re-throw to allow UI to handle specific error cases if needed
      rethrow;
    }
  }

  Future<void> startSmsMonitoring() async {
    try {
      final hasPermission = await SmsService.requestSmsPermission();
      if (!hasPermission) {
        _error =
            'SMS permission is required for automatic monitoring. Please grant permission in app settings.';
        notifyListeners();
        return;
      }

      // Note: Automatic SMS monitoring is limited due to privacy restrictions
      // This implementation focuses on manual SMS analysis for security
      _error = null;
      notifyListeners();

      // You can implement manual SMS monitoring here if needed
      // or rely on user manually pasting SMS text
    } catch (e) {
      _error = 'Failed to setup SMS monitoring: $e';
      notifyListeners();
    }
  }

  void clearHistory() {
    _recentScans.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  // Get statistics
  Map<String, int> get scanStatistics {
    int totalScans = _recentScans.length;
    int scamDetected = _recentScans
        .where((scan) => (scan['result'] as ScamResult).label == 'scam')
        .length;
    int safeScans = totalScans - scamDetected;

    return {
      'total': totalScans,
      'scam': scamDetected,
      'safe': safeScans,
    };
  }

  // Get recent scam alerts
  List<Map<String, dynamic>> get recentScamAlerts {
    return _recentScans
        .where((scan) => (scan['result'] as ScamResult).label == 'scam')
        .take(10)
        .toList();
  }
}
