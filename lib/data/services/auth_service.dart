import '../../core/network/api_client.dart';
import '../../core/constants/api_constant.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<UserModel> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      ApiConstant.login,
      body: {'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Format respons login tidak valid.');
    }

    return UserModel.fromJson(data);
  }
}
