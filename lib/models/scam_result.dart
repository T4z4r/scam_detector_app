class ScamResult {
  final String label;
  final double confidence;
  final String reason;
  final String alert;

  ScamResult({
    required this.label,
    required this.confidence,
    required this.reason,
    required this.alert,
  });

  factory ScamResult.fromJson(Map<String, dynamic> json) {
    return ScamResult(
      label: json['result'],
      confidence:
          double.tryParse(json['confidence'].replaceAll('%', '')) ?? 0.0,
      reason: json['reason'],
      alert: json['alert'],
    );
  }
}
