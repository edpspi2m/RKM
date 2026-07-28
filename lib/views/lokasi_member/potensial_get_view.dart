import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../kunjungan/kunjungan_form_view.dart';

class PotensialGetView extends StatefulWidget {
  const PotensialGetView({super.key});

  @override
  State<PotensialGetView> createState() => _PotensialGetViewState();
}

class _PotensialGetViewState extends State<PotensialGetView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: peta titik potensi dari Excel
  List<Map<String, dynamic>> _potensiData = [];
  bool _loadingPotensi = true;
  bool _satelit = false;

  // Tab 2: member yang belum pernah dikunjungi
  List<Map<String, dynamic>> _memberData = [];
  bool _loadingMember = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPotensi();
    _loadMember();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPotensi() async {
    setState(() => _loadingPotensi = true);
    try {
      final response = await context.read<ApiClient>().post('/potensi_lokasi_list.php', body: {});
      final list = (response['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _potensiData = list; _loadingPotensi = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPotensi = false);
    }
  }

  Future<void> _loadMember() async {
    setState(() => _loadingMember = true);
    try {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      final response = await context.read<ApiClient>().post('/potensial_get_list.php', body: {'user_id': userId});
      final list = (response['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _memberData = list; _loadingMember = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMember = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Potensial Get'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Peta Potensi'), Tab(text: 'Belum Dikunjungi')]),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(_satelit ? Icons.map_outlined : Icons.satellite_alt_outlined),
              tooltip: _satelit ? 'Tampilan Peta Biasa' : 'Tampilan Satelit',
              onPressed: () => setState(() => _satelit = !_satelit),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loadingPotensi
              ? const Center(child: CircularProgressIndicator())
              : _potensiData.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada data lokasi potensi. Admin bisa upload Excel di web.', textAlign: TextAlign.center)))
                  : StatefulBuilder(
                      builder: (context, setLocalState) => FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(double.parse(_potensiData.first['latitude'].toString()), double.parse(_potensiData.first['longitude'].toString())),
                          initialZoom: 13,
                        ),
                        children: [
                          _satelit
                              ? TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: 'com.rkm.app')
                              : TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.rkm.app'),
                          MarkerLayer(
                            markers: _potensiData.map((item) {
                              final lat = double.parse(item['latitude'].toString());
                              final lng = double.parse(item['longitude'].toString());
                              return Marker(
                                point: LatLng(lat, lng),
                                width: 34, height: 34,
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (ctx) => Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['nama'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text('${item['latitude']}, ${item['longitude']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.star, color: Colors.amber, size: 30, shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))]),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
          _loadingMember
              ? const Center(child: CircularProgressIndicator())
              : _memberData.isEmpty
                  ? const Center(child: Text('Semua member sudah pernah dikunjungi.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _memberData.length,
                      itemBuilder: (context, index) {
                        final item = _memberData[index];
                        final member = MemberModel(
                          id: int.tryParse(item['id'].toString()) ?? 0,
                          kodeMember: item['kode_member'] ?? '-',
                          nama: item['nama'] ?? '-',
                          kota: item['kota'],
                          latitude: item['latitude'] != null ? double.tryParse(item['latitude'].toString()) : null,
                          longitude: item['longitude'] != null ? double.tryParse(item['longitude'].toString()) : null,
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_outlined, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('${item['kecamatan'] ?? '-'}, ${item['kota'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => KunjunganFormView(selectedMember: member))),
                                child: const Text('Kunjungi', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
