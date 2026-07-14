class RoutePointModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime capturedAt;

  const RoutePointModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.capturedAt,
  });

  factory RoutePointModel.fromJson(Map<String, dynamic> json) {
    return RoutePointModel(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      accuracy: json['acc'] != null ? (json['acc'] as num).toDouble() : null,
      capturedAt: DateTime.parse(json['ts'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        if (accuracy != null) 'acc': accuracy,
        'ts': capturedAt.toIso8601String(),
      };
}
