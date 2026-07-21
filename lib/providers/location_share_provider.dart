import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/services/location_share_service.dart';

// Import conditional - untuk web gunakan browser geolocation
// ignore: avoid_web_libraries_in_flutter
import '../data/services/browser_geolocation_service.dart'
    if (dart.library.html) '../data/services/browser_geolocation_service.dart';

class LocationShareProvider extends ChangeNotifier {
  final LocationShareService _service;
  
  LocationShareProvider(this._service);

  bool _isSharing = false;
  Timer? _timer;
  String? _errorMessage;
  bool _isLoading = false;
  double? _lastLatitude;
  double? _lastLongitude;

  bool get isSharing => _isSharing;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  double? get lastLatitude => _lastLatitude;
  double? get lastLongitude => _lastLongitude;

  /// Start sharing location - auto detect platform (mobile/web)
  Future<void> startSharing(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        await _startSharingWeb(userId);
      } else {
        await _startSharingMobile(userId);
      }

      _isSharing = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Mobile implementation - gunakan Geolocator plugin
  Future<void> _startSharingMobile(String userId) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Izin akses lokasi ditolak.');
      }
    }

    // Send initial position
    await _sendLocationUpdateMobile(userId);

    // Setup periodic updates - setiap 20 detik
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _sendLocationUpdateMobile(userId));
  }

  /// Web implementation - gunakan Browser Geolocation API dengan JS interop
  Future<void> _startSharingWeb(String userId) async {
    try {
      // Send initial position
      await _sendLocationUpdateWeb(userId);

      // Setup periodic updates - setiap 20 detik (untuk web gunakan polling)
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 20), (_) => _sendLocationUpdateWeb(userId));
    } catch (e) {
      throw Exception('Gagal memulai share lokasi di web: $e');
    }
  }

  /// Update lokasi dari mobile (Geolocator)
  Future<void> _sendLocationUpdateMobile(String userId) async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      _lastLatitude = pos.latitude;
      _lastLongitude = pos.longitude;

      await _service.updateLocation(
        userId: userId,
        lat: pos.latitude,
        lng: pos.longitude,
        isSharing: true,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error update lokasi mobile: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Update lokasi dari web (Browser Geolocation API)
  Future<void> _sendLocationUpdateWeb(String userId) async {
    try {
      // Pastikan browser geolocation service sudah available
      if (!kIsWeb) return;

      final positionData = await BrowserGeolocationService.getCurrentPosition();

      final latitude = positionData['latitude'] as double;
      final longitude = positionData['longitude'] as double;

      _lastLatitude = latitude;
      _lastLongitude = longitude;

      await _service.updateLocation(
        userId: userId,
        lat: latitude,
        lng: longitude,
        isSharing: true,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error update lokasi web: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Stop sharing location
  Future<void> stopSharing(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _timer?.cancel();
      _timer = null;

      // Send final update - isSharing = false
      try {
        if (kIsWeb) {
          final positionData = await BrowserGeolocationService.getCurrentPosition();
          await _service.updateLocation(
            userId: userId,
            lat: positionData['latitude'] as double,
            lng: positionData['longitude'] as double,
            isSharing: false,
          );
        } else {
          final pos = await Geolocator.getCurrentPosition();
          await _service.updateLocation(
            userId: userId,
            lat: pos.latitude,
            lng: pos.longitude,
            isSharing: false,
          );
        }
      } catch (_) {
        // Ignore error saat stop sharing
      }

      _isSharing = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error saat stop sharing: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get current status
  Map<String, dynamic> getStatus() {
    return {
      'isSharing': _isSharing,
      'isLoading': _isLoading,
      'lastLatitude': _lastLatitude,
      'lastLongitude': _lastLongitude,
      'errorMessage': _errorMessage,
      'platform': kIsWeb ? 'web' : 'mobile',
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (kIsWeb) {
      try {
        BrowserGeolocationService.clearWatch();
      } catch (_) {}
    }
    super.dispose();
  }
}
