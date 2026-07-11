import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../login/login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 600, maxHeight: 600);
    if (picked == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    setState(() => _isUploading = true);

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.postMultipart(
        '/upload_foto_profil.php',
        fields: {'user_id': userId},
        file: File(picked.path),
        fileFieldName: 'foto',
      );
      final url = response['foto_url'] as String?;
      if (url != null) {
        await authProvider.updateFotoProfil(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal unggah foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _confirmLogout() async {
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

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
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
            child: Stack(
              children: [
                Container(
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
                      ? const Icon(Icons.person, size: 38, color: AppColors.textSecondary)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadPhoto,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUploading
                          ? const Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(nama, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(role, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
            onTap: _confirmLogout,
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
