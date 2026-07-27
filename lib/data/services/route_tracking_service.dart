import '../../core/network/api_client.dart';
import '../../core/constants/api_constant.dart';
import '../models/route_point_model.dart';

class RouteTrackingService {
  final ApiClient _apiClient;
  RouteTrackingService(this._apiClient);

  Future<void> submitPoints({required String userId, required List<RoutePointModel> points}) async {
    if (points.isEmpty) return;
    await _apiClient.post(ApiConstant.routeTrack, body: {
      'user_id': userId,
      'points': points.map((p) => p.toJson()).toList(),
    });
  }

  Future<void> reportFakeGps({required String userId, required double lat, required double lng, required String context}) async {
    try {
      await _apiClient.post('/report_fake_gps.php', body: {'user_id': userId, 'latitude': lat.toString(), 'longitude': lng.toString(), 'context': context});
    } catch (_) {}
  }
}
