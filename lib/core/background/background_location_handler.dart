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
        initialNotificationContent: 'Mengirim lokasi secara berkala...',
        foregroundServiceNotificationId: _notifId,
      ),
      iosConfiguration: IosConfiguration(autoStart: false, onForeground: _onStart, onBackground: _onIosBackground),
    );
  }

  static Future<void> start(String userId) async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) await service.startService();
    service.invoke('startTracking', {'user_id': userId});
  }

  static Future<void> stop(String userId) async {
    FlutterBackgroundService().invoke('stopTracking', {'user_id': userId});
  }

  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();
  static Stream<Map<String, dynamic>?> get onFakeGpsDetected => FlutterBackgroundService().on('fakeGpsDetected');

  /// Baca status debug terakhir — dipakai UI untuk menampilkan panel diagnostik live.
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

Future<void> _writeDebug(String userId, Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  data['written_at'] = DateTime.now().toIso8601String();
  await prefs.setString('route_debug_$userId', jsonEncode(data));
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (service is AndroidServiceInstance) service.setAsForegroundService();

  Timer? locationTimer;
  String currentUserId = '';
  DateTime? lastFakeGpsReport;

  Future<void> captureOnce() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      if (pos.isMocked) {
        // PENTING: JANGAN matikan service total lagi — cuma lewati titik ini
        // dan tetap lanjut coba lagi di interval berikutnya. Mematikan total
        // dulu jadi penyebab "sekali salah deteksi, tracking mati selamanya".
        await _writeDebug(currentUserId, {
          'lat': pos.latitude, 'lng': pos.longitude, 'is_mocked': true, 'sent_ok': false,
          'error': 'Lokasi ditandai mocked oleh sistem Android, titik ini dilewati.',
        });

        final now = DateTime.now();
        if (lastFakeGpsReport == null || now.difference(lastFakeGpsReport!).inMinutes >= 10) {
          lastFakeGpsReport = now;
          service.invoke('fakeGpsDetected', {'user_id': currentUserId});
          try {
            await http.post(
              Uri.parse('${ApiConstant.baseUrl}/report_fake_gps.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'user_id': currentUserId, 'latitude': pos.latitude, 'longitude': pos.longitude, 'context': 'route_tracking'}),
            ).timeout(const Duration(seconds: 8));
          } catch (_) {}
        }
        return;
      }

      await _appendPoint(currentUserId, pos);
      final prefs = await SharedPreferences.getInstance();
      final sendResult = await _flushBuffer(currentUserId, prefs);

      await _writeDebug(currentUserId, {
        'lat': pos.latitude, 'lng': pos.longitude, 'is_mocked': false,
        'sent_ok': sendResult, 'error': sendResult ? null : 'Gagal mengirim ke server (cek koneksi internet HP).',
      });
    } catch (e) {
      await _writeDebug(currentUserId, {'lat': null, 'lng': null, 'is_mocked': false, 'sent_ok': false, 'error': 'Gagal ambil lokasi: $e'});
    }
  }

  service.on('startTracking').listen((data) async {
    currentUserId = data?['user_id'] as String? ?? '';
    locationTimer?.cancel();
    await captureOnce();
    locationTimer = Timer.periodic(const Duration(seconds: 15), (_) => captureOnce());
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
  buffer.add(jsonEncode({'lat': pos.latitude, 'lng': pos.longitude, 'acc': pos.accuracy, 'ts': DateTime.now().toIso8601String()}));
  if (buffer.length > 500) buffer.removeRange(0, buffer.length - 500);
  await prefs.setStringList(key, buffer);
}

Future<bool> _flushBuffer(String userId, SharedPreferences prefs) async {
  final key = '${_bufferKey}_$userId';
  final buffer = prefs.getStringList(key) ?? [];
  if (buffer.isEmpty) return true;

  final token = prefs.getString('token') ?? '';
  final points = buffer.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

  try {
    final response = await http.post(
      Uri.parse('${ApiConstant.baseUrl}${ApiConstant.routeTrack}'),
      headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
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

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
