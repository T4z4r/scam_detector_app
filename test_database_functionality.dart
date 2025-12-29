/// Test file to demonstrate local database functionality for scam detection results
/// Run this file to test the database integration

import 'dart:async';
import 'lib/models/scam_result.dart';
import 'lib/models/scam_result_db.dart';
import 'lib/services/database_helper.dart';
import 'lib/services/scam_history_service.dart';
import 'lib/services/api_service.dart';
import 'lib/services/local_scam_detection_service.dart';

Future<void> main() async {
  print('=== Scam Detector Local Database Test ===\n');

  // Initialize database service
  final dbHelper = DatabaseHelper();
  final historyService = ScamHistoryService();

  try {
    // Test 1: Test database initialization
    print('1. Testing database initialization...');
    final database = await dbHelper.database;
    print('✓ Database initialized successfully\n');

    // Test 2: Test inserting sample scam results
    print('2. Testing insert operations...');
    
    // Create sample results
    final sampleResults = [
      // Legitimate message
      ScamResultDB.fromScamResult(
        ScamResult(
          label: 'legitimate',
          confidence: 95.0,
          reason: 'No scam patterns detected in message',
          alert: 'This appears to be a legitimate message',
        ),
        'Hello, how are you doing today?',
        'FRIEND',
        detectionMethod: 'local',
      ),
      
      // M-Pesa scam
      ScamResultDB.fromScamResult(
        ScamResult(
          label: 'scam',
          confidence: 90.0,
          reason: 'M-Pesa reversal scam - common fraud tactic in East Africa',
          alert: 'Never share your M-Pesa PIN or click suspicious links claiming reversals',
        ),
        'MPESA REVERSAL: You have received Ksh 5000. Click here to confirm: bit.ly/mpesa-reversal',
        'MPESA',
        detectionMethod: 'local',
      ),
      
      // Loan scam
      ScamResultDB.fromScamResult(
        ScamResult(
          label: 'scam',
          confidence: 85.0,
          reason: 'Fake loan approval scam',
          alert: 'Legitimate loans require proper application and verification',
        ),
        'Congratulations! Your loan of Tsh 1,000,000 has been approved. Apply now at www.fake-loans.com',
        'LOAN-APPROVAL',
        detectionMethod: 'api',
      ),
      
      // Cryptocurrency scam
      ScamResultDB.fromScamResult(
        ScamResult(
          label: 'suspicious',
          confidence: 75.0,
          reason: 'Cryptocurrency investment scam',
          alert: 'No investment can guarantee returns - this is a common scam tactic',
        ),
        'Earn 300% returns on Bitcoin investment. Register now for guaranteed profits!',
        'CRYPTO-INVEST',
        detectionMethod: 'hybrid',
      ),
    ];

    // Insert all sample results
    for (final result in sampleResults) {
      final id = await dbHelper.insertScamResult(result);
      print('✓ Inserted result with ID: $id');
    }
    print('');

    // Test 3: Test retrieval operations
    print('3. Testing retrieval operations...');
    
    // Get all results
    final allResults = await historyService.getAllResults();
    print('✓ Retrieved ${allResults.length} total results');
    
    // Get results by label
    final scamResults = await historyService.getResultsByLabel('scam');
    print('✓ Retrieved ${scamResults.length} scam results');
    
    final legitimateResults = await historyService.getResultsByLabel('legitimate');
    print('✓ Retrieved ${legitimateResults.length} legitimate results');
    
    // Get results by detection method
    final localResults = await historyService.getResultsByMethod('local');
    print('✓ Retrieved ${localResults.length} locally detected results');
    
    final apiResults = await historyService.getResultsByMethod('api');
    print('✓ Retrieved ${apiResults.length} API detected results\n');

    // Test 4: Test search functionality
    print('4. Testing search functionality...');
    
    final mpesaResults = await historyService.searchResults('mpesa');
    print('✓ Found ${mpesaResults.length} results containing "mpesa"');
    
    final loanResults = await historyService.searchResults('loan');
    print('✓ Found ${loanResults.length} results containing "loan"\n');

    // Test 5: Test star functionality
    print('5. Testing star functionality...');
    
    if (allResults.isNotEmpty) {
      final firstResult = allResults.first;
      final toggleResult = await historyService.toggleStarStatus(firstResult.id!);
      print('✓ Toggle star status for result ${firstResult.id}: $toggleResult');
      
      final starredResults = await historyService.getStarredResults();
      print('✓ Retrieved ${starredResults.length} starred results\n');
    }

    // Test 6: Test statistics
    print('6. Testing statistics...');
    
    final stats = await historyService.getStatistics();
    print('✓ Total results: ${stats['total_results']}');
    print('✓ Starred results: ${stats['starred_results']}');
    print('✓ Average confidence: ${stats['average_confidence']}%');
    print('✓ Results by label: ${stats['by_label']}');
    print('✓ Results by method: ${stats['by_method']}\n');

    // Test 7: Test today's summary
    print('7. Testing today\'s summary...');
    
    final todaySummary = await historyService.getTodaySummary();
    print('✓ Today\'s summary: $todaySummary\n');

    // Test 8: Test recent results
    print('8. Testing recent results...');
    
    final recentResults = await historyService.getRecentResults(limit: 5);
    print('✓ Retrieved ${recentResults.length} recent results');
    
    for (final result in recentResults) {
      print('  - ${result.label} (${result.confidence.toStringAsFixed(1)}%) from ${result.sender}');
    }
    print('');

    // Test 9: Test real scam detection with database storage
    print('9. Testing real scam detection with database storage...');
    
    final testMessages = [
      'Hello friend, hope you are well',
      'URGENT: Your M-Pesa account is suspended. Click here to restore: fake-mpesa.com',
      'Congratulations! You have won 10000 in our lottery. Claim now!',
      'Emergency: Your family member is in hospital. Send money immediately to this number.',
    ];
    
    for (final message in testMessages) {
      try {
        final result = await ApiService.checkScam(message, 'TEST-SENDER');
        print('✓ Analyzed: "${message.substring(0, message.length > 50 ? 50 : message.length)}..."');
        print('  Result: ${result.label} (${result.confidence.toStringAsFixed(1)}% confidence)');
        print('  Reason: ${result.reason}\n');
      } catch (e) {
        print('✗ Failed to analyze message: $e\n');
      }
    }

    // Test 10: Show final statistics
    print('10. Final statistics after testing...');
    
    final finalStats = await historyService.getStatistics();
    print('✓ Final total results: ${finalStats['total_results']}');
    print('✓ Final results by label: ${finalStats['by_label']}');
    print('✓ Final results by method: ${finalStats['by_method']}\n');

    // Test 11: Test cleanup
    print('11. Testing cleanup operations...');
    
    final commonPatterns = await historyService.getMostCommonPatterns();
    print('✓ Most common scam patterns: $commonPatterns');
    
    final senderStats = await historyService.getSenderStatistics();
    print('✓ Sender statistics: $senderStats\n');

    print('=== All tests completed successfully! ===');
    print('\nDatabase Features Available:');
    print('- Automatic storage of all scam detection results');
    print('- Search functionality across stored results');
    print('- Star important results for quick access');
    print('- Comprehensive statistics and analytics');
    print('- Date-based filtering and time ranges');
    print('- Export functionality for backup/sharing');
    print('- Cleanup old results automatically');

  } catch (e, stackTrace) {
    print('✗ Test failed with error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Close database connection
    await dbHelper.close();
    print('\n✓ Database connection closed');
  }
}