import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class NotGetMapView extends StatefulWidget {
  const NotGetMapView({super.key});

  @override
  State<NotGetMapView> createState() => _NotGetMapViewState();
}

class _NotGetMapViewState extends State<NotGetMapView> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post('/not_get_list.php', body: {});
      final list = (response['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _data = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _withLokasi =>
      _data.where((d) => d['latitude'] != null && d['longitude'] != null).toList();

  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['foto_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(item['foto_url'], height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 180, color: AppColors.inputFill)),
              ),
            const SizedBox(height: 14),
            Text(item['member'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${item['kecamatan'] ?? '-'}, ${item['kota'] ?? '-'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            Text('Alasan: ${item['catatan']?.toString().isNotEmpty == true ? item['catatan'] : '-'}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Text('Sales: ${item['nama_sales'] ?? '-'} • ${item['waktu']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Member Not Get'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Peta'), Tab(text: 'Daftar')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Gagal memuat data: $_error', textAlign: TextAlign.center)))
              : _data.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada laporan Not Get. Pastikan sales sudah mengirim laporan dengan tanda "Not Get" dicentang.', textAlign: TextAlign.center)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _withLokasi.isEmpty
                            ? const Center(child: Text('Data ada, tapi belum ada koordinat lokasi.'))
                            : FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(double.parse(_withLokasi.first['latitude'].toString()), double.parse(_withLokasi.first['longitude'].toString())),
                                  initialZoom: 11,
                                ),
                                children: [
                                  TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.rkm.app'),
                                  MarkerLayer(
                                    markers: _withLokasi.map((item) {
                                      final lat = double.parse(item['latitude'].toString());
                                      final lng = double.parse(item['longitude'].toString());
                                      return Marker(
                                        point: LatLng(lat, lng),
                                        width: 40, height: 40,
                                        child: GestureDetector(
                                          onTap: () => _showDetail(item),
                                          child: const Icon(Icons.location_on, color: AppColors.error, size: 36, shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _data.length,
                          itemBuilder: (context, index) {
                            final item = _data[index];
                            return GestureDetector(
                              onTap: () => _showDetail(item),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                                child: Row(
                                  children: [
                                    if (item['foto_url'] != null)
                                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['foto_url'], width: 48, height: 48, fit: BoxFit.cover))
                                    else
                                      Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.cancel_outlined, color: AppColors.error)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['member'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('${item['kecamatan'] ?? '-'}, ${item['kota'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          Text('Sales: ${item['nama_sales'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
    );
  }
}
