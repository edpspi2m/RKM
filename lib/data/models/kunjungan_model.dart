import 'gps_location_model.dart';

class KunjunganModel {
  final String userId;
  final String member;
  final String catatan;
  final GpsLocationModel lokasi;
  final String statusKunjungan;

  const KunjunganModel({
    required this.userId,
    required this.member,
    required this.catatan,
    required this.lokasi,
    this.statusKunjungan = 'berhasil',
  });

  Map<String, String> toFields() => {
        'user_id': userId,
        'member': member,
        'catatan': catatan,
        'latitude': lokasi.latitude.toString(),
        'longitude': lokasi.longitude.toString(),
        'timestamp': lokasi.capturedAt.toIso8601String(),
        'status_kunjungan': statusKunjungan,
      };
}
