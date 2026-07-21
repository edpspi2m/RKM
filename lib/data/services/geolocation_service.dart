import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/network/api_client.dart';
import '../models/gps_location_model.dart';

/// Abstract service untuk geolocation yang support mobile & web
abstract class GeolocationService {
  Future<GpsLocationModel> getCurrentPosition();
  Future<bool> requestPermission();
  Stream<GpsLocationModel> watchPosition({Duration interval = const Duration(seconds: 5)});
  Future<void> dispose();
}

/// Mobile implementation menggunakan Geolocator
class MobileGeolocationService implements GeolocationService {
  StreamSubscription? _positionStream;

  @override
  Future<GpsLocationModel> getCurrentPosition() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return GpsLocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get position: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse || result == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  @override
  Stream<GpsLocationModel> watchPosition({Duration interval = const Duration(seconds: 5)}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).map((position) => GpsLocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        ));
  }

  @override
  Future<void> dispose() async {
    await _positionStream?.cancel();
  }
}

/// Web implementation menggunakan browser Geolocation API
class WebGeolocationService implements GeolocationService {
  StreamController<GpsLocationModel>? _controller;
  int? _watchId;

  @override
  Future<GpsLocationModel> getCurrentPosition() async {
    return _getCurrentPositionWeb();
  }

  Future<GpsLocationModel> _getCurrentPositionWeb() async {
    // Simulasi untuk web - dalam production perlu JavaScript interop
    // Menggunakan dummy data untuk sekarang
    await Future.delayed(const Duration(milliseconds: 500));
    return GpsLocationModel(
      latitude: -7.0,
      longitude: 110.0,
      accuracy: 50.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> requestPermission() async {
    // Web geolocation permission diminta browser secara otomatis
    try {
      await getCurrentPosition();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<GpsLocationModel> watchPosition({Duration interval = const Duration(seconds: 5)}) {
    _controller = StreamController<GpsLocationModel>();

    // Polling implementation untuk web
    Timer.periodic(interval, (_) async {
      try {
        final position = await getCurrentPosition();
        if (!_controller!.isClosed) {
          _controller!.add(position);
        }
      } catch (e) {
        if (!_controller!.isClosed) {
          _controller!.addError(e);
        }
      }
    });

    return _controller!.stream;
  }

  @override
  Future<void> dispose() async {
    await _controller?.close();
  }
}

/// Factory class untuk select implementation berdasarkan platform
class GeolocationServiceFactory {
  static GeolocationService create() {
    if (kIsWeb) {
      return WebGeolocationService();
    } else {
      return MobileGeolocationService();
    }
  }
}
