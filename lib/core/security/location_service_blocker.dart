import 'package:geolocator/geolocator.dart';

class LocationServiceBlocker {
  /// Memeriksa status GPS, Izin, dan Proteksi Fake GPS (Mock Location)
  static Future<Map<String, dynamic>> checkAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek Service GPS HP
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return {
        'isValid': false,
        'message': 'GPS HP belum aktif. Silakan nyalakan GPS terlebih dahulu.',
        'position': null,
      };
    }

    // 2. Cek Izin Akses Lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {
          'isValid': false,
          'message': 'Izin lokasi ditolak. Aplikasi RKM membutuhkan izin GPS untuk Check-In.',
          'position': null,
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return {
        'isValid': false,
        'message': 'Izin lokasi ditolak permanen. Buka Pengaturan HP untuk mengizinkan lokasi.',
        'position': null,
      };
    }

    // 3. Ambil Koordinat HP (High Accuracy)
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4. Deteksi Fake GPS / Mock Location dari OS Android/iOS
    if (position.isMocked) {
      return {
        'isValid': false,
        'message': 'DETEKSI LOKASI PALSU! Terdeteksi penggunaan Fake GPS / Mock Location.',
        'position': position,
      };
    }

    return {
      'isValid': true,
      'message': 'Lokasi valid.',
      'position': position,
    };
  }
}
