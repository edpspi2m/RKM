import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/services/izin_sakit_service.dart';

class IzinStatusProvider extends ChangeNotifier {
  final IzinSakitService _service;
  IzinStatusProvider(this._service);

  String? _jenisAktif;
  bool _isLoading = false;
  String? _errorMessage;

  String? get jenisAktif => _jenisAktif;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> start({required String userId, required String jenis, required String keterangan}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final serviceStatus = await Geolocator.isLocationServiceEnabled();
      if (!serviceStatus) {
        _errorMessage = 'LANGKAH 1 GAGAL: GPS/Lokasi HP sedang mati. Nyalakan GPS di HP dulu.';
        _isLoading = false; notifyListeners();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Permission.locationWhenInUse.request();
        if (!requested.isGranted) {
          _errorMessage = 'LANGKAH 2 GAGAL: Izin lokasi ditolak. Buka Pengaturan HP > Aplikasi > RKM > Izin > aktifkan Lokasi.';
          _isLoading = false; notifyListeners();
          return false;
        }
        permission = await Geolocator.checkPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'LANGKAH 2 GAGAL: Izin lokasi ditolak permanen. Buka Pengaturan HP > Aplikasi > RKM > Izin, aktifkan manual.';
        _isLoading = false; notifyListeners();
        return false;
      }

      final Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 8));
      } catch (e) {
        _errorMessage = 'LANGKAH 3 GAGAL: Tidak bisa ambil koordinat GPS ($e). Coba di tempat terbuka (bukan dalam ruangan).';
        _isLoading = false; notifyListeners();
        return false;
      }

      try {
        await _service.start(userId: userId, jenis: jenis, lat: pos.latitude, lng: pos.longitude, keterangan: keterangan);
      } catch (e) {
        _errorMessage = 'LANGKAH 4 GAGAL (server menolak): $e';
        _isLoading = false; notifyListeners();
        return false;
      }

      _jenisAktif = jenis;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'ERROR TIDAK TERDUGA: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> stop(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.stop(userId);
      _jenisAktif = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menonaktifkan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
