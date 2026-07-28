import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/api_constant.dart';
import 'not_get_detail_view.dart';

class NotGetMapView extends StatefulWidget {
  const NotGetMapView({super.key});

  @override
  State<NotGetMapView> createState() => _NotGetMapViewState();
}

class _NotGetMapViewState extends State<NotGetMapView> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  int? _httpStatusCode;
  bool _satelit = false;
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
    setState(() { _loading = true; _error = null; _httpStatusCode = null; });

    try {
      // Panggil LANGSUNG via http (bukan lewat wrapper) supaya kalau ada
      // masalah, status code & body mentah kelihatan jelas, tidak
      // disamarkan jadi "list kosong" oleh lapisan lain.
      final response = await http.post(
        Uri.parse('${ApiConstant.baseUrl}/not_get_list.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      _httpStatusCode = response.statusCode;

      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = 'Server merespon status ${response.statusCode}.\nIsi respons: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}';
        });
        return;
      }

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        setState(() {
          _loading = false;
          _error = 'Respons server BUKAN JSON valid (kemungkinan ada teks/error PHP nyempil).\nAwal respons: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}';
        });
        return;
      }

      if (json['success'] != true) {
        setState(() { _loading = false; _error = 'Server: ${json['message'] ?? 'gagal tanpa pesan'}'; });
        return;
      }

      final list = (json['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = 'Gagal konek ke server: $e'; });
    }
  }

  List<Map<String, dynamic>> get _withLokasi => _data.where((d) => d['latitude'] != null && d['longitude'] != null).toList();

  void _showDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotGetDetailView(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Member Not Get'),
        actions: [
          IconButton(icon: Icon(_satelit ? Icons.map_outlined : Icons.satellite_alt_outlined), onPressed: () => setState(() => _satelit = !_satelit)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Peta'), Tab(text: 'Daftar')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                        const SizedBox(height: 12),
                        const Text('Gagal memuat data (ERROR, bukan kosong)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : _data.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Data kosong (server menjawab benar, memang belum ada laporan Not Get).', textAlign: TextAlign.center)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _withLokasi.isEmpty
                            ? const Center(child: Text('Data ada, tapi belum ada koordinat lokasi.'))
                            : FlutterMap(
                                options: MapOptions(initialCenter: LatLng(double.parse(_withLokasi.first['latitude'].toString()), double.parse(_withLokasi.first['longitude'].toString())), initialZoom: 11),
                                children: [
                                  _satelit
                                      ? TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: 'com.rkm.app')
                                      : TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.rkm.app'),
                                  MarkerLayer(
                                    markers: _withLokasi.map((item) {
                                      final lat = double.tryParse(item['latitude'].toString()) ?? 0;
                                      final lng = double.tryParse(item['longitude'].toString()) ?? 0;
                                      final fotoUrl = item['foto_url'];
                                      return Marker(
                                        point: LatLng(lat, lng), width: 50, height: 50,
                                        child: GestureDetector(
                                          onTap: () => _showDetail(item),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle, border: Border.all(color: AppColors.error, width: 3), color: Colors.white,
                                              image: fotoUrl != null ? DecorationImage(image: NetworkImage(fotoUrl), fit: BoxFit.cover) : null,
                                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                            ),
                                            child: fotoUrl == null ? const Icon(Icons.cancel, color: AppColors.error, size: 24) : null,
                                          ),
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
