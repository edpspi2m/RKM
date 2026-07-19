import '../../core/network/api_client.dart';

class IzinSakitService {
  final ApiClient _apiClient;
  IzinSakitService(this._apiClient);

  Future<void> start({required String userId, required String jenis, required double lat, required double lng}) async {
    await _apiClient.post('/izin_sakit.php', body: {
      'user_id': userId, 'jenis': jenis, 'latitude': lat.toString(), 'longitude': lng.toString(), 'action': 'start',
    });
  }

  Future<void> stop(String userId) async {
    await _apiClient.post('/izin_sakit.php', body: {'user_id': userId, 'action': 'stop'});
  }
}
