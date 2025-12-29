import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

/// Widget panel for testing notification functionality
/// Can be integrated into the main app for easy testing
class NotificationTestPanel extends StatefulWidget {
  const NotificationTestPanel({Key? key}) : super(key: key);

  @override
  State<NotificationTestPanel> createState() => _NotificationTestPanelState();
}

class _NotificationTestPanelState extends State<NotificationTestPanel> {
  bool _isExpanded = false;
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: const Text('🧪 Notification Testing'),
        subtitle: const Text('Test local notification functionality'),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Quick Tests',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                
                // Basic notification test
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testBasicNotification(),
                  icon: _isTesting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.notifications),
                  label: const Text('Test Basic Notification'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                const SizedBox(height: 8),

                // Scam alert test
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testScamAlert(),
                  icon: _isTesting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.warning, color: Colors.red),
                  label: const Text('Test Scam Alert'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                const SizedBox(height: 8),

                // Suspicious message test
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testSuspiciousAlert(),
                  icon: _isTesting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.psychology, color: Colors.orange),
                  label: const Text('Test Suspicious Alert'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                const SizedBox(height: 8),

                // Legitimate message test
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testLegitimateAlert(),
                  icon: _isTesting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text('Test Legitimate Alert'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 8),

                const Text(
                  'Real Detection Tests',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Test with real scam detection
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testRealScamDetection(),
                  icon: _isTesting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.security),
                  label: const Text('Test Real Scam Detection'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
                const SizedBox(height: 8),

                // Test scheduled notification
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testScheduledNotification(),
                  icon: _isTesting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.schedule),
                  label: const Text('Test Scheduled Notification'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 8),

                // Clear all notifications
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _clearAllNotifications(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All Notifications'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testBasicNotification() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService.testNotification(
        title: 'Basic Test',
        body: 'This is a basic notification test to verify functionality.',
      );
      _showSnackBar('Basic notification sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send notification: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testScamAlert() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService.testScamNotification();
      _showSnackBar('Scam alert sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send scam alert: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testSuspiciousAlert() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService.testSuspiciousNotification();
      _showSnackBar('Suspicious alert sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send suspicious alert: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testLegitimateAlert() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService.testLegitimateNotification();
      _showSnackBar('Legitimate notification sent successfully!');
    } catch (e) {
      _showSnackBar('Failed to send legitimate notification: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testRealScamDetection() async {
    setState(() => _isTesting = true);
    try {
      // Test with a known scam message
      final result = await ApiService.checkScam(
        'MPESA REVERSAL: You have received Ksh 5000. Click here to confirm: bit.ly/mpesa-reversal',
        'MPESA',
      );

      if (result.label == 'scam' && result.confidence > 80.0) {
        await NotificationService.showScamAlert(
          title: '🚨 AUTO-DETECTED SCAM!',
          body: '${result.alert}\\nConfidence: ${result.confidence.toStringAsFixed(1)}%\\n\\nSender: MPESA',
          payload: 'auto_detected_scam',
        );
        _showSnackBar('Real scam detected and notification sent!');
      } else {
        _showSnackBar('Detection result: ${result.label} (${result.confidence.toStringAsFixed(1)}%)');
      }
    } catch (e) {
      _showSnackBar('Failed to test real detection: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testScheduledNotification() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService.testScheduledNotification();
      _showSnackBar('Scheduled notification set (appears in 5 seconds)!');
    } catch (e) {
      _showSnackBar('Failed to schedule notification: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService.cancelAllNotifications();
      _showSnackBar('All notifications cleared!');
    } catch (e) {
      _showSnackBar('Failed to clear notifications: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}