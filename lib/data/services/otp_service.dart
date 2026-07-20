import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constant.dart';
import '../models/user_model.dart';

class OtpService {
  final ApiClient _apiClient;
  OtpService(this._apiClient);

  Future<void> requestOtp({required String username, required String password}) async {
    final response = await _apiClient.post(ApiConstant.otpRequest, body: {'username': username, 'password': password});
    if (response['success'] != true) throw Exception(response['message']?.toString() ?? 'Gagal meminta OTP.');
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    // ID unik dibuat sendiri (persisten), TIDAK bergantung pada properti Android
    // yang kadang kosong di beberapa merk HP (Xiaomi/Oppo dll).
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_uuid');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = DateTime.now().microsecondsSinceEpoch.toString() + (1000 + DateTime.now().millisecond).toString();
      await prefs.setString('device_uuid', deviceId);
    }

    String model = 'Unknown Device';
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      model = '${info.brand} ${info.model}';
    } catch (_) {}

    return {'device_id': deviceId, 'device_model': model};
  }

  Future<UserModel> verifyOtp({required String username, required String otp}) async {
    final deviceInfo = await _getDeviceInfo();
    final response = await _apiClient.post(ApiConstant.otpVerify, body: {
      'username': username, 'otp': otp,
      'device_id': deviceInfo['device_id'], 'device_model': deviceInfo['device_model'],
    });
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception(response['message']?.toString() ?? 'OTP tidak valid.');
    return UserModel.fromJson(data);
  }
}
