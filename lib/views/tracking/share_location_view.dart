import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_share_provider.dart';

class ShareLocationView extends StatelessWidget {
  const ShareLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    final shareProvider = context.watch<LocationShareProvider>();
    final userId = context.read<AuthProvider>().user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bagikan Lokasi Live')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Icon(
                    shareProvider.isSharing ? Icons.location_on : Icons.location_off_outlined,
                    size: 48,
                    color: shareProvider.isSharing ? AppColors.action : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shareProvider.isSharing ? 'Lokasi sedang dibagikan' : 'Lokasi tidak dibagikan',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shareProvider.isSharing
                        ? 'Admin dapat melihat posisi Anda secara real-time selama aplikasi ini dibuka.'
                        : 'Aktifkan untuk membagikan lokasi Anda ke admin secara real-time.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Switch(
                    value: shareProvider.isSharing,
                    activeColor: AppColors.action,
                    onChanged: (value) {
                      if (value) {
                        shareProvider.startSharing(userId);
                      } else {
                        shareProvider.stopSharing(userId);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lokasi hanya terkirim selama aplikasi ini terbuka di layar. Menutup aplikasi akan menghentikan pembagian lokasi.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (shareProvider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(shareProvider.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
