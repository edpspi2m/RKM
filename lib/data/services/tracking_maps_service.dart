import '../../core/network/api_client.dart';
import '../../core/constants/api_constant.dart';

class TrackingMapsService {
  final ApiClient _apiClient;
  TrackingMapsService(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchLiveLocations(String userId) async {
    final response = await _apiClient.post(ApiConstant.liveLocations, body: {'user_id': userId});
    final list = response['data'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
