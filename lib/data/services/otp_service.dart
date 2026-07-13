import '../../core/network/api_client.dart';
import '../../core/constants/api_constant.dart';
import '../models/user_model.dart';

class OtpService {
  final ApiClient _apiClient;
  OtpService(this._apiClient);

  Future<void> requestOtp({required String username, required String password}) async {
    final response = await _apiClient.post(
      ApiConstant.otpRequest,
      body: {'username': username, 'password': password},
    );
    final success = response['success'] == true;
    if (!success) {
      throw Exception(response['message']?.toString() ?? 'Gagal meminta OTP.');
    }
  }

  Future<UserModel> verifyOtp({required String username, required String otp}) async {
    final response = await _apiClient.post(
      ApiConstant.otpVerify,
      body: {'username': username, 'otp': otp},
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception(response['message']?.toString() ?? 'OTP tidak valid atau sudah kedaluwarsa.');
    }
    return UserModel.fromJson(data);
  }
}
