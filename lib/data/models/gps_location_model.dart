class GpsLocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime capturedAt;

  const GpsLocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.capturedAt,
  });

  String get coordinateText => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'captured_at': capturedAt.toIso8601String(),
      };
}
