import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../kunjungan/kunjungan_form_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => authProvider.logout()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, ${user?.nama ?? '-'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(user?.jabatan ?? '', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                title: const Text('Buat Laporan Kunjungan'),
                subtitle: const Text('Ambil foto dengan watermark lokasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => KunjunganFormView()), // <- const DIHAPUS DI SINI
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
