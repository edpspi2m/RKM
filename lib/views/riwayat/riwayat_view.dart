import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/riwayat_provider.dart';
import 'riwayat_detail_view.dart';

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

  Widget _statusBadge(Map<String, dynamic> item) {
    final isNotGet = item['status_kunjungan'] == 'not_get';
    final approval = item['status_approval'] ?? 'pending';

    if (isNotGet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: const Text('Not Get', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
      );
    }

    final map = {'pending': ('Menunggu', AppColors.warning), 'approved': ('Disetujui', AppColors.action), 'rejected': ('Ditolak', AppColors.error)};
    final (label, color) = map[approval] ?? ('Menunggu', AppColors.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _showDetail(Map<String, dynamic> item, bool showSales) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RiwayatDetailView(item: item, showSales: showSales)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiwayatProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? '';
    final isMaster = authProvider.user?.role == 'master';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(provider.isAllMode ? 'Riwayat Semua Sales' : 'Riwayat Kunjungan'),
        actions: [
          if (isMaster)
            TextButton.icon(
              onPressed: () {
                if (provider.isAllMode) {
                  context.read<RiwayatProvider>().load(userId);
                } else {
                  context.read<RiwayatProvider>().loadAll(userId);
                }
              },
              icon: Icon(provider.isAllMode ? Icons.person : Icons.groups, color: Colors.white, size: 18),
              label: Text(provider.isAllMode ? 'Saya Saja' : 'Semua Sales', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.isAllMode ? context.read<RiwayatProvider>().loadAll(userId) : context.read<RiwayatProvider>().load(userId),
        child: Builder(builder: (_) {
          if (provider.state == RiwayatState.loading) return const Center(child: CircularProgressIndicator());
          if (provider.state == RiwayatState.error) return Center(child: Text(provider.errorMessage ?? 'Gagal memuat riwayat'));
          if (provider.grouped.isEmpty) return const Center(child: Text('Belum ada riwayat kunjungan'));

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
                    child: Text(_formatTanggal(tanggal), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                  ),
                  ...items.map((item) => GestureDetector(
                        onTap: () => _showDetail(item, provider.isAllMode),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                          child: Row(
                            children: [
                              if (item['foto_url'] != null)
                                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['foto_url'], width: 48, height: 48, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.inputFill, child: const Icon(Icons.image_not_supported_outlined, size: 20))))
                              else
                                Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.action.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.check_circle_outline, color: AppColors.action)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['member'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    if (provider.isAllMode)
                                      Text('Sales: ${item['nama_sales'] ?? '-'}', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600))
                                    else
                                      Text(item['catatan'] ?? '-', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              _statusBadge(item),
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
