import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/background/background_location_handler.dart';
import '../data/models/route_point_model.dart';
import '../data/services/route_tracking_service.dart';

class RouteTrackingProvider extends ChangeNotifier {
  final RouteTrackingService _service;

  RouteTrackingProvider(this._service) {
    BackgroundLocationHandler.onFakeGpsDetected.listen((event) {
      _fakeGpsDetected = true;
      notifyListeners();
    });
  }

  bool _isTracking = false;
  bool _isValidating = false;
  bool _fakeGpsDetected = false;
  Timer? _foregroundTimer;

  bool get isTracking => _isTracking;
  bool get isValidating => _isValidating;
  bool get fakeGpsDetected => _fakeGpsDetected;

  Future<void> _lockAccount(String userId, double lat, double lng, String ctx) async {
    try {
      await http.post(
        Uri.parse('https://api.isreport.my.id/absen/auto_lock_fake_gps.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'latitude': lat, 'longitude': lng, 'context': ctx}),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> checkInitialState() async {
    _isTracking = await BackgroundLocationHandler.isRunning();
    notifyListeners();
  }

  Future<void> _captureAndSendForeground(String userId) async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 12));
      if (pos.isMocked) {
        _fakeGpsDetected = true;
        notifyListeners();
        _lockAccount(userId, pos.latitude, pos.longitude, 'route_tracking');
        return;
      }
      await _service.submitPoints(userId: userId, points: [
        RoutePointModel(latitude: pos.latitude, longitude: pos.longitude, accuracy: pos.accuracy, capturedAt: DateTime.now()),
      ]);
    } catch (_) {
      // Log diam-diam tanpa mengganggu UI — tidak ditampilkan sebagai panel lagi.
    }
  }

  Future<bool> startTracking(String userId) async {
    _isValidating = true;
    notifyListeners();

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      if (pos.isMocked) {
        _isValidating = false;
        _fakeGpsDetected = true;
        notifyListeners();
        _lockAccount(userId, pos.latitude, pos.longitude, 'toggle_perjalanan');
        return false;
      }
    } catch (_) {
      _isValidating = false;
      notifyListeners();
      return false;
    }

    // JALUR 1: timer di dalam app (foreground) — paling andal selama app terbuka/baru diminimize.
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(seconds: 15), (_) => _captureAndSendForeground(userId));
    await _captureAndSendForeground(userId);

    // JALUR 2: background service — usaha terbaik supaya tetap jalan walau
    // aplikasi ditutup total. Tidak dijamin 100% di semua HP (tergantung
    // battery optimizer masing-masing merk), tapi tetap dicoba sebagai
    // jalur cadangan di samping jalur 1.
    await BackgroundLocationHandler.start(userId);

    _isTracking = true;
    _isValidating = false;
    notifyListeners();
    return true;
  }

  Future<void> stopTracking(String userId) async {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    await BackgroundLocationHandler.stop(userId);
    _isTracking = false;
    notifyListeners();
  }

  void clearFakeGpsFlag() {
    _fakeGpsDetected = false;
    notifyListeners();
  }

  Future<void> uploadPendingPoints(String userId) async {}

  @override
  void dispose() {
    _foregroundTimer?.cancel();
    super.dispose();
  }
}
