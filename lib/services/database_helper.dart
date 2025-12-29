import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scam_result_db.dart';

/// Database helper service for managing local SQLite database
/// Handles all database operations for scam detection results
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database with tables
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'scam_detector.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Main table for scam detection results
    await db.execute('''
      CREATE TABLE scam_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        confidence REAL NOT NULL,
        reason TEXT NOT NULL,
        alert TEXT NOT NULL,
        source_text TEXT NOT NULL,
        sender TEXT NOT NULL,
        detection_method TEXT NOT NULL DEFAULT 'local',
        is_starred INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_label ON scam_results(label)');
    await db.execute('CREATE INDEX idx_created_at ON scam_results(created_at)');
    await db.execute('CREATE INDEX idx_detection_method ON scam_results(detection_method)');
    await db.execute('CREATE INDEX idx_is_starred ON scam_results(is_starred)');
  }

  /// Insert a new scam detection result
  Future<int> insertScamResult(ScamResultDB result) async {
    final db = await database;
    return await db.insert('scam_results', result.toMap());
  }

  /// Get all scam detection results
  Future<List<ScamResultDB>> getAllScamResults({
    int limit = 50,
    int offset = 0,
    String? orderBy,
  }) async {
    final db = await database;
    
    final maps = await db.query(
      'scam_results',
      orderBy: orderBy ?? 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => ScamResultDB.fromMap(maps[i]));
  }

  /// Get scam results by label (scam, legitimate, suspicious)
  Future<List<ScamResultDB>> getScamResultsByLabel(
    String label, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    
    final maps = await db.query(
      'scam_results',
      where: 'label = ?',
      whereArgs: [label],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => ScamResultDB.fromMap(maps[i]));
  }

  /// Get scam results by detection method
  Future<List<ScamResultDB>> getScamResultsByMethod(
    String method, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    
    final maps = await db.query(
      'scam_results',
      where: 'detection_method = ?',
      whereArgs: [method],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => ScamResultDB.fromMap(maps[i]));
  }

  /// Get starred scam results
  Future<List<ScamResultDB>> getStarredScamResults({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    
    final maps = await db.query(
      'scam_results',
      where: 'is_starred = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => ScamResultDB.fromMap(maps[i]));
  }

  /// Search scam results by text content
  Future<List<ScamResultDB>> searchScamResults(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    
    final maps = await db.query(
      'scam_results',
      where: 'source_text LIKE ? OR sender LIKE ? OR reason LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => ScamResultDB.fromMap(maps[i]));
  }

  /// Get scam results from date range
  Future<List<ScamResultDB>> getScamResultsFromDate(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    
    final maps = await db.query(
      'scam_results',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => ScamResultDB.fromMap(maps[i]));
  }

  /// Get a single scam result by ID
  Future<ScamResultDB?> getScamResultById(int id) async {
    final db = await database;
    
    final maps = await db.query(
      'scam_results',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ScamResultDB.fromMap(maps.first);
    }
    return null;
  }

  /// Update a scam result
  Future<int> updateScamResult(ScamResultDB result) async {
    final db = await database;
    
    final updatedResult = result.copyWith(updatedAt: DateTime.now());
    
    return await db.update(
      'scam_results',
      updatedResult.toMap(),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  /// Toggle star status of a scam result
  Future<int> toggleStarStatus(int id) async {
    final db = await database;
    
    // First get the current star status
    final currentResult = await getScamResultById(id);
    if (currentResult == null) return 0;
    
    final newStarStatus = !currentResult.isStarred;
    
    return await db.update(
      'scam_results',
      {'is_starred': newStarStatus ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a scam result
  Future<int> deleteScamResult(int id) async {
    final db = await database;
    return await db.delete(
      'scam_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all scam results
  Future<int> deleteAllScamResults() async {
    final db = await database;
    return await db.delete('scam_results');
  }

  /// Get statistics about stored results
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    // Get counts by label
    final labelCounts = await db.rawQuery('''
      SELECT label, COUNT(*) as count 
      FROM scam_results 
      GROUP BY label
    ''');
    
    // Get counts by detection method
    final methodCounts = await db.rawQuery('''
      SELECT detection_method, COUNT(*) as count 
      FROM scam_results 
      GROUP BY detection_method
    ''');
    
    // Get total count and starred count
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM scam_results');
    final starredResult = await db.rawQuery('SELECT COUNT(*) as starred FROM scam_results WHERE is_starred = 1');
    
    // Get average confidence score
    final avgConfidenceResult = await db.rawQuery('SELECT AVG(confidence) as avg_confidence FROM scam_results');
    
    return {
      'total_results': totalResult.first['total'] as int,
      'starred_results': starredResult.first['starred'] as int,
      'by_label': Map.fromEntries(labelCounts.map((e) => MapEntry(e['label'] as String, e['count'] as int))),
      'by_method': Map.fromEntries(methodCounts.map((e) => MapEntry(e['detection_method'] as String, e['count'] as int))),
      'average_confidence': (avgConfidenceResult.first['avg_confidence'] as double?)?.toStringAsFixed(2) ?? '0.00',
    };
  }

  /// Clean up old results (older than specified days)
  Future<int> cleanupOldResults(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      'scam_results',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}