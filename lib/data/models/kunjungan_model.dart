import 'gps_location_model.dart';

class KunjunganModel {
  final String userId;
  final String member;
  final String catatan;
  final GpsLocationModel lokasi;
  final String statusKunjungan;
  final String kelurahan;
  final String kecamatan;
  final String kota;

  const KunjunganModel({
    required this.userId, required this.member, required this.catatan, required this.lokasi,
    this.statusKunjungan = 'berhasil', this.kelurahan = '', this.kecamatan = '', this.kota = '',
  });

  Map<String, String> toFields() => {
    'user_id': userId, 'member': member, 'catatan': catatan,
    'latitude': lokasi.latitude.toString(), 'longitude': lokasi.longitude.toString(),
    'timestamp': lokasi.capturedAt.toIso8601String(), 'status_kunjungan': statusKunjungan,
    if (kelurahan.isNotEmpty) 'kelurahan': kelurahan,
    if (kecamatan.isNotEmpty) 'kecamatan': kecamatan,
    if (kota.isNotEmpty) 'kota': kota,
  };
}
