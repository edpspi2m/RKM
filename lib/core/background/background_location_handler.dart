import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constant.dart';

const _bufferKey       = 'route_point_buffer';
const _notifChannelId  = 'rkm_location_tracking';
const _notifId         = 889;

const int _intervalSeconds     = 30;
const int _minDistanceMeters   = 10;
const int _bufferBatchSize     = 5;
const int _bufferMaxAgeSeconds = 120;

class BackgroundLocationHandler {
  static bool _initialized = false;

  // ============ INIT — AMAN, GAK AUTO START ============
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: false,            // ← JANGAN auto start (bikin crash)
          isForegroundMode: true,
          notificationChannelId: _notifChannelId,
          initialNotificationTitle: 'RKM — Perjalanan Aktif',
          initialNotificationContent: 'Mengirim lokasi perjalanan...',
          foregroundServiceNotificationId: _notifId,
          foregroundServiceTypes: [AndroidForegroundType.location],
          // autoStartOnBoot DIHAPUS — bisa crash di HP tertentu
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,            // ← JANGAN auto start
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
      );

      _initialized = true;
      debugPrint('✅ BackgroundLocationHandler initialized');
    } catch (e, st) {
      debugPrint('❌ Init background service gagal: $e');
      debugPrint('$st');
    }
  }

  static Future<void> start(String userId) async {
    try {
      await initialize();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tracking_active', true);
      await prefs.setString('tracking_user_id', userId);

      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }

      var attempts = 0;
      while (!await service.isRunning() && attempts < 25) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }

      service.invoke('startTracking', {'user_id': userId});
      await Future.delayed(const Duration(milliseconds: 600));
      service.invoke('startTracking', {'user_id': userId});
    } catch (e, st) {
      debugPrint('❌ Start service gagal: $e');
      debugPrint('$st');
    }
  }

  static Future<void> stop(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tracking_active', false);
      FlutterBackgroundService().invoke('stopTracking', {'user_id': userId});
    } catch (e) {
      debugPrint('❌ Stop service gagal: $e');
    }
  }

  static Future<bool> isRunning() async {
    try {
      return await FlutterBackgroundService().isRunning();
    } catch (_) {
      return false;
    }
  }

  static Stream<Map<String, dynamic>?> get onFakeGpsDetected =>
      FlutterBackgroundService().on('fakeGpsDetected');

  static Future<Map<String, dynamic>?> getLastDebugStatus(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('route_debug_$userId');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (service is AndroidServiceInstance) service.setAsForegroundService();

  Timer? locationTimer;
  String currentUserId = '';
  DateTime? lastFakeGpsReport;
  Position? lastSentPosition;
  DateTime? lastSentAt;
  DateTime? lastBufferFlushAt;

  Future<void> captureOnce() async {
    if (currentUserId.isEmpty) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      if (pos.isMocked) {
        await _writeDebug(currentUserId, {
          'lat': pos.latitude, 'lng': pos.longitude,
          'is_mocked': true, 'sent_ok': false,
          'error': 'Lokasi ditandai mocked, dilewati.',
        });

        final now = DateTime.now();
        if (lastFakeGpsReport == null ||
            now.difference(lastFakeGpsReport!).inMinutes >= 5) {
          lastFakeGpsReport = now;
          service.invoke('fakeGpsDetected', {'user_id': currentUserId});
          try {
            await http.post(
              Uri.parse('${ApiConstant.baseUrl}${ApiConstant.reportFakeGps}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': currentUserId,
                'latitude': pos.latitude,
                'longitude': pos.longitude,
                'context': 'route_tracking',
              }),
            ).timeout(const Duration(seconds: 8));
          } catch (_) {}
        }
        return;
      }

      bool shouldSend = true;
      if (lastSentPosition != null && lastSentAt != null) {
        final dist = Geolocator.distanceBetween(
          lastSentPosition!.latitude,
          lastSentPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        final secs = DateTime.now().difference(lastSentAt!).inSeconds;
        shouldSend = dist >= _minDistanceMeters || secs >= 60;
      }
      if (!shouldSend) return;

      bool liveTrackingOk = false;
      try {
        final res = await http.post(
          Uri.parse('${ApiConstant.baseUrl}${ApiConstant.updateLocation}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': int.tryParse(currentUserId) ?? 0,
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'is_sharing': 1,
          }),
        ).timeout(const Duration(seconds: 12));
        liveTrackingOk = res.statusCode >= 200 && res.statusCode < 300;
      } catch (_) {}

      await _appendPoint(currentUserId, pos);

      final prefs = await SharedPreferences.getInstance();
      final bufferedCount = (prefs.getStringList('${_bufferKey}_$currentUserId') ?? []).length;
      final bufferAge = lastBufferFlushAt == null
          ? 9999
          : DateTime.now().difference(lastBufferFlushAt!).inSeconds;

      bool trailOk = true;
      if (bufferedCount >= _bufferBatchSize || bufferAge >= _bufferMaxAgeSeconds) {
        trailOk = await _flushBuffer(currentUserId, prefs);
        if (trailOk) lastBufferFlushAt = DateTime.now();
      }

      await _writeDebug(currentUserId, {
        'lat': pos.latitude, 'lng': pos.longitude,
        'is_mocked': false, 'sent_ok': liveTrackingOk,
        'live_ok': liveTrackingOk, 'trail_ok': trailOk,
        'accuracy': pos.accuracy,
        'error': liveTrackingOk ? null : 'Gagal kirim live tracking',
      });

      if (service is AndroidServiceInstance) {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        service.setForegroundNotificationInfo(
          title: 'RKM — Perjalanan Aktif',
          content: 'Terakhir kirim: $timeStr • Akurasi ±${pos.accuracy.round()}m',
        );
      }

      lastSentPosition = pos;
      lastSentAt = DateTime.now();
    } catch (e) {
      await _writeDebug(currentUserId, {
        'lat': null, 'lng': null,
        'is_mocked': false, 'sent_ok': false,
        'error': 'Gagal ambil lokasi: $e',
      });
    }
  }

  service.on('startTracking').listen((data) async {
    currentUserId = data?['user_id'] as String? ?? currentUserId;
    if (currentUserId.isEmpty) return;

    locationTimer?.cancel();
    await captureOnce();
    locationTimer = Timer.periodic(
      const Duration(seconds: _intervalSeconds),
      (_) => captureOnce(),
    );
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
  try {
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
  } catch (_) {}
}

Future<bool> _flushBuffer(String userId, SharedPreferences prefs) async {
  try {
    final key = '${_bufferKey}_$userId';
    final buffer = prefs.getStringList(key) ?? [];
    if (buffer.isEmpty) return true;

    final token = prefs.getString('token') ?? '';
    final points = buffer
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    final response = await http.post(
      Uri.parse('${ApiConstant.baseUrl}${ApiConstant.routeTrack}'),
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'user_id': userId, 'points': points}),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await prefs.remove(key);
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

Future<void> _writeDebug(String userId, Map<String, dynamic> data) async {
  if (userId.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    data['written_at'] = DateTime.now().toIso8601String();
    await prefs.setString('route_debug_$userId', jsonEncode(data));
  } catch (_) {}
}
