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
      // FIX: minta izin lokasi secara eksplisit dulu — sebelumnya kalau
      // izin belum lengkap, Geolocator langsung throw dan error itu
      // ditelan diam-diam tanpa pesan apa pun ke sales.
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Permission.locationWhenInUse.request();
        if (!requested.isGranted) {
          _errorMessage = 'Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan HP untuk menggunakan fitur ini.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Izin lokasi ditolak permanen. Buka Pengaturan HP > Aplikasi > RKM > Izin, aktifkan Lokasi.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 12));
      await _service.start(userId: userId, jenis: jenis, lat: pos.latitude, lng: pos.longitude, keterangan: keterangan);
      _jenisAktif = jenis;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengaktifkan: ${e.toString()}';
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
      _errorMessage = 'Gagal menonaktifkan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
