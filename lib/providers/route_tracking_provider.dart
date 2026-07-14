import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/background/background_location_handler.dart';
import '../data/models/route_point_model.dart';
import '../data/services/route_tracking_service.dart';

const _bufferKey = 'route_point_buffer';

class RouteTrackingProvider extends ChangeNotifier {
  final RouteTrackingService _service;

  RouteTrackingProvider(this._service) {
    BackgroundLocationHandler.onFakeGpsDetected.listen((event) {
      _isTracking = false;
      _fakeGpsDetected = true;
      notifyListeners();
    });
  }

  bool _isTracking = false;
  bool _fakeGpsDetected = false;

  bool get isTracking => _isTracking;
  bool get fakeGpsDetected => _fakeGpsDetected;

  Future<void> checkInitialState() async {
    _isTracking = await BackgroundLocationHandler.isRunning();
    notifyListeners();
  }

  Future<void> startTracking(String userId) async {
    _fakeGpsDetected = false;
    await BackgroundLocationHandler.start(userId);
    _isTracking = true;
    notifyListeners();
  }

  Future<void> stopTracking(String userId) async {
    await BackgroundLocationHandler.stop(userId);
    _isTracking = false;
    notifyListeners();
  }

  Future<void> toggle(String userId) async {
    if (_isTracking) {
      await stopTracking(userId);
    } else {
      await startTracking(userId);
    }
  }

  void clearFakeGpsFlag() {
    _fakeGpsDetected = false;
    notifyListeners();
  }

  Future<void> uploadPendingPoints(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_bufferKey}_$userId';
    final raw = prefs.getStringList(key) ?? [];
    if (raw.isEmpty) return;

    try {
      final points = raw
          .map((e) => RoutePointModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
      await _service.submitPoints(userId: userId, points: points);
      await prefs.remove(key);
    } catch (_) {}
  }
}
