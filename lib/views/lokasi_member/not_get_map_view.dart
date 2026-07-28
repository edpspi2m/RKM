import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';

class NotGetMapView extends StatefulWidget {
  const NotGetMapView({super.key});

  @override
  State<NotGetMapView> createState() => _NotGetMapViewState();
}

class _NotGetMapViewState extends State<NotGetMapView> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _tabController;
  List<MemberModel> _notGetMembers = [];
  bool _isLoading = true;
  bool _satelit = false; // <-- STATE SATELIT

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      final apiClient = context.read<ApiClient>();
      
      // Sesuaikan endpoint API dengan backend kamu
      final response = await apiClient.post('/get_not_get_members.php', body: {
        'user_id': userId,
      });

      if (response['status'] == 'success') {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _notGetMembers = data.map((e) => MemberModel.fromJson(e)).toList()
            ..removeWhere((m) => m.latitude == null || m.longitude == null); // Hanya ambil yang ada koordinatnya
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data member not get.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMemberDetail(MemberModel m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel, color: AppColors.error),
                const SizedBox(width: 8),
                Text(m.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Kode: ${m.kodeMember} • Kota: ${m.kota ?? '-'}', 
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)
            ),
            const Divider(height: 24),
            const Text('Status: Belum Dikunjungi (Not Get)', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            )
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
        actions: [
          IconButton(
            icon: Icon(_satelit ? Icons.map_outlined : Icons.satellite_alt_outlined),
            tooltip: _satelit ? 'Tampilan Peta Biasa' : 'Tampilan Satelit',
            onPressed: () => setState(() => _satelit = !_satelit), // <-- TOGGLE SATELIT
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Peta'),
            Tab(icon: Icon(Icons.list), text: 'Daftar'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PETA
                _notGetMembers.isEmpty
                    ? const Center(child: Text('Tidak ada member dengan status Not Get.'))
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            _notGetMembers.first.latitude!,
                            _notGetMembers.first.longitude!
                          ),
                          initialZoom: 12,
                        ),
                        children: [
                          _satelit // <-- IMPLEMENTASI TILE SATELIT
                              ? TileLayer(
                                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                  userAgentPackageName: 'com.rkm.app',
                                )
                              : TileLayer(
                                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c'],
                                  userAgentPackageName: 'com.rkm.app',
                                ),
                          MarkerLayer(
                            markers: _notGetMembers.map((m) {
                              return Marker(
                                point: LatLng(m.latitude!, m.longitude!),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showMemberDetail(m),
                                  child: const Icon(
                                    Icons.location_on, 
                                    color: AppColors.error, 
                                    size: 40,
                                    shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))]
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                
                // TAB 2: DAFTAR
                _notGetMembers.isEmpty
                    ? const Center(child: Text('Tidak ada member dengan status Not Get.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notGetMembers.length,
                        itemBuilder: (context, index) {
                          final m = _notGetMembers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFEE2E2),
                                child: Icon(Icons.cancel, color: AppColors.error),
                              ),
                              title: Text(m.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${m.kodeMember} • ${m.kota ?? '-'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.location_searching, color: Colors.blue),
                                onPressed: () {
                                  _tabController.animateTo(0);
                                  _mapController.move(LatLng(m.latitude!, m.longitude!), 16.0);
                                },
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
