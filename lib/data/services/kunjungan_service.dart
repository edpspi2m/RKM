import 'dart:io';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constant.dart';
import '../models/kunjungan_model.dart';

class KunjunganService {
  final ApiClient _apiClient;

  KunjunganService(this._apiClient);

  Future<void> submit({
    required KunjunganModel kunjungan,
    required File fotoWatermark,
  }) {
    return _apiClient.postMultipart(
      ApiConstant.submitKunjungan,
      fields: kunjungan.toFields(),
      file: fotoWatermark,
    );
  }
}
