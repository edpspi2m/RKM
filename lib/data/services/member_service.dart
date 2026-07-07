import '../../core/network/api_client.dart';
import '../models/member_model.dart';

class MemberService {
  final ApiClient _apiClient;
  MemberService(this._apiClient);

  Future<List<MemberModel>> fetchMembers(String userId) async {
    final response = await _apiClient.post('/members_list.php', body: {'user_id': userId});
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => MemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
