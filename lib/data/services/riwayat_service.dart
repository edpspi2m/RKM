import '../../core/network/api_client.dart';

class RiwayatService {
  final ApiClient _apiClient;
  RiwayatService(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchRiwayat(String username) async {
    final response = await _apiClient.post(
      '/riwayat.php',
      body: {'username': username},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
