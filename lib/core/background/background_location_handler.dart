import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constant.dart';

const _bufferKey = 'route_point_buffer';
const _notifChannelId = 'rkm_location_tracking';
const _notifId = 889;

class BackgroundLocationHandler {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notifChannelId,
        initialNotificationTitle: 'RKM — Tracking Rute',
        initialNotificationContent: 'Merekam perjalanan kunjungan...',
        foregroundServiceNotificationId: _notifId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> start(String userId) async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    service.invoke('startTracking', {'user_id': userId});
  }

  static Future<void> stop(String userId) async {
    final service = FlutterBackgroundService();
    service.invoke('stopTracking', {'user_id': userId});
  }

  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();

  static Stream<Map<String, dynamic>?> get onFakeGpsDetected =>
      FlutterBackgroundService().on('fakeGpsDetected');
}

double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer? locationTimer;
  String currentUserId = '';
  Position? lastValidPosition;

  service.on('startTracking').listen((data) async {
    currentUserId = data?['user_id'] as String? ?? '';
    lastValidPosition = null;
    locationTimer?.cancel();

    locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        // ====== LAPISAN 1: flag mock location dari Android ======
        bool isSuspicious = pos.isMocked;

        // ====== LAPISAN 2: cek kecepatan gerak masuk akal atau tidak ======
        // Kalau pindah >150 km dalam interval 30 detik = fisik tidak mungkin.
        if (!isSuspicious && lastValidPosition != null) {
          final distance = _distanceMeters(
            lastValidPosition!.latitude, lastValidPosition!.longitude,
            pos.latitude, pos.longitude,
          );
          const maxRealisticMeters = 150000; // 150 km dalam 30 detik
          if (distance > maxRealisticMeters) {
            isSuspicious = true;
          }
        }

        if (isSuspicious) {
          timer.cancel();
          locationTimer = null;

          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'RKM — Tracking Dihentikan',
              content: 'Lokasi mencurigakan terdeteksi. Tracking otomatis dimatikan.',
            );
          }

          service.invoke('fakeGpsDetected', {'user_id': currentUserId});
          return;
        }

        lastValidPosition = pos;
        await _appendPoint(currentUserId, pos);

        final prefs = await SharedPreferences.getInstance();
        final buffer = prefs.getStringList('${_bufferKey}_$currentUserId') ?? [];
        if (buffer.length >= 5) {
          await _flushBuffer(currentUserId, prefs);
        }
      } catch (_) {}
    });
  });

  service.on('stopTracking').listen((data) async {
    locationTimer?.cancel();
    locationTimer = null;

    final userId = data?['user_id'] as String? ?? currentUserId;
    final prefs = await SharedPreferences.getInstance();
    await _flushBuffer(userId, prefs);

    service.stopSelf();
  });
}

Future<void> _appendPoint(String userId, Position pos) async {
  final prefs = await SharedPreferences.getInstance();
  final key = '${_bufferKey}_$userId';
  final buffer = prefs.getStringList(key) ?? [];
  buffer.add(jsonEncode({
    'lat': pos.latitude,
    'lng': pos.longitude,
    'acc': pos.accuracy,
    'ts': DateTime.now().toIso8601String(),
  }));
  if (buffer.length > 500) buffer.removeRange(0, buffer.length - 500);
  await prefs.setStringList(key, buffer);
}

Future<void> _flushBuffer(String userId, SharedPreferences prefs) async {
  final key = '${_bufferKey}_$userId';
  final buffer = prefs.getStringList(key) ?? [];
  if (buffer.isEmpty) return;

  final token = prefs.getString('token') ?? '';
  final points = buffer.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

  try {
    final response = await http
        .post(
          Uri.parse('${ApiConstant.baseUrl}${ApiConstant.routeTrack}'),
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'user_id': userId, 'points': points}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await prefs.remove(key);
    }
  } catch (_) {}
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
