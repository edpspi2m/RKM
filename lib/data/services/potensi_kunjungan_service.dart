import 'dart:io';
import '../../core/network/api_client.dart';
import '../models/gps_location_model.dart'; // Import model lokasi milik Anda

class PotensiKunjunganService {
  final ApiClient _apiClient;

  PotensiKunjunganService(this._apiClient);

  Future<void> kirim({
    required int potensiId,
    required String userId,
    required String catatan,
    required GpsLocationModel lokasi, // Ubah dari Position ke GpsLocationModel
    required File foto,
  }) async {
    final fields = {
      'potensi_id': potensiId.toString(),
      'user_id': userId,
      'catatan': catatan,
      'latitude': lokasi.latitude.toString(),
      'longitude': lokasi.longitude.toString(),
    };

    await _apiClient.postMultipart(
      '/potensi-kunjungan/potensi_kunjungan.php', // Sesuaikan endpoint API Anda
      fields: fields,
      file: foto, // Jika ApiClient menerima Map, ganti jadi: files: {'foto': foto}
    );
  }
}
