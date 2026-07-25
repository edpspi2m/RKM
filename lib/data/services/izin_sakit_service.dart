import '../../core/network/api_client.dart';

class IzinSakitService {
  final ApiClient _apiClient;
  IzinSakitService(this._apiClient);

  Future<void> start({required String userId, required String jenis, required double lat, required double lng, required String keterangan}) async {
    final response = await _apiClient.post('/izin_sakit.php', body: {
      'user_id': userId, 'jenis': jenis, 'latitude': lat.toString(), 'longitude': lng.toString(), 'keterangan': keterangan, 'action': 'start',
    });
    if (response['success'] != true) {
      throw Exception(response['message']?.toString() ?? 'Server menolak permintaan (tidak diketahui alasannya)');
    }
  }

  Future<void> stop(String userId) async {
    final response = await _apiClient.post('/izin_sakit.php', body: {'user_id': userId, 'action': 'stop'});
    if (response['success'] != true) {
      throw Exception(response['message']?.toString() ?? 'Gagal menonaktifkan status');
    }
  }
}
