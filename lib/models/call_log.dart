class CallLogEntry {
  final String phoneNumber;
  final String callerName;
  final DateTime callDate;
  final int duration; // in seconds
  final CallType callType;
  final bool isScamSuspected;

  CallLogEntry({
    required this.phoneNumber,
    required this.callerName,
    required this.callDate,
    required this.duration,
    required this.callType,
    this.isScamSuspected = false,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'callerName': callerName,
      'callDate': callDate.millisecondsSinceEpoch,
      'duration': duration,
      'callType': callType.index,
      'isScamSuspected': isScamSuspected,
    };
  }

  // Create from JSON
  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    return CallLogEntry(
      phoneNumber: json['phoneNumber'] ?? '',
      callerName: json['callerName'] ?? '',
      callDate: DateTime.fromMillisecondsSinceEpoch(json['callDate'] ?? 0),
      duration: json['duration'] ?? 0,
      callType: CallType.values[json['callType'] ?? 0],
      isScamSuspected: json['isScamSuspected'] ?? false,
    );
  }

  // Format duration as human-readable string
  String get formattedDuration {
    if (duration < 60) {
      return '${duration}s';
    } else if (duration < 3600) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = duration ~/ 3600;
      final minutes = (duration % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  // Get call type display name
  String get callTypeDisplayName {
    switch (callType) {
      case CallType.incoming:
        return 'Incoming';
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.missed:
        return 'Missed';
    }
  }

  // Get call type icon
  String get callTypeIcon {
    switch (callType) {
      case CallType.incoming:
        return '📞';
      case CallType.outgoing:
        return '📱';
      case CallType.missed:
        return '❌';
    }
  }

  @override
  String toString() {
    return 'CallLogEntry(phoneNumber: $phoneNumber, callerName: $callerName, callDate: $callDate, duration: $duration, callType: $callType)';
  }
}

enum CallType {
  incoming,
  outgoing,
  missed,
}