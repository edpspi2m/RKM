import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';

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

  Future<void> _buildRoute() async {
    final members = _membersWithLokasi;
    if (members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 2 member dengan lokasi diperlukan untuk membuat rute.')),
      );
      return;
    }

    setState(() => _buildingRoute = true);

    final coords = members.map((m) => '${m.longitude},${m.latitude}').join(';');
    final url = 'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body);
      final coordsList = json['routes'][0]['geometry']['coordinates'] as List;
      setState(() {
        _routePoints = coordsList.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        _buildingRoute = false;
      });
    } catch (e) {
      setState(() => _buildingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat rute, coba lagi.')));
      }
    }
  }

  Future<void> _openGoogleMaps(MemberModel m) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${m.latitude},${m.longitude}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openGoogleMaps(m),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Buka di Google Maps'),
              ),
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
            icon: _buildingRoute ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.alt_route),
            onPressed: _buildingRoute ? null : _buildRoute,
            tooltip: 'Buat Rute Kunjungan',
          ),
        ],
      ),
      body: memberProvider.state == MemberState.loading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Belum ada data lokasi member untuk Anda.', textAlign: TextAlign.center)))
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(members.first.latitude!, members.first.longitude!),
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.rkm.app',
                    ),
                    if (_routePoints != null)
                      PolylineLayer(polylines: [Polyline(points: _routePoints!, strokeWidth: 4, color: AppColors.primary)]),
                    MarkerLayer(
                      markers: members.map((m) {
                        return Marker(
                          point: LatLng(m.latitude!, m.longitude!),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showMemberSheet(m),
                            child: Icon(
                              m.sudahKunjungan ? Icons.check_circle : Icons.storefront,
                              color: m.sudahKunjungan ? AppColors.action : AppColors.error,
                              size: 32,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
    );
  }
}
