import 'gps_location_model.dart';

class KunjunganModel {
  final String namaToko;
  final String catatan;
  final GpsLocationModel lokasi;
  final String fotoPath;
  final String username;

  const KunjunganModel({
    required this.namaToko,
    required this.catatan,
    required this.lokasi,
    required this.fotoPath,
    required this.username,
  });

  Map<String, String> toFields() => {
        'username': username,
        'nama_toko': namaToko,
        'catatan': catatan,
        'latitude': lokasi.latitude.toString(),
        'longitude': lokasi.longitude.toString(),
        'alamat': lokasi.address,
        'waktu_kunjungan': lokasi.capturedAt.toIso8601String(),
      };
}
