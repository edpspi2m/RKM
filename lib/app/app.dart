import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';
import '../core/network/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/kunjungan_service.dart';
import '../data/services/promo_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/kunjungan_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/kunjungan_provider.dart';
import '../providers/promo_provider.dart';
import '../views/login/login_view.dart';
import '../views/home/home_view.dart';

class RkmApp extends StatelessWidget {
  const RkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(client: http.Client());
    final authService = AuthService(apiClient);
    final kunjunganService = KunjunganService(apiClient);
    final promoService = PromoService(apiClient);

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

/// Menentukan halaman awal: cek dulu apakah ada sesi login tersimpan.
/// Jika ada & valid, langsung ke HomeView tanpa perlu login ulang.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isCheckingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.isAuthenticated) {
      return const HomeView();
    }

    return const LoginView();
  }
}
