import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/riwayat_provider.dart';

class RiwayatView extends StatefulWidget {
  const RiwayatView({super.key});

  @override
  State<RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<RiwayatView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<RiwayatProvider>().load(userId);
    });
  }

  String _formatTanggal(String tanggal) {
    final date = DateTime.tryParse(tanggal);
    if (date == null) return tanggal;
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${bulan[date.month]} ${date.year}';
  }

  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item['foto_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(item['foto_url'], height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(item['member'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item['catatan'] ?? '-', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Text('Waktu: ${item['waktu'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (item['latitude'] != null && item['longitude'] != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://maps.google.com/?q=${item['latitude']},${item['longitude']}');
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Buka di Peta'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiwayatProvider>();
    final userId = context.read<AuthProvider>().user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Kunjungan')),
      body: RefreshIndicator(
        onRefresh: () => context.read<RiwayatProvider>().load(userId),
        child: Builder(builder: (_) {
          if (provider.state == RiwayatState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.state == RiwayatState.error) {
            return Center(child: Text(provider.errorMessage ?? 'Gagal memuat riwayat'));
          }
          if (provider.grouped.isEmpty) {
            return const Center(child: Text('Belum ada riwayat kunjungan'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.grouped.length,
            itemBuilder: (context, index) {
              final group = provider.grouped[index];
              final tanggal = group['tanggal'] as String;
              final items = (group['items'] as List<dynamic>).cast<Map<String, dynamic>>();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(_formatTanggal(tanggal),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                  ),
                  ...items.map((item) => GestureDetector(
                        onTap: () => _showDetail(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              if (item['foto_url'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(item['foto_url'], width: 48, height: 48, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          width: 48, height: 48, color: AppColors.inputFill,
                                          child: const Icon(Icons.image_not_supported_outlined, size: 20))),
                                )
                              else
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: AppColors.action.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.check_circle_outline, color: AppColors.action),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['member'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(item['catatan'] ?? '-', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                            ],
                          ),
                        ),
                      )),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}
