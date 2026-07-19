import 'package:device_info_plus/device_info_plus.dart';
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

  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'device_id': androidInfo.id,
        'device_model': '${androidInfo.brand} ${androidInfo.model}',
      };
    } catch (_) {
      return {'device_id': '', 'device_model': 'Unknown Device'};
    }
  }

  Future<UserModel> verifyOtp({required String username, required String otp}) async {
    final deviceInfo = await _getDeviceInfo();

    final response = await _apiClient.post(
      ApiConstant.otpVerify,
      body: {
        'username': username,
        'otp': otp,
        'device_id': deviceInfo['device_id'],
        'device_model': deviceInfo['device_model'],
      },
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception(response['message']?.toString() ?? 'OTP tidak valid atau sudah kedaluwarsa.');
    }
    return UserModel.fromJson(data);
  }
}
