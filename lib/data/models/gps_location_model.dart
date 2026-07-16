class GpsLocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime capturedAt;
  final double? accuracy;

  const GpsLocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.capturedAt,
    this.accuracy,
  });

  String get coordinateText =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
