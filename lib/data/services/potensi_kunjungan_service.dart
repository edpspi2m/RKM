import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../models/gps_location_model.dart';

class PotensiKunjunganService {
  final ApiClient _apiClient;
  PotensiKunjunganService(this._apiClient);

  Future<void> kirim({
    required int potensiId,
    required String userId,
    required String catatan,
    required GpsLocationModel lokasi,
    required File foto,
  }) async {
    await _apiClient.postMultipart(
      '/potensi_kunjungan.php',
      fields: {
        'potensi_id': potensiId.toString(),
        'user_id': userId,
        'catatan': catatan,
        'latitude': lokasi.latitude.toString(),
        'longitude': lokasi.longitude.toString(),
        'timestamp': lokasi.capturedAt.toIso8601String(),
      },
      file: foto,
      fileField: 'foto',
    );
  }
}
