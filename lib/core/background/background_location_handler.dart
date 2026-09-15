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

/// Interval utama pengiriman lokasi (detik).
/// 30 detik = keseimbangan antara akurasi trail & hemat baterai.
const int _intervalSeconds = 30;

/// Minimal jarak (meter) untuk kirim. Kalau sales diam di 1 titik,
/// lokasi gak dikirim terus-terusan — hemat kuota & baterai.
const int _minDistanceMeters = 10;

/// Kirim batch trail ke routeTrack kalau buffer >= 5 titik
/// ATAU udah 2 menit dari pengiriman terakhir.
const int _bufferBatchSize     = 5;
const int _bufferMaxAgeSeconds = 120;

class BackgroundLocationHandler {
  // ===================== INIT =====================
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: _notifChannelId,
        initialNotificationTitle: 'RKM — Perjalanan Aktif',
        initialNotificationContent: 'Mengirim lokasi perjalanan...',
        foregroundServiceNotificationId: _notifId,
        foregroundServiceTypes: [AndroidForegroundType.location],
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  // ===================== START =====================
  static Future<void> start(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_active', true);
    await prefs.setString('tracking_user_id', userId);

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }

    // Tunggu isolate siap (maks 5 detik)
    var attempts = 0;
    while (!await service.isRunning() && attempts < 25) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    service.invoke('startTracking', {'user_id': userId});
    await Future.delayed(const Duration(milliseconds: 600));
    service.invoke('startTracking', {'user_id': userId});
  }

  // ===================== STOP =====================
  static Future<void> stop(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_active', false);
    FlutterBackgroundService().invoke('stopTracking', {'user_id': userId});
  }

  // ===================== HELPERS =====================
  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();

  static Stream<Map<String, dynamic>?> get onFakeGpsDetected =>
      FlutterBackgroundService().on('fakeGpsDetected');

  static Future<Map<String, dynamic>?> getLastDebugStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('route_debug_$userId');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

// ============================================================
//                     BACKGROUND ISOLATE
// ============================================================

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

  // ---------- Fungsi utama: ambil lokasi & kirim ----------
  Future<void> captureOnce() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      // --- Cek Fake GPS ---
      if (pos.isMocked) {
        await _writeDebug(currentUserId, {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'is_mocked': true,
          'sent_ok': false,
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

      // --- Smart Filter: kirim kalau jarak > 10m atau udah 1 menit ---
      bool shouldSend = true;
      if (lastSentPosition != null && lastSentAt != null) {
        final dist = Geolocator.distanceBetween(
          lastSentPosition.latitude,
          lastSentPosition.longitude,
          pos.latitude,
          pos.longitude,
        );
        final secs = DateTime.now().difference(lastSentAt!).inSeconds;
        shouldSend = dist >= _minDistanceMeters || secs >= 60;
      }
      if (!shouldSend) return;

      // ====== STEP 1: LIVE TRACKING (update_location.php) ======
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

      // ====== STEP 2: BUFFER TRAIL (routeTrack) ======
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

      // --- Update debug info ---
      await _writeDebug(currentUserId, {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'is_mocked': false,
        'sent_ok': liveTrackingOk,
        'live_ok': liveTrackingOk,
        'trail_ok': trailOk,
        'accuracy': pos.accuracy,
        'error': liveTrackingOk ? null : 'Gagal kirim live tracking (cek internet)',
      });

      // --- Update notifikasi ---
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
        'lat': null,
        'lng': null,
        'is_mocked': false,
        'sent_ok': false,
        'error': 'Gagal ambil lokasi: $e',
      });
    }
  }

  // ---------- Listener: MULAI tracking ----------
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

  // ---------- Listener: STOP tracking ----------
  service.on('stopTracking').listen((data) async {
    locationTimer?.cancel();
    locationTimer = null;

    final userId = data?['user_id'] as String? ?? currentUserId;
    final prefs = await SharedPreferences.getInstance();
    await _flushBuffer(userId, prefs);

    service.stopSelf();
  });
}

// ============================================================
//                     HELPER FUNCTIONS
// ============================================================

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

Future<bool> _flushBuffer(String userId, SharedPreferences prefs) async {
  final key = '${_bufferKey}_$userId';
  final buffer = prefs.getStringList(key) ?? [];
  if (buffer.isEmpty) return true;

  final token = prefs.getString('token') ?? '';
  final points = buffer
      .map((e) => jsonDecode(e) as Map<String, dynamic>)
      .toList();

  try {
    final response = await http.post(
      Uri.parse('${ApiConstant.baseUrl}${ApiConstant.routeTrack}'),
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'points': points,
      }),
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
  final prefs = await SharedPreferences.getInstance();
  data['written_at'] = DateTime.now().toIso8601String();
  await prefs.setString('route_debug_$userId', jsonEncode(data));
}
