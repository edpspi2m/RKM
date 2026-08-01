import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import 'potensi_kunjungan_form_view.dart';

class PotensiDetailView extends StatefulWidget {
  final Map<String, dynamic> item;
  const PotensiDetailView({super.key, required this.item});

  @override
  State<PotensiDetailView> createState() => _PotensiDetailViewState();
}

class _PotensiDetailViewState extends State<PotensiDetailView> {
  bool _loading = true;
  bool _sudahDikunjungi = false;
  int _totalKunjungan = 0;
  List<Map<String, dynamic>> _riwayat = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final response = await context.read<ApiClient>().post('/potensi_lokasi_detail.php', body: {
        'potensi_id': widget.item['id'].toString(),
      });
      if (mounted) {
        setState(() {
          _sudahDikunjungi = response['sudah_dikunjungi'] == true;
          _totalKunjungan = response['total_kunjungan'] as int? ?? 0;
          _riwayat = (response['riwayat'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bukaNavigasi() async {
    final lat = widget.item['latitude'];
    final lng = widget.item['longitude'];
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Lokasi Potensi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _sudahDikunjungi ? AppColors.actionLight : AppColors.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _sudahDikunjungi ? AppColors.action.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_sudahDikunjungi ? Icons.check_circle : Icons.location_on_outlined, size: 36, color: _sudahDikunjungi ? AppColors.action : AppColors.error),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_sudahDikunjungi ? 'Sudah Dikunjungi' : 'Belum Pernah Dikunjungi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _sudahDikunjungi ? AppColors.actionText : AppColors.error)),
                            const SizedBox(height: 2),
                            Text(widget.item['nama'] ?? 'Lokasi Potensial', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                        child: Column(children: [Text('$_totalKunjungan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)), const Text('Total Kunjungan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                        child: Column(children: [Text(widget.item['kode_area'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), const Text('Kode Area', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _bukaNavigasi,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Rute ke Lokasi Ini'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PotensiKunjunganFormView(potensiId: int.parse(widget.item['id'].toString()), namaLokasi: widget.item['nama'] ?? 'Lokasi Potensial'),
                      ));
                      if (result == true && mounted) _loadDetail();
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Buat Laporan Kunjungan'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.action, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                if (_riwayat.isNotEmpty) ...[
                  const Text('Riwayat Kunjungan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._riwayat.map((v) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                        child: Row(
                          children: [
                            if (v['foto_url'] != null)
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v['foto_url'], width: 44, height: 44, fit: BoxFit.cover))
                            else
                              const Icon(Icons.check_circle, size: 20, color: AppColors.action),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v['waktu'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text(v['catatan']?.toString().isNotEmpty == true ? v['catatan'] : '-', style: const TextStyle(fontSize: 12)),
                                  Text('Sales: ${v['nama_sales'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Belum ada riwayat kunjungan di lokasi ini.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
              ],
            ),
    );
  }
}
