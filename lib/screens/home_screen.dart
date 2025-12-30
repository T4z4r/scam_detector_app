import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/scam_provider.dart';
import '../models/scam_result.dart';

import '../services/scam_history_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _smsController = TextEditingController();
  bool _autoMonitoringEnabled = false;
  bool _showTestPanel = false; // Toggle for test panel

  // Sample test messages for different scam types
  final List<Map<String, dynamic>> _sampleMessages = [
    {
      'title': 'M-Pesa Scam',
      'message':
          'MPESA REVERSAL: You have received Ksh 5000. Click here to confirm: bit.ly/mpesa-reversal',
      'expected': 'scam',
      'color': Colors.red,
    },
    {
      'title': 'Loan Scam',
      'message':
          'Congratulations! Your loan of Tsh 1,000,000 has been approved. Apply now at www.fake-loans.com',
      'expected': 'scam',
      'color': Colors.red,
    },
    {
      'title': 'Crypto Scam',
      'message':
          'Earn 300% returns on Bitcoin investment. Register now for guaranteed profits!',
      'expected': 'suspicious',
      'color': Colors.orange,
    },
    {
      'title': 'Bank Scam',
      'message':
          'URGENT: Your bank account is suspended. Verify your identity immediately.',
      'expected': 'scam',
      'color': Colors.red,
    },
    {
      'title': 'Legitimate Message',
      'message':
          'Hello friend, hope you are doing well. Let\'s meet for lunch tomorrow.',
      'expected': 'legitimate',
      'color': Colors.green,
    },
    {
      'title': 'Prize Scam',
      'message':
          'Congratulations! You have won 10000 in our lottery. Claim now!',
      'expected': 'suspicious',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Start monitoring SMS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScamProvider>().startSmsMonitoring();
    });
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Scam Detector TZ/KE'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ScamProvider>(
        builder: (context, scamProvider, child) {
          return SafeArea(
            child: Column(
              children: [
                // Error Display
                if (scamProvider.hasError)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scamProvider.error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => scamProvider.clearError(),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                // Main Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Quick Check Card
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  scamProvider.isLoading
                                      ? Icons.hourglass_empty
                                      : Icons.security,
                                  size: 64,
                                  color: Colors.orange,
                                ).animate().scale(duration: 500.ms),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _smsController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Paste suspicious SMS here',
                                    hintText: 'M-PESA reversal TSh 50000...',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.send),
                                      onPressed: scamProvider.isLoading
                                          ? null
                                          : _checkScam,
                                    ),
                                  ),
                                ),
                                if (scamProvider.lastSms != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.blue.shade200),
                                    ),
                                    child: Text(
                                      'Latest SMS: ${_truncateText(scamProvider.lastSms!)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  title: const Text(
                                      'Auto-detect scams in incoming SMS'),
                                  subtitle: const Text(
                                      'Automatically analyze incoming messages'),
                                  value: _autoMonitoringEnabled,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _autoMonitoringEnabled = value;
                                    });
                                    if (value) {
                                      context
                                          .read<ScamProvider>()
                                          .startSmsMonitoring();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('SMS monitoring enabled'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('SMS monitoring disabled'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),

                        const SizedBox(height: 16),

                        // Test Panel Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showTestPanel = !_showTestPanel;
                                });
                              },
                              icon: Icon(_showTestPanel
                                  ? Icons.hide_source
                                  : Icons.science),
                              label: Text(_showTestPanel
                                  ? 'Hide Tests'
                                  : '🧪 Show Tests'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // Test Panel
                        if (_showTestPanel) ...[
                          const SizedBox(height: 16),
                          _buildTestPanel(),
                        ],

                        const SizedBox(height: 16),

                        // Recent Scans Section
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Recent Scans',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: scamProvider
                                              .recentScans.isEmpty
                                          ? null
                                          : () => scamProvider.clearHistory(),
                                      child: const Text('Clear All'),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Content Area
                              SizedBox(
                                height: 300, // Fixed height for scrollable list
                                child: scamProvider.recentScans.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No scans yet',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Start by analyzing a suspicious SMS',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        itemCount:
                                            scamProvider.recentScans.length,
                                        itemBuilder: (context, index) {
                                          final scan =
                                              scamProvider.recentScans[index];
                                          final result =
                                              scan['result'] as ScamResult;

                                          return Card(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            color: result.label == 'scam'
                                                ? Colors.red.shade50
                                                : Colors.green.shade50,
                                            child: ListTile(
                                              leading: Icon(
                                                result.label == 'scam'
                                                    ? Icons.warning
                                                    : Icons.check_circle,
                                                color: result.label == 'scam'
                                                    ? Colors.red
                                                    : Colors.green,
                                                size: 24,
                                              ),
                                              title: Text(
                                                _truncateText(
                                                    scan['text'].toString()),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      '${result.confidence.toStringAsFixed(1)}% confidence'),
                                                  Text(
                                                    result.reason,
                                                    style: const TextStyle(
                                                        fontSize: 11),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                              trailing: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: result.label == 'scam'
                                                      ? Colors.red.shade100
                                                      : Colors.green.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  result.label.toUpperCase(),
                                                  style: TextStyle(
                                                    color: result.label ==
                                                            'scam'
                                                        ? Colors.red.shade700
                                                        : Colors.green.shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                              onTap: () => _showScanDetails(
                                                  context, scan),
                                            ),
                                          )
                                              .animate()
                                              .fadeIn(delay: (index * 100).ms);
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 80), // Extra space for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _checkScam(),
        backgroundColor: Colors.green.shade600,
        icon: const Icon(Icons.security_update),
        label: const Text('Quick Scan'),
      ),
    );
  }

  String _truncateText(String text) {
    const maxLength = 50;
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  void _checkScam() {
    final text = _smsController.text.trim();
    if (text.isNotEmpty) {
      context.read<ScamProvider>().checkScam(text);
      _smsController.clear();
    } else {
      // Show a snackbar or error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an SMS text to analyze'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showScanDetails(BuildContext context, Map<String, dynamic> scan) {
    final result = scan['result'] as ScamResult;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.label == 'scam' ? '🚨 SCAM DETECTED' : '✅ Safe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: ${result.confidence.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text('Reason: ${result.reason}'),
            const SizedBox(height: 8),
            Text('Alert: ${result.alert}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  // Test Panel Widget
  Widget _buildTestPanel() {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Testing Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Database Tests Section
            const Text(
              'Database Tests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testDatabaseInsert,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Insert Test Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testDatabaseStats,
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Get Stats'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testDatabaseClear,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notification Tests Section
            const Text(
              'Notification Tests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testBasicNotification,
                  icon: const Icon(Icons.notifications, size: 16),
                  label: const Text('Basic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testScamNotification,
                  icon: const Icon(Icons.warning, size: 16),
                  label: const Text('Scam Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testSuspiciousNotification,
                  icon: const Icon(Icons.psychology, size: 16),
                  label: const Text('Suspicious'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testScheduledNotification,
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Scheduled'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scam Detection Tests Section
            const Text(
              'Scam Detection Tests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._sampleMessages.map((sample) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _testScamDetection(
                        sample['message'] as String, sample['title'] as String),
                    icon: Icon(Icons.verified_user,
                        size: 16, color: sample['color'] as Color),
                    label: Text(sample['title'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (sample['color'] as Color).withValues(alpha: 0.1),
                      foregroundColor: sample['color'] as Color,
                      side: BorderSide(color: sample['color'] as Color),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                )),
            const SizedBox(height: 8),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testAllFeatures,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Run All Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showTestResults,
                  icon: const Icon(Icons.assessment, size: 16),
                  label: const Text('Show Results'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Test Methods
  Future<void> _testDatabaseInsert() async {
    try {
      await ApiService.checkScam(
        'This is a test message for database insertion.',
        'TEST-SENDER',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test data inserted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Database test failed: $e');
    }
  }

  Future<void> _testDatabaseStats() async {
    try {
      final historyService = ScamHistoryService();
      final stats = await historyService.getStatistics();

      _showDialog(
        'Database Statistics',
        'Total Results: ${stats['total_results']}\n'
            'Starred Results: ${stats['starred_results']}\n'
            'Average Confidence: ${stats['average_confidence']}%\n'
            'Results by Label: ${stats['by_label']}\n'
            'Results by Method: ${stats['by_method']}',
      );
    } catch (e) {
      _showError('Failed to get statistics: $e');
    }
  }

  Future<void> _testDatabaseClear() async {
    final confirmed =
        await _showConfirmationDialog('Clear all database records?');
    if (confirmed) {
      try {
        final historyService = ScamHistoryService();
        await historyService.deleteAllResults();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database cleared successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        _showError('Failed to clear database: $e');
      }
    }
  }

  Future<void> _testBasicNotification() async {
    try {
      await NotificationService.testNotification(
        title: 'Basic Test Notification',
        body: 'This is a test of the basic notification functionality.',
        payload: 'basic_test',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Basic notification sent!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      _showError('Notification test failed: $e');
    }
  }

  Future<void> _testScamNotification() async {
    try {
      await NotificationService.testScamNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Scam alert notification sent!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showError('Scam notification test failed: $e');
    }
  }

  Future<void> _testSuspiciousNotification() async {
    try {
      await NotificationService.testSuspiciousNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Suspicious message notification sent!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      _showError('Suspicious notification test failed: $e');
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      await NotificationService.testScheduledNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Scheduled notification set (appears in 5 seconds)!'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      _showError('Scheduled notification test failed: $e');
    }
  }

  Future<void> _testScamDetection(String message, String title) async {
    try {
      final result = await ApiService.checkScam(message, 'TEST-SENDER');

      _showDialog(
        'Test Result: $title',
        'Result: ${result.label.toUpperCase()}\n'
            'Confidence: ${result.confidence.toStringAsFixed(1)}%\n'
            'Reason: ${result.reason}\n'
            'Alert: ${result.alert}',
      );
    } catch (e) {
      _showError('Scam detection test failed: $e');
    }
  }

  Future<void> _testAllFeatures() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Running comprehensive tests...'),
          backgroundColor: Colors.indigo,
        ),
      );

      // Test database insert
      await _testDatabaseInsert();
      await Future.delayed(const Duration(seconds: 1));

      // Test notification
      await _testBasicNotification();
      await Future.delayed(const Duration(seconds: 1));

      // Test scam detection
      await _testScamDetection(
        'MPESA REVERSAL: You have received Ksh 5000. Click here to confirm.',
        'Comprehensive Test',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All tests completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Comprehensive test failed: $e');
    }
  }

  Future<void> _showTestResults() async {
    try {
      final historyService = ScamHistoryService();
      final recentResults = await historyService.getRecentResults(limit: 5);
      final stats = await historyService.getStatistics();

      String resultsText = 'Recent Test Results:\n\n';
      for (int i = 0; i < recentResults.length; i++) {
        final result = recentResults[i];
        resultsText +=
            '${i + 1}. ${result.label.toUpperCase()} (${result.confidence.toStringAsFixed(1)}%) - ${result.sender}\n';
        resultsText += '   ${result.reason}\n\n';
      }

      resultsText += 'Statistics:\n';
      resultsText += 'Total: ${stats['total_results']}\n';
      resultsText += 'Average Confidence: ${stats['average_confidence']}%';

      _showDialog('Test Results', resultsText);
    } catch (e) {
      _showError('Failed to show test results: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Action'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
