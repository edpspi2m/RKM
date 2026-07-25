import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/widgets/fake_gps_dialog.dart';
import '../data/models/route_point_model.dart';
import '../data/services/route_tracking_service.dart';

class RouteTrackingProvider extends ChangeNotifier {
  final RouteTrackingService _service;
  RouteTrackingProvider(this._service);

  bool _isTracking = false;
  bool _isValidating = false;
  bool _fakeGpsDetected = false;
  Timer? _timer;
  Map<String, dynamic>? _debugStatus;
  int _successCount = 0;
  int _failCount = 0;

  bool get isTracking => _isTracking;
  bool get isValidating => _isValidating;
  bool get fakeGpsDetected => _fakeGpsDetected;
  Map<String, dynamic>? get debugStatus => _debugStatus;
  int get successCount => _successCount;
  int get failCount => _failCount;

  Future<void> checkInitialState() async {
    // Sekarang status "tracking" murni disimpan di memori provider (foreground),
    // jadi tidak perlu cek service eksternal lagi.
    notifyListeners();
  }

  Future<void> refreshDebugStatus(String userId) async {
    notifyListeners();
  }

  Future<bool> _captureAndSend(String userId) async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 12));

      if (pos.isMocked) {
        _debugStatus = {'lat': pos.latitude, 'lng': pos.longitude, 'is_mocked': true, 'sent_ok': false, 'error': 'Lokasi terdeteksi mocked, titik dilewati.', 'written_at': DateTime.now().toIso8601String()};
        _fakeGpsDetected = true;
        _service.reportFakeGps(userId: userId, lat: pos.latitude, lng: pos.longitude, context: 'route_tracking');
        notifyListeners();
        return false;
      }

      await _service.submitPoints(userId: userId, points: [
        RoutePointModel(latitude: pos.latitude, longitude: pos.longitude, accuracy: pos.accuracy, capturedAt: DateTime.now()),
      ]);

      _successCount++;
      _debugStatus = {'lat': pos.latitude, 'lng': pos.longitude, 'is_mocked': false, 'sent_ok': true, 'error': null, 'written_at': DateTime.now().toIso8601String()};
      notifyListeners();
      return true;
    } catch (e) {
      _failCount++;
      _debugStatus = {'lat': null, 'lng': null, 'is_mocked': false, 'sent_ok': false, 'error': e.toString(), 'written_at': DateTime.now().toIso8601String()};
      notifyListeners();
      return false;
    }
  }

  Future<bool> startTracking(String userId) async {
    _isValidating = true;
    notifyListeners();

    final firstOk = await _captureAndSend(userId);
    _isValidating = false;

    if (!firstOk && _fakeGpsDetected) {
      notifyListeners();
      return false;
    }

    _isTracking = true;
    _successCount = firstOk ? 1 : 0;
    _failCount = firstOk ? 0 : 1;
    notifyListeners();

    // Timer FOREGROUND — jalan selama app terbuka/di-background baru-baru ini.
    // Ini pengganti flutter_background_service yang terbukti tidak stabil.
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_fakeGpsDetected) return; // sudah dihentikan karena fake GPS
      await _captureAndSend(userId);
    });

    return true;
  }

  Future<void> stopTracking(String userId) async {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
    notifyListeners();
  }

  void clearFakeGpsFlag() {
    _fakeGpsDetected = false;
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  Future<void> uploadPendingPoints(String userId) async {
    // Tidak diperlukan lagi karena tidak ada buffer offline di pendekatan baru ini.
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
