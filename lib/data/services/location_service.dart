import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/gps_location_model.dart';

class LocationService {
  Future<GpsLocationModel> getCurrentValidatedLocation() async {
    // ====== Pastikan layanan lokasi & izin aktif ======
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi tidak aktif. Aktifkan GPS terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Aktifkan lewat pengaturan HP.');
    }

    // ====== Ambil posisi ======
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );

    // ====== Validasi ketat: tolak jika lokasi palsu ======
    // Pesan ini dirancang generik agar tidak menjelaskan mekanisme deteksi.
    if (pos.isMocked) {
      throw Exception('GPS tidak valid, coba lagi.');
    }

    // ====== Reverse geocode alamat (best-effort) ======
    String address = 'Lokasi terdeteksi';
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = [p.street, p.subLocality, p.locality]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');
        if (address.isEmpty) address = 'Lokasi terdeteksi';
      }
    } catch (_) {}

    return GpsLocationModel(
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: address,
      capturedAt: DateTime.now(),
      accuracy: pos.accuracy,
    );
  }
}
