import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme/app_colors.dart';
import '../core/widgets/fake_gps_dialog.dart';
import '../providers/route_tracking_provider.dart';
import 'home/kunjungan_home_view.dart';
import 'member/member_view.dart';
import 'lokasi_member/lokasi_member_view.dart';
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
    RiwayatView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Dengarkan fake GPS di level global, supaya popup muncul
    // di tab mana pun sedang dibuka, bukan cuma di halaman tracking.
    final routeProvider = context.watch<RouteTrackingProvider>();
    if (routeProvider.fakeGpsDetected) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await FakeGpsDialog.show(
          context,
          detail: 'Terdeteksi lokasi mencurigakan (fake GPS) saat merekam rute. Tracking otomatis dihentikan.',
        );
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
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Kunjungan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Member'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Lokasi Member'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}
