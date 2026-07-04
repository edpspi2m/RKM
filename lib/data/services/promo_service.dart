import '../../core/network/api_client.dart';
import '../../core/constants/api_constant.dart';
import '../models/promo_model.dart';

class PromoService {
  final ApiClient _apiClient;
  PromoService(this._apiClient);

  Future<List<PromoModel>> fetchPromo() async {
    final response = await _apiClient.post(ApiConstant.promo, body: {});
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => PromoModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
