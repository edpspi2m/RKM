import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<bool> _ensurePermissions() async {
    final fineStatus = await Permission.locationWhenInUse.request();
    if (!fineStatus.isGranted) return false;
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengaktifkan. Cek panel diagnostik di bawah.')));
        }
      }
    } else {
      await provider.stopTracking(userId);
    }
  }

  // Test button SEKARANG mengecek fake GPS juga — sebelumnya lubang ini
  // yang bikin "test kirim lokasi" lolos walau fake GPS aktif.
  Future<void> _testKirimManual() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));

      if (pos.isMocked) {
        if (mounted) {
          await FakeGpsDialog.show(context);
        }
        context.read<RouteTrackingProvider>().startTracking(userId); // akan gagal & set fakeGpsDetected untuk laporan telegram
        return;
      }

      final apiClient = context.read<AuthProvider>();
      final response = await context.read<RouteTrackingProvider>().startTracking(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response ? 'Berhasil terkirim! Cek Tracking Maps di web sekarang.' : 'Gagal terkirim, cek panel diagnostik.'),
          backgroundColor: response ? AppColors.action : AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GAGAL: $e')));
    }
  }

  Widget _debugPanel(Map<String, dynamic>? debug, int success, int fail) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.action.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Column(children: [Text('$success', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.action)), const Text('Berhasil', style: TextStyle(fontSize: 10))]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Column(children: [Text('$fail', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error)), const Text('Gagal', style: TextStyle(fontSize: 10))]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (debug != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: debug['sent_ok'] == true ? AppColors.action.withOpacity(0.06) : AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: debug['sent_ok'] == true ? AppColors.action.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debug['sent_ok'] == true ? '✓ Titik terakhir berhasil' : '✗ Titik terakhir gagal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: debug['sent_ok'] == true ? AppColors.action : AppColors.error)),
                if (debug['lat'] != null) Text('Koordinat: ${debug['lat']}, ${debug['lng']}', style: const TextStyle(fontSize: 11)),
                if (debug['error'] != null) Text('Detail: ${debug['error']}', style: const TextStyle(fontSize: 11, color: AppColors.error)),
                Text('Jam: ${debug['written_at']}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
      ],
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Catatan: pencatatan aktif selama aplikasi terbuka/baru saja diminimize. Jangan menutup paksa aplikasi selama tracking aktif.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  (_isRequesting || provider.isValidating) ? const CircularProgressIndicator() : Switch(value: provider.isTracking, activeColor: AppColors.action, onChanged: (_) => _toggle(provider)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Status Diagnostik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            _debugPanel(provider.debugStatus, provider.successCount, provider.failCount),
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
          ],
        ),
      ),
    );
  }
}
