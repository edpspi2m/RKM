import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../kunjungan/kunjungan_form_view.dart';
import 'potensi_detail_view.dart';

class PotensialGetView extends StatefulWidget {
  const PotensialGetView({super.key});

  @override
  State<PotensialGetView> createState() => _PotensialGetViewState();
}

class _PotensialGetViewState extends State<PotensialGetView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _potensiData = [];
  bool _loadingPotensi = true;
  bool _satelit = false;
  final MapController _mapController = MapController();
  List<LatLng>? _routePoints;
  Map<String, dynamic>? _navigatingTo;
  double? _distanceMeters;
  bool _buildingRoute = false;

  List<Map<String, dynamic>> _memberData = [];
  bool _loadingMember = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
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

  Future<void> _startNavigation(Map<String, dynamic> item) async {
    setState(() { _buildingRoute = true; _navigatingTo = item; });
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      final destLat = item['latitude'];
      final destLng = item['longitude'];
      final url = 'https://router.project-osrm.org/route/v1/driving/${pos.longitude},${pos.latitude};$destLng,$destLat?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body);
      final coordsList = json['routes'][0]['geometry']['coordinates'] as List;
      final points = coordsList.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

      setState(() {
        _routePoints = points;
        _buildingRoute = false;
        _distanceMeters = Geolocator.distanceBetween(pos.latitude, pos.longitude, double.parse(destLat.toString()), double.parse(destLng.toString()));
      });
      _mapController.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(60)));
    } catch (e) {
      setState(() { _buildingRoute = false; _navigatingTo = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat rute. Pastikan GPS aktif.')));
    }
  }

  void _cancelNavigation() {
    setState(() { _navigatingTo = null; _routePoints = null; _distanceMeters = null; });
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _showMarkerSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['nama'] ?? 'Lokasi Potensial', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.of(ctx).pop(); _startNavigation(item); },
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Rute ke Lokasi Ini'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => PotensiDetailView(item: item))); },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Lihat Detail & Riwayat'),
              ),
            ),
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
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(double.parse(_potensiData.first['latitude'].toString()), double.parse(_potensiData.first['longitude'].toString())),
                            initialZoom: 13,
                          ),
                          children: [
                            _satelit
                                ? TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: 'com.rkm.app')
                                : TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.rkm.app'),
                            if (_routePoints != null) PolylineLayer(polylines: [Polyline(points: _routePoints!, strokeWidth: 5, color: AppColors.primary)]),
                            MarkerLayer(
                              markers: (_navigatingTo != null ? [_navigatingTo!] : _potensiData).map((item) {
                                final lat = double.parse(item['latitude'].toString());
                                final lng = double.parse(item['longitude'].toString());
                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 38, height: 46,
                                  alignment: Alignment.topCenter,
                                  child: GestureDetector(
                                    onTap: () => _navigatingTo == null ? _showMarkerSheet(item) : null,
                                    child: const Icon(Icons.location_on, color: AppColors.error, size: 38, shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        if (_buildingRoute) const Center(child: CircularProgressIndicator()),
                        if (_navigatingTo != null && !_buildingRoute)
                          Positioned(
                            left: 16, right: 16, bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))]),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.navigation, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_navigatingTo!['nama'] ?? 'Lokasi Potensial', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        if (_distanceMeters != null) Text('Jarak: ${_formatDistance(_distanceMeters!)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  IconButton(onPressed: _cancelNavigation, icon: const Icon(Icons.close, color: AppColors.error)),
                                ],
                              ),
                            ),
                          ),
                      ],
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
