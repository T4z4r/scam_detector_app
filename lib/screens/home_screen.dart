import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/scam_provider.dart';
import '../models/scam_result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _smsController = TextEditingController();
  bool _autoMonitoringEnabled = false;

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
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Error Display
                if (scamProvider.hasError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                // Quick Check Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
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
                                borderRadius: BorderRadius.circular(12)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed:
                                  scamProvider.isLoading ? null : _checkScam,
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
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Latest SMS: ${_truncateText(scamProvider.lastSms!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title:
                              const Text('Auto-detect scams in incoming SMS'),
                          subtitle: const Text(
                              'Automatically analyze incoming messages'),
                          value: _autoMonitoringEnabled,
                          onChanged: (bool value) {
                            setState(() {
                              _autoMonitoringEnabled = value;
                            });
                            if (value) {
                              context.read<ScamProvider>().startSmsMonitoring();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('SMS monitoring enabled'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('SMS monitoring disabled'),
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

                const SizedBox(height: 24),

                // Recent Scans
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Scans',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: scamProvider.recentScans.isEmpty
                                ? null
                                : () => scamProvider.clearHistory(),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: scamProvider.recentScans.length,
                          itemBuilder: (context, index) {
                            final scan = scamProvider.recentScans[index];
                            final result = scan['result'] as ScamResult;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                  size: 32,
                                ),
                                title: Text(
                                    _truncateText(scan['text'].toString())),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${result.confidence.toStringAsFixed(1)}% confidence'),
                                    Text(result.reason,
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: Text(
                                  result.label.toUpperCase(),
                                  style: TextStyle(
                                    color: result.label == 'scam'
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => _showScanDetails(context, scan),
                              ),
                            ).animate().fadeIn(delay: (index * 100).ms);
                          },
                        ),
                      ),
                    ],
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
}
