import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme/app_colors.dart';
import '../core/widgets/fake_gps_dialog.dart';
import '../providers/route_tracking_provider.dart';
import 'home/kunjungan_home_view.dart';
import 'member/member_view.dart';
import 'lokasi_member/lokasi_member_view.dart';
import 'lokasi_member/not_get_map_view.dart';
import 'riwayat/riwayat_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    KunjunganHomeView(),
    MemberView(),
    LokasiMemberView(),
    NotGetMapView(),
    RiwayatView(),
  ];

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
