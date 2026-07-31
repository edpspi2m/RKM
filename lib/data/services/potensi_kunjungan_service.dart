import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../../core/network/api_client.dart';

class PotensiKunjunganService {
  final ApiClient _apiClient;

  PotensiKunjunganService(this._apiClient);

  Future<void> kirim({
    required int potensiId,
    required String userId,
    required String catatan,
    required Position lokasi,
    required File foto,
  }) async {
    final fields = {
      'potensi_id': potensiId.toString(),
      'user_id': userId,
      'catatan': catatan,
      'latitude': lokasi.latitude.toString(),
      'longitude': lokasi.longitude.toString(),
    };

    // Hapus parameter `fileField: 'foto'` yang tidak ada di ApiClient
    await _apiClient.postMultipart(
      '/potensi-kunjungan', // Sesuaikan dengan endpoint API Anda
      fields: fields,
      file: foto,
    );
  }
}
