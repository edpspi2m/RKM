import 'dart:io';
import '../../core/network/api_client.dart';

class PotensiKunjunganService {
  final ApiClient apiClient;

  PotensiKunjunganService(this.apiClient);

  Future<void> kirim({
    required int potensiId,
    required String userId,
    required String catatan,
    required double latitude,
    required double longitude,
    required File foto,
  }) async {
    final fields = {
      'potensi_id': potensiId.toString(),
      'user_id': userId,
      'catatan': catatan,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    await apiClient.postMultipart(
      '/absen/potensi_kunjungan.php', 
      fields: fields,
      file: foto,
    );
  }
}
