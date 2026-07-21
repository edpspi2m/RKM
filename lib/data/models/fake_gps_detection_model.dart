class FakeGpsDetectionModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime detectedAt;
  final String detectionType; // 'mocked', 'speed_anomaly', 'accuracy_issue'
  final String? description;
  final bool reported;
  final DateTime? reportedAt;

  const FakeGpsDetectionModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.detectedAt,
    required this.detectionType,
    this.description,
    this.reported = false,
    this.reportedAt,
  });

  factory FakeGpsDetectionModel.fromJson(Map<String, dynamic> json) {
    return FakeGpsDetectionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detected_at'] as String),
      detectionType: json['detection_type'] as String,
      description: json['description'] as String?,
      reported: json['reported'] as bool? ?? false,
      reportedAt: json['reported_at'] != null ? DateTime.parse(json['reported_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'detected_at': detectedAt.toIso8601String(),
        'detection_type': detectionType,
        'description': description,
        'reported': reported,
        'reported_at': reportedAt?.toIso8601String(),
      };
}
