import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../login/login_view.dart';

class LockedView extends StatelessWidget {
  final String message;
  const LockedView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF08306B),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
                      }
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), foregroundColor: Colors.white),
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
