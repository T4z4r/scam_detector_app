# Local Database Integration for Scam Detection Results

## Overview

The scam detector app now includes comprehensive local database storage using SQLite to store all scam detection results. This provides persistent storage, advanced querying capabilities, and detailed analytics for scam detection patterns.

## Features Added

### 🔄 Automatic Storage
- All scam detection results are automatically stored in the local database
- No additional code required - works seamlessly with existing API and local detection
- Results include detection method, confidence score, source text, and sender information

### 📊 Advanced Analytics
- Comprehensive statistics and analytics
- Pattern analysis and trend identification
- Sender reputation tracking
- Time-based filtering and grouping

### 🔍 Search & Filter
- Full-text search across all stored results
- Filter by detection method (local, API, hybrid)
- Filter by result label (scam, legitimate, suspicious)
- Date range filtering and time-based queries

### ⭐ User Features
- Star important results for quick access
- Export functionality for backup and sharing
- Automatic cleanup of old results
- Real-time statistics and summaries

## Files Added/Modified

### New Files
- `lib/models/scam_result_db.dart` - Database model extending base ScamResult
- `lib/services/database_helper.dart` - Core database operations
- `lib/services/scam_history_service.dart` - High-level history management
- `test_database_functionality.dart` - Comprehensive test suite

### Modified Files
- `pubspec.yaml` - Added SQLite dependencies
- `lib/services/api_service.dart` - Integrated automatic database storage

## Dependencies Added

```yaml
sqflite: ^2.4.1      # SQLite database
path: ^1.0.0         # Database path utilities
```

## Database Schema

### Main Table: `scam_results`

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PRIMARY KEY | Auto-incrementing ID |
| `label` | TEXT | Detection result (scam/legitimate/suspicious) |
| `confidence` | REAL | Confidence score (0-100) |
| `reason` | TEXT | Detection reason/explanation |
| `alert` | TEXT | Alert message for user |
| `source_text` | TEXT | Original SMS/message text |
| `sender` | TEXT | Message sender |
| `detection_method` | TEXT | How it was detected (local/api/hybrid) |
| `is_starred` | INTEGER | User-starred flag (0/1) |
| `created_at` | TEXT | ISO8601 timestamp |
| `updated_at` | TEXT | ISO8601 timestamp |

## Usage Examples

### Basic Database Operations

```dart
import 'lib/services/database_helper.dart';
import 'lib/services/scam_history_service.dart';

// Initialize services
final dbHelper = DatabaseHelper();
final historyService = ScamHistoryService();

// Insert a result (automatically done by ApiService)
final result = ScamResultDB.fromScamResult(
  scamResult,
  sourceText,
  sender,
  detectionMethod: 'local',
);
await dbHelper.insertScamResult(result);
```

### Retrieving Results

```dart
// Get all results with pagination
final allResults = await historyService.getAllResults(limit: 50);

// Get results by label
final scamResults = await historyService.getResultsByLabel('scam');
final legitimateResults = await historyService.getResultsByLabel('legitimate');

// Get results by detection method
final localResults = await historyService.getResultsByMethod('local');
final apiResults = await historyService.getResultsByMethod('api');

// Get starred results
final starredResults = await historyService.getStarredResults();

// Search results
final searchResults = await historyService.searchResults('mpesa');

// Get recent results (last 24 hours)
final recentResults = await historyService.getRecentResults();

// Get today's results
final todayResults = await historyService.getTodayResults();
```

### Statistics and Analytics

```dart
// Get comprehensive statistics
final stats = await historyService.getStatistics();
print('Total results: ${stats['total_results']}');
print('Results by label: ${stats['by_label']}');
print('Results by method: ${stats['by_method']}');
print('Average confidence: ${stats['average_confidence']}%');

// Get today's summary
final todaySummary = await historyService.getTodaySummary();
print('Today: ${todaySummary['total']} total, ${todaySummary['scam']} scams');

// Get weekly statistics
final weeklyStats = await historyService.getWeeklyStatistics();

// Get most common scam patterns
final patterns = await historyService.getMostCommonPatterns();

// Get sender statistics
final senders = await historyService.getSenderStatistics();
```

### User Interactions

```dart
// Toggle star status
await historyService.toggleStarStatus(resultId);

// Star/unstar specific result
await historyService.starResult(resultId);
await historyService.unstarResult(resultId);

// Delete result
await historyService.deleteResult(resultId);

// Export results
final exportedData = await historyService.exportResults(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
```

### Date Range Filtering

```dart
// Get results from specific date range
final weekResults = await historyService.getResultsFromDateRange(
  DateTime.now().subtract(Duration(days: 7)),
  DateTime.now(),
);

// Get this week's results
final weekResults = await historyService.getWeekResults();

// Get last week's results
final lastWeekResults = await historyService.getLastWeekResults();
```

## Automatic Integration

The database integration is seamless - no code changes required in existing components:

### API Service Integration
```dart
// This now automatically stores results in the database
final result = await ApiService.checkScam(text, sender);
// Result is automatically saved with metadata
```

### Provider Integration
The existing `ScamProvider` continues to work normally, while results are automatically stored in the background.

## Performance Optimizations

- **Indexes**: Created on frequently queried columns (label, created_at, detection_method, is_starred)
- **Pagination**: All retrieval methods support limit/offset for large datasets
- **Efficient Queries**: Optimized SQL queries with proper WHERE clauses
- **Connection Management**: Singleton database instance with proper cleanup

## Data Management

### Automatic Cleanup
```dart
// Clean up results older than 30 days
final deletedCount = await historyService.cleanupOldResults(30);
```

### Export Functionality
```dart
// Export all results for backup
final allExported = await historyService.exportResults();

// Export only scam results
final scamExported = await historyService.exportResults(label: 'scam');

// Export results from last week
final weekExported = await historyService.exportResults(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
```

## Testing

Run the comprehensive test suite:

```bash
dart test_database_functionality.dart
```

This tests:
- Database initialization
- Insert operations
- Retrieval operations
- Search functionality
- Star functionality
- Statistics generation
- Real scam detection with storage
- Cleanup operations

## Migration Guide

### For Existing Code
No changes required! The database integration is backward compatible:

1. Existing `ScamResult` objects continue to work unchanged
2. All existing methods in `ApiService` work as before
3. Results are automatically stored without any code changes
4. Provider and UI components continue to function normally

### For New Features
To add database-aware features:

1. Use `ScamHistoryService` for all result retrieval
2. Use `ScamResultDB` for database-specific operations
3. Leverage the statistics methods for analytics
4. Use the search functionality for user interfaces

## Best Practices

1. **Always handle async operations** - All database operations are async
2. **Use pagination** - Don't load thousands of results at once
3. **Star important results** - Users can mark significant findings
4. **Regular cleanup** - Remove old results to keep database size manageable
5. **Use search wisely** - Full-text search can be expensive on large datasets

## Future Enhancements

Potential improvements for future versions:
- Cloud synchronization
- Advanced analytics dashboard
- Machine learning pattern recognition
- User behavior tracking
- Report generation
- Data encryption for sensitive information

## Troubleshooting

### Common Issues

1. **Database not initializing**: Check SQLite permissions and storage availability
2. **Slow queries**: Ensure proper indexing and use pagination
3. **Memory issues**: Use pagination and limit result sets
4. **Data corruption**: Implement proper error handling and backups

### Debug Mode
Enable debug logging by setting:
```dart
import 'dart:developer' as developer;

void debugLog(String message) {
  developer.log(message, name: 'ScamDB');
}
```

The database integration provides a solid foundation for advanced scam detection analytics while maintaining the simplicity and performance of the existing codebase.