import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/services/izin_sakit_service.dart';

class IzinStatusProvider extends ChangeNotifier {
  final IzinSakitService _service;
  IzinStatusProvider(this._service);

  String? _jenisAktif;
  String? get jenisAktif => _jenisAktif;

  Future<void> start({required String userId, required String jenis, required String keterangan}) async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      await _service.start(userId: userId, jenis: jenis, lat: pos.latitude, lng: pos.longitude, keterangan: keterangan);
      _jenisAktif = jenis;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> stop(String userId) async {
    await _service.stop(userId);
    _jenisAktif = null;
    notifyListeners();
  }
}
