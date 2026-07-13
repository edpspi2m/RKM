import '../../core/network/api_client.dart';

class LocationShareService {
  final ApiClient _apiClient;
  LocationShareService(this._apiClient);

  Future<void> updateLocation({
    required String userId,
    required double lat,
    required double lng,
    required bool isSharing,
  }) async {
    await _apiClient.post('/update_location.php', body: {
      'user_id': userId,
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'is_sharing': isSharing ? '1' : '0',
    });
  }
}
