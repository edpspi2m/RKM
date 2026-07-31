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
  String _statusPin = 'potensial';
  bool _sudahMember = false;
  String? _namaMember;
  String? _kodeMember;
  int _totalKunjungan = 0;
  List<Map<String, dynamic>> _riwayat = [];
  Map<String, dynamic>? _notGetInfo;
  List<Map<String, dynamic>> _riwayatPotensi = [];

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
      
      try {
        final responseP = await context.read<ApiClient>().post('/potensi_kunjungan_detail.php', body: {'potensi_id': widget.item['id'].toString()});
        if (mounted) setState(() => _riwayatPotensi = (responseP['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      } catch (_) {}

      if (mounted) {
        setState(() {
          _statusPin = response['status_pin'] ?? 'potensial';
          _sudahMember = response['sudah_member'] == true;
          _namaMember = response['nama_member'];
          _kodeMember = response['kode_member'];
          _totalKunjungan = response['total_kunjungan'] as int? ?? 0;
          _riwayat = (response['riwayat'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          _notGetInfo = response['not_get_info'] as Map<String, dynamic>?;
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

  (String, Color, IconData) get _statusInfo {
    switch (_statusPin) {
      case 'member': return ('Sudah Menjadi Member', AppColors.action, Icons.verified);
      case 'not_get': return ('Sudah Dilaporkan Not Get', AppColors.error, Icons.cancel);
      default: return ('Belum Pernah Disentuh — Potensial', AppColors.warning, Icons.explore_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusIcon) = _statusInfo;

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
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: statusColor.withOpacity(0.3))),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 36, color: statusColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: statusColor)),
                            const SizedBox(height: 2),
                            Text(_sudahMember ? '$_namaMember ${_kodeMember != null ? "($_kodeMember)" : ""}' : widget.item['nama'] ?? 'Lokasi Potensial', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_notGetInfo != null) ...[
                  const Text('Info Laporan Not Get', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error)),
                  const SizedBox(height: 8),
                  if (_notGetInfo!['foto_url'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(_notGetInfo!['foto_url'], height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 150, color: AppColors.inputFill)),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Toko: ${_notGetInfo!['toko'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Alasan: ${_notGetInfo!['alasan']?.toString().isNotEmpty == true ? _notGetInfo!['alasan'] : '-'}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Sales: ${_notGetInfo!['sales'] ?? '-'} • ${_notGetInfo!['waktu'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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
                  ..._riwayat.map((v) {
                    final isNotGet = v['status_kunjungan'] == 'not_get';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                      child: Row(
                        children: [
                          if (v['foto_url'] != null)
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v['foto_url'], width: 44, height: 44, fit: BoxFit.cover))
                          else
                            Icon(isNotGet ? Icons.cancel : Icons.check_circle, size: 20, color: isNotGet ? AppColors.error : AppColors.action),
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
                    );
                  }),
                ],
                
                if (_riwayatPotensi.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Riwayat Kunjungan Lokasi Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._riwayatPotensi.map((v) => Container(
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
                ],
              ],
            ),
    );
  }
}
