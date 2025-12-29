import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/scam_result_db.dart';
import 'database_helper.dart';

/// Service for managing scam detection history and statistics
/// Provides convenient methods for retrieving stored results
class ScamHistoryService {
  static final ScamHistoryService _instance = ScamHistoryService._internal();
  factory ScamHistoryService() => _instance;
  ScamHistoryService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get all scam detection results with pagination
  Future<List<ScamResultDB>> getAllResults({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _dbHelper.getAllScamResults(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting all results: $e');
      return [];
    }
  }

  /// Get results filtered by label (scam, legitimate, suspicious)
  Future<List<ScamResultDB>> getResultsByLabel(
    String label, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _dbHelper.getScamResultsByLabel(
        label,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting results by label: $e');
      return [];
    }
  }

  /// Get results filtered by detection method
  Future<List<ScamResultDB>> getResultsByMethod(
    String method, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _dbHelper.getScamResultsByMethod(
        method,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting results by method: $e');
      return [];
    }
  }

  /// Get starred (important) results
  Future<List<ScamResultDB>> getStarredResults({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _dbHelper.getStarredScamResults(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting starred results: $e');
      return [];
    }
  }

  /// Search results by text content
  Future<List<ScamResultDB>> searchResults(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      return await _dbHelper.searchScamResults(
        query,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error searching results: $e');
      return [];
    }
  }

  /// Get results from a specific date range
  Future<List<ScamResultDB>> getResultsFromDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _dbHelper.getScamResultsFromDate(
        startDate,
        endDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting results by date range: $e');
      return [];
    }
  }

  /// Get recent results (last 24 hours)
  Future<List<ScamResultDB>> getRecentResults({
    int limit = 20,
  }) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    return await getResultsFromDateRange(yesterday, now, limit: limit);
  }

