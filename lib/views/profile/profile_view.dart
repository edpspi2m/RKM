import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../login/login_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  String _getInitial(String nama) {
    if (nama.isEmpty) return '?';
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nama = user?.nama ?? '-';
    final username = user?.username ?? '-';
    final role = user?.role ?? '-';
    final fotoUrl = user?.fotoProfil;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil'), elevation: 0.5),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inputFill,
                border: Border.all(color: AppColors.divider, width: 1),
                image: fotoUrl != null
                    ? DecorationImage(image: NetworkImage(fotoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: fotoUrl == null
                  ? Center(
                      child: Text(
                        _getInitial(nama),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(nama, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(role, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (fotoUrl == null) ...[
            const SizedBox(height: 6),
            const Text(
              'Foto profil belum diatur. Hubungi admin untuk mengunggahnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 24),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.textSecondary),
            title: const Text('Username', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            subtitle: Text(username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
            title: const Text('Peran', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            subtitle: Text(role, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Keluar', style: TextStyle(color: AppColors.error, fontSize: 14)),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(height: 1),

          const SizedBox(height: 24),
          const Center(
            child: Text('RKM App v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
