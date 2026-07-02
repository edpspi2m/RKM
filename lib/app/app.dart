import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';
import '../core/network/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/kunjungan_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/kunjungan_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/kunjungan_provider.dart';
import '../views/login/login_view.dart';

class RkmApp extends StatelessWidget {
  const RkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(client: http.Client());
    final authService = AuthService(apiClient);
    final kunjunganService = KunjunganService(apiClient);

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: AuthRepository(authService),
            apiClient: apiClient,
          ),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => KunjunganProvider(
            repository: KunjunganRepository(kunjunganService: kunjunganService),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'RKM App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginView(),
      ),
    );
  }
}
