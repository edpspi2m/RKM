import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';
import '../core/network/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/kunjungan_service.dart';
import '../data/services/promo_service.dart';
import '../data/services/member_service.dart';
import '../data/services/riwayat_service.dart';
import '../data/services/location_share_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/kunjungan_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/kunjungan_provider.dart';
import '../providers/promo_provider.dart';
import '../providers/member_provider.dart';
import '../providers/riwayat_provider.dart';
import '../providers/location_share_provider.dart';
import '../views/login/login_view.dart';
import '../views/main_navigation_view.dart';

class RkmApp extends StatelessWidget {
  const RkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(client: http.Client());
    final authService = AuthService(apiClient);
    final kunjunganService = KunjunganService(apiClient);
    final promoService = PromoService(apiClient);
    final memberService = MemberService(apiClient);
    final riwayatService = RiwayatService(apiClient);
    final locationShareService = LocationShareService(apiClient);

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: AuthRepository(authService),
            apiClient: apiClient,
          )..tryAutoLogin(),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => KunjunganProvider(
            repository: KunjunganRepository(kunjunganService: kunjunganService),
          ),
        ),
        ChangeNotifierProvider(create: (_) => PromoProvider(promoService)),
        ChangeNotifierProvider(create: (_) => MemberProvider(memberService)),
        ChangeNotifierProvider(create: (_) => RiwayatProvider(riwayatService)),
        ChangeNotifierProvider(create: (_) => LocationShareProvider(locationShareService)),
      ],
      child: MaterialApp(
        title: 'RKM App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _StartupGate(),
      ),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated) {
      return const MainNavigationView();
    }

    return const LoginView();
  }
}
