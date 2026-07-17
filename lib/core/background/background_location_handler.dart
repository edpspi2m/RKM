import 'dart:async';
import 'dart:convert';
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
        initialNotificationTitle: 'RKM — Perjalanan',
        initialNotificationContent: 'Titik lokasi tercatat otomatis...',
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

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer? locationTimer;
  String currentUserId = '';

  Future<void> stopEverything({required bool fakeGps}) async {
    locationTimer?.cancel();
    locationTimer = null;

    final prefs = await SharedPreferences.getInstance();
    await _flushBuffer(currentUserId, prefs);

    if (fakeGps) {
      service.invoke('fakeGpsDetected', {'user_id': currentUserId});
    }

    // KUNCI FIX: service harus benar-benar dimatikan, bukan cuma timer-nya.
    // Kalau tidak, isRunning() tetap true dan toggle di UI "hidup lagi sendiri".
    service.stopSelf();
  }

  Future<void> captureOnce() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (pos.isMocked) {
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(title: 'RKM — Dihentikan', content: 'Lokasi mencurigakan terdeteksi.');
        }
        await stopEverything(fakeGps: true);
        return;
      }

      await _appendPoint(currentUserId, pos);
      final prefs = await SharedPreferences.getInstance();
      await _flushBuffer(currentUserId, prefs);
    } catch (_) {}
  }

  service.on('startTracking').listen((data) async {
    currentUserId = data?['user_id'] as String? ?? '';
    locationTimer?.cancel();
    await captureOnce();
    locationTimer = Timer.periodic(const Duration(seconds: 15), (_) => captureOnce());
  });

  service.on('stopTracking').listen((data) async {
    await stopEverything(fakeGps: false);
  });
}

Future<void> _appendPoint(String userId, Position pos) async {
  final prefs = await SharedPreferences.getInstance();
  final key = '${_bufferKey}_$userId';
  final buffer = prefs.getStringList(key) ?? [];
  buffer.add(jsonEncode({'lat': pos.latitude, 'lng': pos.longitude, 'acc': pos.accuracy, 'ts': DateTime.now().toIso8601String()}));
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
          headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
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
