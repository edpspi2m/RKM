import 'package:safe_device/safe_device.dart';

class DeviceSecurityResult {
  final bool isSafe;
  final List<String> reasons;

  const DeviceSecurityResult({required this.isSafe, required this.reasons});
}

class DeviceSecurityService {
  Future<DeviceSecurityResult> check() async {
    final reasons = <String>[];

    final isJailBroken = await SafeDevice.isJailBroken;
    if (isJailBroken) reasons.add('Perangkat terdeteksi root/jailbreak.');

    final isRealDevice = await SafeDevice.isRealDevice;
    if (!isRealDevice) reasons.add('Aplikasi berjalan pada emulator, bukan perangkat asli.');

    final isOnExternalStorage = await SafeDevice.isOnExternalStorage;
    if (isOnExternalStorage) {
      reasons.add('Instalasi aplikasi di penyimpanan eksternal tidak diizinkan.');
    }

    return DeviceSecurityResult(isSafe: reasons.isEmpty, reasons: reasons);
  }
}
