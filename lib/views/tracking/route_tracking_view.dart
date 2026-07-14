import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/fake_gps_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_tracking_provider.dart';

class RouteTrackingView extends StatefulWidget {
  const RouteTrackingView({super.key});

  @override
  State<RouteTrackingView> createState() => _RouteTrackingViewState();
}

class _RouteTrackingViewState extends State<RouteTrackingView> {
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteTrackingProvider>().checkInitialState();
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<RouteTrackingProvider>().uploadPendingPoints(userId);
    });
  }

  Future<bool> _ensurePermissions() async {
    final fineStatus = await Permission.locationWhenInUse.request();
    if (!fineStatus.isGranted) return false;

    final bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi "Selalu Izinkan" diperlukan untuk rekam rute berjalan.')),
        );
      }
      return false;
    }

    await Permission.notification.request();

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    return true;
  }

  Future<void> _toggle(RouteTrackingProvider provider) async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    if (userId.isEmpty) return;

    if (!provider.isTracking) {
      setState(() => _isRequesting = true);
      final granted = await _ensurePermissions();
      setState(() => _isRequesting = false);
      if (!granted) return;
      await provider.startTracking(userId);
    } else {
      await provider.stopTracking(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RouteTrackingProvider>();

    // Kalau background service mendeteksi fake GPS, tampilkan popup peringatan.
    if (provider.fakeGpsDetected) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await FakeGpsDialog.show(
          context,
          detail: 'Terdeteksi lokasi palsu (fake GPS) saat merekam rute. Tracking otomatis dihentikan demi menjaga keakuratan data.',
        );
        if (mounted) context.read<RouteTrackingProvider>().clearFakeGpsFlag();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rekam Rute Perjalanan')),
      body: Padding(
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
                  Text(provider.isTracking ? 'Rute sedang direkam' : 'Rute tidak direkam', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    provider.isTracking
                        ? 'Titik lokasi tercatat otomatis tiap 30 detik, termasuk saat layar HP terkunci. Tracking otomatis berhenti jika terdeteksi fake GPS.'
                        : 'Aktifkan untuk merekam jalur kunjungan Anda sepanjang hari.',
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  _isRequesting
                      ? const CircularProgressIndicator()
                      : Switch(value: provider.isTracking, activeColor: AppColors.action, onChanged: (_) => _toggle(provider)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saat mengaktifkan, HP meminta izin "Selalu Izinkan" lokasi dan pengecualian optimasi baterai — WAJIB disetujui agar rekaman tetap berjalan saat layar terkunci.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.battery_charging_full, size: 18),
                label: const Text('Buka Pengaturan Baterai HP'),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'Khusus HP Xiaomi/Oppo/Vivo: buka Pengaturan HP → Aplikasi → RKM → aktifkan "Autostart" atau "Jalankan di Latar Belakang". Tanpa ini, sistem HP tetap bisa mematikan tracking meski izin sudah diberikan.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