  /// Get today's results
  Future<List<ScamResultDB>> getTodayResults() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await getResultsFromDateRange(startOfDay, endOfDay);
  }

  /// Get this week's results
  Future<List<ScamResultDB>> getWeekResults() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return await getResultsFromDateRange(startOfWeek, endOfWeek);
  }

  /// Get results from the last 7 days
  Future<List<ScamResultDB>> getLastWeekResults() async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));

    return await getResultsFromDateRange(lastWeek, now);
  }

  /// Get a specific result by ID
  Future<ScamResultDB?> getResultById(int id) async {
    try {
      return await _dbHelper.getScamResultById(id);
    } catch (e) {
      debugPrint('Error getting result by ID: $e');
      return null;
    }
  }

  /// Toggle star status of a result
  Future<bool> toggleStarStatus(int id) async {
    try {
      final result = await _dbHelper.toggleStarStatus(id);
      return result > 0;
    } catch (e) {
      debugPrint('Error toggling star status: $e');
      return false;
    }
  }

  /// Star a result
  Future<bool> starResult(int id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(
        'scam_results',
        {'is_starred': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Error starring result: $e');
      return false;
    }
  }

  /// Unstar a result
  Future<bool> unstarResult(int id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(
        'scam_results',
        {'is_starred': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Error unstarring result: $e');
      return false;
    }
  }

  /// Delete a specific result
  Future<bool> deleteResult(int id) async {
    try {
      final result = await _dbHelper.deleteScamResult(id);
      return result > 0;
    } catch (e) {
      debugPrint('Error deleting result: $e');
      return false;
    }
  }

  /// Delete all results (with confirmation)
  Future<bool> deleteAllResults() async {
    try {
      final result = await _dbHelper.deleteAllScamResults();
      return result >= 0; // 0 means no rows affected, but operation succeeded
    } catch (e) {
      debugPrint('Error deleting all results: $e');
      return false;
    }
  }

  /// Get comprehensive statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _dbHelper.getStatistics();
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {
        'total_results': 0,
        'starred_results': 0,
        'by_label': {},
        'by_method': {},
        'average_confidence': '0.00',
      };
    }
  }

  /// Get summary statistics for today
  Future<Map<String, int>> getTodaySummary() async {
    final todayResults = await getTodayResults();

    final summary = <String, int>{
      'total': todayResults.length,
      'scam': 0,
      'legitimate': 0,
      'suspicious': 0,
      'starred': 0,
    };

    for (final result in todayResults) {
      summary[result.label] = (summary[result.label] ?? 0) + 1;
      if (result.isStarred) {
        summary['starred'] = (summary['starred'] ?? 0) + 1;
      }
    }

    return summary;
  }

  /// Get weekly statistics
  Future<Map<String, dynamic>> getWeeklyStatistics() async {
    final weekResults = await getWeekResults();

    final dailyStats = <String, Map<String, int>>{};
    final methodStats = <String, int>{};
    final labelStats = <String, int>{};

    for (final result in weekResults) {
      final dateKey = result.createdAt.toIso8601String().split('T')[0];

      // Initialize daily stats for this date
      dailyStats.putIfAbsent(
          dateKey,
          () => {
                'total': 0,
                'scam': 0,
                'legitimate': 0,
                'suspicious': 0,
                'starred': 0,
              });

      // Update daily stats
      final dayStats = dailyStats[dateKey]!;
      dayStats['total'] = (dayStats['total'] ?? 0) + 1;
      dayStats[result.label] = (dayStats[result.label] ?? 0) + 1;
      if (result.isStarred) {
        dayStats['starred'] = (dayStats['starred'] ?? 0) + 1;
      }

      // Update method stats
      methodStats[result.detectionMethod] =
          (methodStats[result.detectionMethod] ?? 0) + 1;

      // Update label stats
      labelStats[result.label] = (labelStats[result.label] ?? 0) + 1;
    }

    return {
      'daily_stats': dailyStats,
      'method_stats': methodStats,
      'label_stats': labelStats,
      'total_results': weekResults.length,
    };
  }

  /// Clean up old results (older than specified days)
  Future<int> cleanupOldResults(int daysToKeep) async {
    try {
      return await _dbHelper.cleanupOldResults(daysToKeep);
    } catch (e) {
      debugPrint('Error cleaning up old results: $e');
      return 0;
    }
  }

  /// Export results to a list of maps (for sharing or backup)
  Future<List<Map<String, dynamic>>> exportResults({
    DateTime? startDate,
    DateTime? endDate,
    String? label,
  }) async {
    List<ScamResultDB> results;

    if (startDate != null && endDate != null) {
      results = await getResultsFromDateRange(startDate, endDate);
    } else if (label != null) {
      results = await getResultsByLabel(label);
    } else {
      results = await getAllResults();
    }

    return results.map((result) => result.toJson()).toList();
  }

  /// Get most common scam patterns
  Future<Map<String, int>> getMostCommonPatterns() async {
    try {
      final allResults = await getAllResults(limit: 1000);
      final patternCounts = <String, int>{};

      for (final result in allResults) {
        if (result.label == 'scam' || result.label == 'suspicious') {
          final reason = result.reason;
          patternCounts[reason] = (patternCounts[reason] ?? 0) + 1;
        }
      }

      // Sort by count and return top 10
      final sortedPatterns = patternCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedPatterns.take(10));
    } catch (e) {
      debugPrint('Error getting common patterns: $e');
      return {};
    }
  }

  /// Get sender statistics
  Future<Map<String, int>> getSenderStatistics() async {
    try {
      final allResults = await getAllResults(limit: 1000);
      final senderCounts = <String, int>{};

      for (final result in allResults) {
        final sender = result.sender;
        senderCounts[sender] = (senderCounts[sender] ?? 0) + 1;
      }

      // Sort by count and return top 20
      final sortedSenders = senderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedSenders.take(20));
    } catch (e) {
      debugPrint('Error getting sender statistics: $e');
      return {};
    }
  }
}
