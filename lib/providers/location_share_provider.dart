import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/services/location_share_service.dart';

class LocationShareProvider extends ChangeNotifier {
  final LocationShareService _service;
  LocationShareProvider(this._service);

  bool _isSharing = false;
  Timer? _timer;
  String? _errorMessage;

  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;

  Future<void> startSharing(String userId) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _errorMessage = 'Izin lokasi ditolak.';
        notifyListeners();
        return;
      }
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    await _sendUpdate(userId);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _sendUpdate(userId));
  }

  Future<void> _sendUpdate(String userId) async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _service.updateLocation(userId: userId, lat: pos.latitude, lng: pos.longitude, isSharing: true);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopSharing(String userId) async {
    _timer?.cancel();
    _timer = null;
    _isSharing = false;
    notifyListeners();
    try {
      final pos = await Geolocator.getCurrentPosition();
      await _service.updateLocation(userId: userId, lat: pos.latitude, lng: pos.longitude, isSharing: false);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
