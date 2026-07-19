import 'dart:async';
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

const _kBlue = Color(0xFF1E88E5);

class LokasiMemberView extends StatefulWidget {
  const LokasiMemberView({super.key});

  @override
  State<LokasiMemberView> createState() => _LokasiMemberViewState();
}

class _LokasiMemberViewState extends State<LokasiMemberView> {
  List<LatLng>? _routePoints;
  bool _buildingRoute = false;
  MemberModel? _navigatingTo;
  double? _distanceMeters;
  Timer? _distanceTimer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<MemberProvider>().load(userId);
    });
  }

  @override
  void dispose() {
    _distanceTimer?.cancel();
    super.dispose();
  }

  List<MemberModel> get _membersWithLokasi {
    return context.watch<MemberProvider>().members.where((m) => m.latitude != null && m.longitude != null).toList();
  }

  Future<void> _startNavigation(MemberModel m) async {
    setState(() { _buildingRoute = true; _navigatingTo = m; });
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      final url = 'https://router.project-osrm.org/route/v1/driving/${pos.longitude},${pos.latitude};${m.longitude},${m.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body);
      final coordsList = json['routes'][0]['geometry']['coordinates'] as List;
      final points = coordsList.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

      setState(() {
        _routePoints = points;
        _buildingRoute = false;
        _distanceMeters = Geolocator.distanceBetween(pos.latitude, pos.longitude, m.latitude!, m.longitude!);
      });

      _mapController.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(60)));

      _distanceTimer?.cancel();
      _distanceTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          final p = await Geolocator.getCurrentPosition();
          if (mounted && _navigatingTo != null) {
            setState(() {
              _distanceMeters = Geolocator.distanceBetween(p.latitude, p.longitude, _navigatingTo!.latitude!, _navigatingTo!.longitude!);
            });
          }
        } catch (_) {}
      });
    } catch (e) {
      setState(() { _buildingRoute = false; _navigatingTo = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat rute. Pastikan GPS aktif.')));
    }
  }

  void _cancelNavigation() {
    _distanceTimer?.cancel();
    setState(() { _navigatingTo = null; _routePoints = null; _distanceMeters = null; });
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
      context: context, isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Total kunjungan: $total kali', style: const TextStyle(color: _kBlue, fontSize: 13, fontWeight: FontWeight.w600)),
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
                onPressed: () { Navigator.of(ctx).pop(); _startNavigation(m); },
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Rute ke Lokasi Ini'),
                style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white),
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

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();
    final allMembers = _membersWithLokasi;
    final visibleMembers = _navigatingTo != null ? [_navigatingTo!] : allMembers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lokasi Member')),
      body: memberProvider.state == MemberState.loading
          ? const Center(child: CircularProgressIndicator())
          : allMembers.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada data lokasi member untuk Anda.', textAlign: TextAlign.center)))
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(initialCenter: LatLng(allMembers.first.latitude!, allMembers.first.longitude!), initialZoom: 12),
                      children: [
                        TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.rkm.app'),
                        if (_routePoints != null) PolylineLayer(polylines: [Polyline(points: _routePoints!, strokeWidth: 5, color: _kBlue)]),
                        MarkerLayer(
                          markers: visibleMembers.map((m) {
                            final color = m.sudahKunjungan ? AppColors.action : _kBlue;
                            return Marker(
                              point: LatLng(m.latitude!, m.longitude!),
                              width: 36, height: 44, alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _navigatingTo == null ? _showMemberSheet(m) : null,
                                child: Icon(Icons.location_on, color: color, size: 40, shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]),
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
                                decoration: BoxDecoration(color: _kBlue.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.navigation, color: _kBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_navigatingTo!.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (_distanceMeters != null)
                                      Text('Jarak: ${_formatDistance(_distanceMeters!)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _cancelNavigation,
                                icon: const Icon(Icons.close, color: AppColors.error),
                                tooltip: 'Batalkan navigasi',
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
