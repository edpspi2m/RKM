import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme/app_colors.dart';
import '../core/network/api_client.dart';
import '../core/widgets/fake_gps_dialog.dart';
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

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;
  Timer? _statusTimer;
  bool _showingLock = false;

  final List<Widget> _pages = const [
    KunjunganHomeView(),
    MemberView(),
    LokasiMemberView(),
    NotGetMapView(),
    RiwayatView(),
  ];

  @override
  void initState() {
    super.initState();
    _statusTimer = Timer.periodic(const Duration(seconds: 45), (_) => _checkStatus());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (!mounted || _showingLock) return;
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
    final routeProvider = context.watch<RouteTrackingProvider>();
    if (routeProvider.fakeGpsDetected) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await FakeGpsDialog.show(context);
        if (mounted) context.read<RouteTrackingProvider>().clearFakeGpsFlag();
      });
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        elevation: 8,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Kunjungan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Member'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Lokasi'),
          BottomNavigationBarItem(icon: Icon(Icons.cancel_outlined), activeIcon: Icon(Icons.cancel), label: 'Not Get'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}
