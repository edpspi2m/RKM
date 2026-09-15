import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/background/background_location_handler.dart';
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
  Timer? _statusTimer;
  Map<String, dynamic>? _lastStatus;

  @override
  void initState() {
    super.initState();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().user?.id ?? '';
      if (userId.isEmpty) return;
      final status = await BackgroundLocationHandler.getLastDebugStatus(userId);
      if (mounted) setState(() => _lastStatus = status);
    });
  }

  Future<bool> _ensurePermissions() async {
    final fineStatus = await Permission.locationWhenInUse.request();
    if (!fineStatus.isGranted) return false;

    final bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin "Selalu Izinkan" diperlukan agar pencatatan tetap berjalan.'),
        ),
      );
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
      if (!granted) {
        setState(() => _isRequesting = false);
        return;
      }
      final success = await provider.startTracking(userId);
      if (!mounted) return;
      setState(() => _isRequesting = false);

      if (!success) {
        if (provider.fakeGpsDetected) {
          await FakeGpsDialog.show(context);
          provider.clearFakeGpsFlag();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengaktifkan. Pastikan GPS menyala.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rute perjalanan aktif.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      await provider.stopTracking(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rute perjalanan dihentikan.')),
        );
      }
    }
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
            // === CARD UTAMA ===
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    provider.isTracking ? Icons.route : Icons.route_outlined,
                    size: 56,
                    color: provider.isTracking ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.isTracking
                        ? 'RUTE PERJALANAN AKTIF'
                        : 'AKTIFKAN RUTE PERJALANAN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Titik lokasi realtime tercatat otomatis sepanjang perjalanan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  (_isRequesting || provider.isValidating)
                      ? const CircularProgressIndicator()
                      : Switch(
                          value: provider.isTracking,
                          activeColor: AppColors.success,
                          onChanged: (_) => _toggle(provider),
                        ),
                ],
              ),
            ),

            // === STATUS PENGIRIMAN ===
            if (provider.isTracking && _lastStatus != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.satellite_alt, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'STATUS PENGIRIMAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _statusRow(
                      'Lokasi terakhir',
                      _lastStatus!['lat'] != null
                          ? '${(_lastStatus!['lat'] as num).toStringAsFixed(5)}, ${(_lastStatus!['lng'] as num).toStringAsFixed(5)}'
                          : '-',
                    ),
                    _statusRow(
                      'Waktu',
                      _lastStatus!['written_at'] != null
                          ? DateTime.parse(_lastStatus!['written_at'])
                              .toLocal()
                              .toString()
                              .substring(11, 19)
                          : '-',
                    ),
                    _statusRow(
                      'Terkirim',
                      _lastStatus!['sent_ok'] == true ? '✅ Ya' : '❌ Gagal',
                    ),
                    if (_lastStatus!['error'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '⚠ ${_lastStatus!['error']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // === WARNING ===
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wajib setujui izin "Selalu Izinkan" lokasi dan pengecualian optimasi baterai.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textPrimary,
                      ),
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
                label: const Text('BUKA PENGATURAN BATERAI'),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Text(
                'Xiaomi/Oppo/Vivo: Setting HP → Apps → RKM → aktifkan "Autostart" & "Battery: No restriction".',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
