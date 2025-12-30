class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
      errors: json['errors'],
    );
  }

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
}

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
      label: json['result'] ?? json['label'] ?? '',
      confidence: _parseConfidence(json['confidence']),
      reason: json['reason'] ?? '',
      alert: json['alert'] ?? '',
    );
  }

  static double _parseConfidence(dynamic confidence) {
    if (confidence is double) return confidence;
    if (confidence is int) return confidence.toDouble();
    if (confidence is String) {
      // Handle percentage format "85%" or decimal format "0.85"
      final parsed = double.tryParse(confidence.replaceAll('%', ''));
      if (parsed != null) {
        return parsed > 1.0 ? parsed : parsed * 100.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'result': label,
      'confidence': confidence,
      'reason': reason,
      'alert': alert,
    };
  }
}

// Training related models
class TrainingStatus {
  final bool isTraining;
  final String? currentEpoch;
  final String? progress;
  final String? modelVersion;
  final String? lastTrained;

  TrainingStatus({
    required this.isTraining,
    this.currentEpoch,
    this.progress,
    this.modelVersion,
    this.lastTrained,
  });

  factory TrainingStatus.fromJson(Map<String, dynamic> json) {
    return TrainingStatus(
      isTraining: json['is_training'] ?? false,
      currentEpoch: json['current_epoch']?.toString(),
      progress: json['progress'],
      modelVersion: json['model_version'],
      lastTrained: json['last_trained'],
    );
  }
}

class TrainingData {
  final int totalSamples;
  final int scamSamples;
  final int legitimateSamples;
  final List<String> sampleTexts;

  TrainingData({
    required this.totalSamples,
    required this.scamSamples,
    required this.legitimateSamples,
    required this.sampleTexts,
  });

  factory TrainingData.fromJson(Map<String, dynamic> json) {
    return TrainingData(
      totalSamples: json['total_samples'] ?? 0,
      scamSamples: json['scam_samples'] ?? 0,
      legitimateSamples: json['legitimate_samples'] ?? 0,
      sampleTexts: List<String>.from(json['sample_texts'] ?? []),
    );
  }
}

class ModelMetrics {
  final double accuracy;
  final double precision;
  final double recall;
  final double f1Score;
  final Map<String, double> categoryMetrics;

  ModelMetrics({
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.categoryMetrics,
  });

  factory ModelMetrics.fromJson(Map<String, dynamic> json) {
    return ModelMetrics(
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      precision: (json['precision'] ?? 0.0).toDouble(),
      recall: (json['recall'] ?? 0.0).toDouble(),
      f1Score: (json['f1_score'] ?? 0.0).toDouble(),
      categoryMetrics: Map<String, double>.from(json['category_metrics'] ?? {}),
    );
  }
}
