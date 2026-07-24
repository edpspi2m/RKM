import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';

class RiwayatDetailView extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool showSales;
  const RiwayatDetailView({super.key, required this.item, this.showSales = false});

  @override
  Widget build(BuildContext context) {
    final isNotGet = item['status_kunjungan'] == 'not_get';
    final approval = item['status_approval'] ?? 'pending';
    final approvalMap = {'pending': ('Menunggu', AppColors.warning), 'approved': ('Disetujui', AppColors.action), 'rejected': ('Ditolak', AppColors.error)};
    final (approvalLabel, approvalColor) = approvalMap[approval] ?? ('Menunggu', AppColors.warning);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Kunjungan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (item['foto_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(item['foto_url'], height: 260, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 260, color: AppColors.inputFill, child: const Icon(Icons.image_not_supported_outlined))),
            )
          else
            Container(height: 200, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(16)), child: const Center(child: Icon(Icons.check_circle_outline, size: 48, color: AppColors.action))),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text(item['member'] ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: isNotGet ? AppColors.error.withOpacity(0.1) : AppColors.action.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(isNotGet ? 'NOT GET' : 'BERHASIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isNotGet ? AppColors.error : AppColors.action)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: approvalColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Status Approval: $approvalLabel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: approvalColor)),
          ),
          const SizedBox(height: 20),

          if (showSales) _detailRow(Icons.person_outline, 'Sales', item['nama_sales'] ?? '-'),
          _detailRow(Icons.access_time, 'Waktu', item['waktu'] ?? '-'),
          _detailRow(Icons.notes, 'Catatan', item['catatan']?.toString().isNotEmpty == true ? item['catatan'] : '-'),
          if (item['latitude'] != null && item['longitude'] != null) ...[
            _detailRow(Icons.gps_fixed, 'Koordinat GPS', '${item['latitude']}, ${item['longitude']}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('https://maps.google.com/?q=${item['latitude']},${item['longitude']}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Buka Lokasi di Google Maps'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
