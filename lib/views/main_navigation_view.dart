import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../app/theme/app_colors.dart';
import '../core/network/api_client.dart';
import '../core/widgets/fake_gps_dialog.dart';
import '../core/widgets/global_fake_gps_blocker.dart';
import '../providers/auth_provider.dart';
import '../providers/route_tracking_provider.dart';
import 'home/kunjungan_home_view.dart';
import 'member/member_view.dart';
import 'lokasi_member/lokasi_member_view.dart';
import 'lokasi_member/not_get_map_view.dart';
import 'riwayat/riwayat_view.dart';
import 'locked/locked_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _statusTimer;
  bool _showingLock = false;
  bool _fakeGpsBlocked = false;

  final List<Widget> _pages = const [
    KunjunganHomeView(),
    MemberView(),
    LokasiMemberView(),
    NotGetMapView(),
    RiwayatView(),
  ];

  final List<IconData> _iconsOutline = const [Icons.storefront_outlined, Icons.people_outline, Icons.map_outlined, Icons.cancel_outlined, Icons.history_outlined];
  final List<IconData> _iconsFilled = const [Icons.storefront, Icons.people, Icons.map, Icons.cancel, Icons.history];
  final List<String> _labels = const ['Kunjungan', 'Member', 'Lokasi', 'Not Get', 'Riwayat'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statusTimer = Timer.periodic(const Duration(seconds: 45), (_) => _checkStatus());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkStatus();
      await _ensureTrackingAlwaysOn();
      _checkFakeGps(context: 'app_resume');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkFakeGps(context: 'app_resume');
      _ensureTrackingAlwaysOn();
    }
  }

  /// AUTO-START: lokasi otomatis nyala begitu app dibuka/login — TIDAK ADA
  /// toggle manual lagi. Kalau belum aktif, langsung diaktifkan diam-diam.
  Future<void> _ensureTrackingAlwaysOn() async {
    final routeProvider = context.read<RouteTrackingProvider>();
    if (routeProvider.isTracking) return;

    final userId = context.read<AuthProvider>().user?.id ?? '';
    if (userId.isEmpty) return;

    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
    await Permission.notification.request();
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) await Permission.ignoreBatteryOptimizations.request();

    await routeProvider.startTracking(userId);
  }

  Future<void> _checkFakeGps({required String context}) async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 8));
      if (pos.isMocked && mounted) {
        await _lockAccountNow(pos.latitude, pos.longitude, context);
      }
    } catch (_) {}
  }

  Future<void> _lockAccountNow(double? lat, double? lng, String reasonContext) async {
    if (_fakeGpsBlocked) return;
    setState(() => _fakeGpsBlocked = true);

    final userId = this.context.read<AuthProvider>().user?.id ?? '';
    try {
      await http.post(
        Uri.parse('https://api.isreport.my.id/absen/auto_lock_fake_gps.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'latitude': lat, 'longitude': lng, 'context': reasonContext}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> _checkStatus() async {
    if (!mounted || _showingLock || _fakeGpsBlocked) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post('/check_status.php', body: {'user_id': userId});

      if (response['is_locked'] == true) {
        _showingLock = true;
        final msg = response['lock_message']?.toString() ?? 'Akun Anda dikunci oleh admin.';
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => LockedView(message: msg)));
        }
        return;
      }

      final notice = response['notice'];
      if (notice != null && notice.toString().isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pemberitahuan'),
            content: Text(notice.toString()),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Mengerti'))],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_fakeGpsBlocked) {
      return const GlobalFakeGpsBlocker();
    }

    final routeProvider = context.watch<RouteTrackingProvider>();
    if (routeProvider.fakeGpsDetected) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await FakeGpsDialog.show(context);
        if (mounted) context.read<RouteTrackingProvider>().clearFakeGpsFlag();
      });
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _AnimatedBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        iconsOutline: _iconsOutline,
        iconsFilled: _iconsFilled,
        labels: _labels,
      ),
    );
  }
}

class _AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IconData> iconsOutline;
  final List<IconData> iconsFilled;
  final List<String> labels;

  const _AnimatedBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.iconsOutline,
    required this.iconsFilled,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(labels.length, (index) {
              final isActive = index == currentIndex;
              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: isActive ? 0.8 : 1.0, end: isActive ? 1.15 : 1.0),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(isActive ? iconsFilled[index] : iconsOutline[index], color: isActive ? AppColors.primary : AppColors.textSecondary, size: 22),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(fontSize: isActive ? 10.5 : 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.primary : AppColors.textSecondary),
                        child: Text(labels[index]),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
