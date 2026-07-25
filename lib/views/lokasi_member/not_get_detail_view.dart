
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';

class NotGetDetailView extends StatelessWidget {
  final Map<String, dynamic> item;
  const NotGetDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final hasLokasi = item['latitude'] != null && item['longitude'] != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Member Not Get')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (item['foto_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(item['foto_url'], height: 280, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 200, color: AppColors.inputFill, child: const Icon(Icons.image_not_supported_outlined, size: 40))),
            )
          else
            Container(height: 180, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.06), borderRadius: BorderRadius.circular(16)), child: const Center(child: Icon(Icons.no_photography_outlined, size: 48, color: AppColors.error))),

          const SizedBox(height: 20),
          Text(item['member'] ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('NOT GET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
          ),
          const SizedBox(height: 20),

          _row(Icons.location_city_outlined, 'Kelurahan', item['kelurahan'] ?? '-'),
          _row(Icons.map_outlined, 'Kecamatan', item['kecamatan'] ?? '-'),
          _row(Icons.location_on_outlined, 'Kota/Kabupaten', item['kota'] ?? '-'),
          _row(Icons.person_outline, 'Sales', item['nama_sales'] ?? '-'),
          _row(Icons.access_time, 'Waktu', item['waktu'] ?? '-'),
          _row(Icons.notes, 'Alasan', item['catatan']?.toString().isNotEmpty == true ? item['catatan'] : '-'),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: hasLokasi
                  ? () async {
                      final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${item['latitude']},${item['longitude']}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  : null,
              icon: const Icon(Icons.directions),
              label: Text(hasLokasi ? 'Buka Lokasi di Google Maps' : 'Lokasi Tidak Tersedia'),
              style: ElevatedButton.styleFrom(backgroundColor: hasLokasi ? AppColors.primary : AppColors.divider, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
