import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';

class TrackingMapsView extends StatelessWidget {
  const TrackingMapsView({super.key});

  Future<void> _openTracking() async {
    final uri = Uri.parse('https://admin2m.isreport.my.id/tracking.php');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tracking Maps')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Lihat posisi sales secara real-time',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Fitur khusus untuk akun master. Menu ini tidak terlihat oleh akun sales.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openTracking,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Buka Peta Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
