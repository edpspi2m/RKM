import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class PotensiDetailView extends StatefulWidget {
  final Map<String, dynamic> item;
  const PotensiDetailView({super.key, required this.item});

  @override
  State<PotensiDetailView> createState() => _PotensiDetailViewState();
}

class _PotensiDetailViewState extends State<PotensiDetailView> {
  bool _loading = true;
  bool _sudahMember = false;
  String? _namaMember;
  String? _kodeMember;
  int _totalKunjungan = 0;
  List<Map<String, dynamic>> _riwayat = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final response = await context.read<ApiClient>().post('/potensi_lokasi_detail.php', body: {
        'latitude': widget.item['latitude'].toString(),
        'longitude': widget.item['longitude'].toString(),
      });
      if (mounted) {
        setState(() {
          _sudahMember = response['sudah_member'] == true;
          _namaMember = response['nama_member'];
          _kodeMember = response['kode_member'];
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
                    color: _sudahMember ? AppColors.action.withOpacity(0.08) : AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _sudahMember ? AppColors.action.withOpacity(0.3) : AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_sudahMember ? Icons.verified : Icons.explore_outlined, size: 36, color: _sudahMember ? AppColors.action : AppColors.warning),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_sudahMember ? 'Sudah Menjadi Member' : 'Belum Menjadi Member', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _sudahMember ? AppColors.action : AppColors.warning)),
                            const SizedBox(height: 2),
                            Text(
                              _sudahMember ? '$_namaMember ${_kodeMember != null ? "($_kodeMember)" : ""}' : widget.item['nama'] ?? 'Lokasi Potensial',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
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
                        child: Column(children: [
                          Text('$_totalKunjungan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const Text('Total Kunjungan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                        child: Column(children: [
                          Text(widget.item['kode_area'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const Text('Kode Area', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _bukaNavigasi,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Rute ke Lokasi Ini'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Riwayat Kunjungan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_riwayat.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Belum pernah dikunjungi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  )
                else
                  ..._riwayat.map((v) {
                    final isNotGet = v['status_kunjungan'] == 'not_get';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(isNotGet ? Icons.cancel : Icons.check_circle, size: 14, color: isNotGet ? AppColors.error : AppColors.action),
                            const SizedBox(width: 6),
                            Text(v['waktu'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          Text(v['catatan']?.toString().isNotEmpty == true ? v['catatan'] : '-', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Sales: ${v['nama_sales'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
