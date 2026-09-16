import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/background/background_location_handler.dart';
import '../core/constants/api_constant.dart';
import '../data/services/route_tracking_service.dart';

class RouteTrackingProvider extends ChangeNotifier {
  final RouteTrackingService _service;

  RouteTrackingProvider(this._service);

  StreamSubscription? _fakeGpsSub;
  bool _listenersInitialized = false;

  bool _isTracking       = false;
  bool _isValidating     = false;
  bool _fakeGpsDetected  = false;

  bool get isTracking      => _isTracking;
  bool get isValidating    => _isValidating;
  bool get fakeGpsDetected => _fakeGpsDetected;

  /// Panggil manual — jangan di constructor
  void initListeners() {
    if (_listenersInitialized) return;
    _listenersInitialized = true;
    try {
      _fakeGpsSub = BackgroundLocationHandler.onFakeGpsDetected.listen((event) {
        _fakeGpsDetected = true;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('⚠️ Fake GPS listener gagal: $e');
    }
  }

  Future<void> checkInitialState() async {
    try {
      _isTracking = await BackgroundLocationHandler.isRunning();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ checkInitialState gagal: $e');
    }
  }

  Future<void> _lockAccount(String userId, double lat, double lng, String ctx) async {
    try {
      await http.post(
        Uri.parse('${ApiConstant.baseUrl}${ApiConstant.autoLockFakeGps}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'latitude': lat,
          'longitude': lng,
          'context': ctx,
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<bool> startTracking(String userId) async {
    _isValidating = true;
    notifyListeners();

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
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

    // ✅ INIT DI SINI (lazy) — bukan di main.dart
    await BackgroundLocationHandler.initialize();
    await BackgroundLocationHandler.start(userId);

    // ✅ Baru listen setelah service jalan
    initListeners();

    _isTracking = true;
    _isValidating = false;
    notifyListeners();
    return true;
  }

  Future<void> stopTracking(String userId) async {
    await BackgroundLocationHandler.stop(userId);
    _isTracking = false;
    notifyListeners();
  }

  void clearFakeGpsFlag() {
    _fakeGpsDetected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _fakeGpsSub?.cancel();
    super.dispose();
  }
}
