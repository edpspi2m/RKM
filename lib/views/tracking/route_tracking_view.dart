import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/fake_gps_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_tracking_provider.dart';
import 'package:geolocator/geolocator.dart';

class RouteTrackingView extends StatefulWidget {
  const RouteTrackingView({super.key});

  @override
  State<RouteTrackingView> createState() => _RouteTrackingViewState();
}

class _RouteTrackingViewState extends State<RouteTrackingView> {
  bool _isRequesting = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteTrackingProvider>().checkInitialState();
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<RouteTrackingProvider>().uploadPendingPoints(userId);
      context.read<RouteTrackingProvider>().refreshDebugStatus(userId);
    });
    // Poll status debug tiap 5 detik — panel di layar update sendiri secara live.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<RouteTrackingProvider>().refreshDebugStatus(userId);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<bool> _ensurePermissions() async {
    final fineStatus = await Permission.locationWhenInUse.request();
    if (!fineStatus.isGranted) return false;
    final bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi "Selalu Izinkan" diperlukan.')));
      return false;
    }
    await Permission.notification.request();
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) await Permission.ignoreBatteryOptimizations.request();
    return true;
  }

  Future<void> _toggle(RouteTrackingProvider provider) async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    if (userId.isEmpty) return;

    if (!provider.isTracking) {
      setState(() => _isRequesting = true);
      final granted = await _ensurePermissions();
      if (!granted) { setState(() => _isRequesting = false); return; }
      final success = await provider.startTracking(userId);
      setState(() => _isRequesting = false);
      if (!success && mounted) {
        if (provider.fakeGpsDetected) {
          await FakeGpsDialog.show(context);
          provider.clearFakeGpsFlag();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengaktifkan, pastikan GPS menyala.')));
        }
      }
    } else {
      await provider.stopTracking(userId);
    }
  }

  Future<void> _testKirimManual() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post('/route_tracking.php', body: {
        'user_id': userId,
        'points': [{'lat': pos.latitude.toString(), 'lng': pos.longitude.toString(), 'ts': DateTime.now().toIso8601String()}],
      });
      if (mounted) {
        final liveUpdated = response['live_updated'] == true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(liveUpdated ? 'Berhasil terkirim ke server! Cek Tracking Maps di web.' : 'Server merespon tapi live_updated=false. Kirim screenshot ini.'),
          backgroundColor: liveUpdated ? AppColors.action : AppColors.warning,
        ));
      }
      final userIdForDebug = userId;
      await context.read<RouteTrackingProvider>().refreshDebugStatus(userIdForDebug);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GAGAL: $e')));
    }
  }

  Widget _debugPanel(Map<String, dynamic>? debug) {
    if (debug == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
        child: const Text('Belum ada data diagnostik. Aktifkan tracking atau tekan "Test Kirim Lokasi Sekarang" di bawah.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      );
    }

    final sentOk = debug['sent_ok'] == true;
    final isMocked = debug['is_mocked'] == true;
    final error = debug['error'];
    final lat = debug['lat'];
    final lng = debug['lng'];
    final writtenAt = debug['written_at'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sentOk ? AppColors.action.withOpacity(0.06) : AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sentOk ? AppColors.action.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(sentOk ? Icons.check_circle : Icons.error_outline, size: 16, color: sentOk ? AppColors.action : AppColors.error),
            const SizedBox(width: 6),
            Text(sentOk ? 'Titik terakhir BERHASIL dikirim' : 'Titik terakhir GAGAL dikirim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sentOk ? AppColors.action : AppColors.error)),
          ]),
          const SizedBox(height: 6),
          if (lat != null) Text('Koordinat: $lat, $lng', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text('Terdeteksi mocked: ${isMocked ? "YA (ditolak)" : "Tidak"}', style: TextStyle(fontSize: 11, color: isMocked ? AppColors.error : AppColors.textSecondary)),
          if (error != null) Text('Detail: $error', style: const TextStyle(fontSize: 11, color: AppColors.error)),
          if (writtenAt != null) Text('Waktu cek: $writtenAt', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RouteTrackingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Perjalanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
              child: Column(
                children: [
                  Icon(provider.isTracking ? Icons.route : Icons.route_outlined, size: 48, color: provider.isTracking ? AppColors.action : AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(provider.isTracking ? 'Rute Perjalanan Aktif' : 'Aktifkan Rute Perjalanan', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Titik lokasi realtime tercatat otomatis sepanjang perjalanan Anda.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 20),
                  (_isRequesting || provider.isValidating) ? const CircularProgressIndicator() : Switch(value: provider.isTracking, activeColor: AppColors.action, onChanged: (_) => _toggle(provider)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Status Diagnostik (Live)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            _debugPanel(provider.debugStatus),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testKirimManual,
                icon: const Icon(Icons.wifi_tethering, size: 18),
                label: const Text('Test Kirim Lokasi Sekarang'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(onPressed: () => openAppSettings(), icon: const Icon(Icons.battery_charging_full, size: 18), label: const Text('Buka Pengaturan Baterai HP')),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
              child: const Text('Khusus HP Xiaomi/Oppo/Vivo: Pengaturan HP → Aplikasi → RKM → aktifkan "Autostart"/"Jalankan di Latar Belakang".', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
