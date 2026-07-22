import '../../core/network/api_client.dart';

class RiwayatService {
  final ApiClient _apiClient;
  RiwayatService(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchRiwayat(String userId) async {
    final response = await _apiClient.post('/riwayat.php', body: {'user_id': userId});
    final list = response['data'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchRiwayatAll(String userId) async {
    final response = await _apiClient.post('/riwayat_all.php', body: {'user_id': userId});
    final list = response['data'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
