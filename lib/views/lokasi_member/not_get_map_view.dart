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

class _NotGetMapViewState extends State<NotGetMapView> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post('/not_get_list.php', body: {});
      final list = (response['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _data = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
    final markers = _withLokasi;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Peta Not Get'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : markers.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada laporan Not Get.', textAlign: TextAlign.center)))
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(double.parse(markers.first['latitude'].toString()), double.parse(markers.first['longitude'].toString())),
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.rkm.app'),
                    MarkerLayer(
                      markers: markers.map((item) {
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
    );
  }
}
