import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
    if (pos.isMocked) {
      await _reportFakeGps(pos, 'foto_kunjungan');
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

  /// Kirim laporan fake GPS ke server (diteruskan ke Telegram).
  /// Best-effort — tidak boleh menghambat/menggagalkan alur utama app kalau
  /// gagal kirim (misal tidak ada internet).
  Future<void> _reportFakeGps(Position pos, String context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final nama = prefs.getString('nama') ?? '';
      if (userId.isEmpty) return;

      await http
          .post(
            Uri.parse('https://api.isreport.my.id/absen/report_fake_gps.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'nama_sales': nama,
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Diamkan — laporan gagal tidak boleh mengganggu alur utama.
    }
  }
}
