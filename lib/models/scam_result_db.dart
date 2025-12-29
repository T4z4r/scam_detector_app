import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'scam_result.dart';

/// Database model for storing scam detection results
/// Extends the base ScamResult with database-specific fields
class ScamResultDB extends ScamResult {
  final int? id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sourceText;
  final String sender;
  final String detectionMethod; // 'local', 'api', 'hybrid'
  final bool isStarred; // User can star important results

  ScamResultDB({
    this.id,
    required String label,
    required double confidence,
    required String reason,
    required String alert,
    required this.sourceText,
    required this.sender,
    required this.detectionMethod,
    this.isStarred = false,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
          label: label,
          confidence: confidence,
          reason: reason,
          alert: alert,
        );

  /// Create ScamResultDB from database map
  factory ScamResultDB.fromMap(Map<String, dynamic> map) {
    return ScamResultDB(
      id: map['id'],
      label: map['label'],
      confidence: map['confidence'].toDouble(),
      reason: map['reason'],
      alert: map['alert'],
      sourceText: map['source_text'],
      sender: map['sender'],
      detectionMethod: map['detection_method'],
      isStarred: map['is_starred'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Convert ScamResultDB to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'reason': reason,
      'alert': alert,
      'source_text': sourceText,
      'sender': sender,
      'detection_method': detectionMethod,
      'is_starred': isStarred ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create ScamResultDB from base ScamResult
  factory ScamResultDB.fromScamResult(
    ScamResult result,
    String sourceText,
    String sender, {
    String detectionMethod = 'local',
    int? id,
    bool isStarred = false,
  }) {
    final now = DateTime.now();
    return ScamResultDB(
      id: id,
      label: result.label,
      confidence: result.confidence,
      reason: result.reason,
      alert: result.alert,
      sourceText: sourceText,
      sender: sender,
      detectionMethod: detectionMethod,
      isStarred: isStarred,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a copy with updated fields
  ScamResultDB copyWith({
    int? id,
    String? label,
    double? confidence,
    String? reason,
    String? alert,
    String? sourceText,
    String? sender,
    String? detectionMethod,
    bool? isStarred,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScamResultDB(
      id: id ?? this.id,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      alert: alert ?? this.alert,
      sourceText: sourceText ?? this.sourceText,
      sender: sender ?? this.sender,
      detectionMethod: detectionMethod ?? this.detectionMethod,
      isStarred: isStarred ?? this.isStarred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ScamResultDB{id: $id, label: $label, confidence: $confidence, reason: $reason, sender: $sender, detectionMethod: $detectionMethod}';
  }

  /// Convert to JSON (for API calls if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'reason': reason,
      'alert': alert,
      'sourceText': sourceText,
      'sender': sender,
      'detectionMethod': detectionMethod,
      'isStarred': isStarred,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ScamResultDB.fromJson(Map<String, dynamic> source) =>
      ScamResultDB.fromMap(source);
}