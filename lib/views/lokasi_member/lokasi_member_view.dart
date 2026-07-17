import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import 'not_get_view.dart';

class LokasiMemberView extends StatefulWidget {
  const LokasiMemberView({super.key});

  @override
  State<LokasiMemberView> createState() => _LokasiMemberViewState();
}

class _LokasiMemberViewState extends State<LokasiMemberView> {
  List<LatLng>? _routePoints;
  bool _buildingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<MemberProvider>().load(userId);
    });
  }

  List<MemberModel> get _membersWithLokasi {
    return context.watch<MemberProvider>().members.where((m) => m.latitude != null && m.longitude != null).toList();
  }

  Future<void> _routeToMember(MemberModel m) async {
    setState(() => _buildingRoute = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      final url = 'https://router.project-osrm.org/route/v1/driving/${pos.longitude},${pos.latitude};${m.longitude},${m.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body);
      final coordsList = json['routes'][0]['geometry']['coordinates'] as List;
      setState(() {
        _routePoints = coordsList.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        _buildingRoute = false;
      });
    } catch (e) {
      setState(() => _buildingRoute = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat rute. Pastikan GPS aktif.')));
    }
  }

  Future<void> _openGoogleMaps(MemberModel m) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${m.latitude},${m.longitude}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showVisitDetail(MemberModel m) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    List<Map<String, dynamic>> visits = [];
    int total = 0;
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post('/member_visit_detail.php', body: {'member': m.nama});
      visits = (response['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      total = response['total_kunjungan'] as int? ?? visits.length;
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Total kunjungan: $total kali', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              const Divider(height: 24),
              Expanded(
                child: visits.isEmpty
                    ? const Center(child: Text('Belum pernah dikunjungi.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: visits.length,
                        itemBuilder: (context, index) {
                          final v = visits[index];
                          final isNotGet = v['status_kunjungan'] == 'not_get';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(isNotGet ? Icons.cancel : Icons.check_circle, size: 14, color: isNotGet ? AppColors.error : AppColors.action),
                                    const SizedBox(width: 6),
                                    Text(v['waktu'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(v['catatan']?.toString().isNotEmpty == true ? v['catatan'] : '-', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 2),
                                Text('Sales: ${v['nama_sales'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberSheet(MemberModel m) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${m.kodeMember} • ${m.kota ?? '-'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.of(ctx).pop(); _routeToMember(m); },
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Rute ke Lokasi Ini'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { Navigator.of(ctx).pop(); _showVisitDetail(m); },
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Lihat Riwayat Kunjungan'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _openGoogleMaps(m),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Buka di Google Maps', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();
    final members = _membersWithLokasi;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lokasi Member'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            tooltip: 'Member Not Get',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotGetView())),
          ),
        ],
      ),
      body: memberProvider.state == MemberState.loading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada data lokasi member untuk Anda.', textAlign: TextAlign.center)))
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(initialCenter: LatLng(members.first.latitude!, members.first.longitude!), initialZoom: 12),
                      children: [
                        TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.rkm.app'),
                        if (_routePoints != null) PolylineLayer(polylines: [Polyline(points: _routePoints!, strokeWidth: 4, color: AppColors.primary)]),
                        MarkerLayer(
                          markers: members.map((m) {
                            return Marker(
                              point: LatLng(m.latitude!, m.longitude!),
                              width: 36, height: 44, alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _showMemberSheet(m),
                                child: Icon(Icons.location_on, color: m.sudahKunjungan ? AppColors.action : AppColors.error, size: 40, shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (_buildingRoute) const Center(child: CircularProgressIndicator()),
                  ],
                ),
    );
  }
}
