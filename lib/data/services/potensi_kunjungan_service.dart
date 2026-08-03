import 'dart:io';
import '../../core/network/api_client.dart';
import '../../models/gps_location_model.dart';

class PotensiKunjunganService {
  final ApiClient apiClient; // Tanpa underscore agar sesuai

  PotensiKunjunganService(this.apiClient);

  Future<void> kirim({
    required int potensiId,
    required String userId,
    required String catatan,
    required GpsLocationModel lokasi,
    required File foto,
  }) async {
    final fields = {
      'potensi_id': potensiId.toString(),
      'user_id': userId,
      'catatan': catatan,
      'latitude': lokasi.latitude.toString(),
      'longitude': lokasi.longitude.toString(),
    };

    await apiClient.postMultipart(
      '/absen/potensi_kunjungan.php', 
      fields: fields,
      file: foto,
    );
  }
}
