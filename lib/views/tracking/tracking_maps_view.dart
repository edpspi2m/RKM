import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/services/tracking_maps_service.dart';
import '../../providers/auth_provider.dart';

class TrackingMapsView extends StatefulWidget {
  const TrackingMapsView({super.key});

  @override
  State<TrackingMapsView> createState() => _TrackingMapsViewState();
}

class _TrackingMapsViewState extends State<TrackingMapsView> {
  Timer? _timer;
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  String? _error;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final service = TrackingMapsService(context.read<ApiClient>());
    try {
      final data = await service.fetchLiveLocations(userId);
      if (mounted) {
        setState(() {
          _locations = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tracking Maps'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gagal memuat: $_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(-7.8, 112.0),
                        initialZoom: 11,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.rkm.app',
                        ),
                        MarkerLayer(
                          markers: _locations.map((loc) {
                            final lat = double.tryParse(loc['latitude'].toString()) ?? 0;
                            final lng = double.tryParse(loc['longitude'].toString()) ?? 0;
                            return Marker(
                              point: LatLng(lat, lng),
                              width: 140,
                              height: 60,
                              child: GestureDetector(
                                onTap: () => _showDetail(loc),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                      child: Text(loc['nama'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
                                    ),
                                    const Icon(Icons.location_on, color: AppColors.primary, size: 30),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (_locations.isEmpty)
                      const Positioned(
                        top: 16, left: 16, right: 16,
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Belum ada sales yang aktif membagikan lokasi (aktifkan "Rekam Rute Perjalanan" di HP sales).',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  void _showDetail(Map<String, dynamic> loc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc['nama'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Update terakhir: ${loc['updated_at']} WIB', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
