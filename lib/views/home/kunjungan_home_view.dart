import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/promo_provider.dart';
import '../../providers/izin_status_provider.dart';
import '../../data/models/promo_model.dart';
import '../kunjungan/kunjungan_form_view.dart';
import '../profile/profile_view.dart';
import '../tracking/route_tracking_view.dart';
import '../tracking/tracking_maps_view.dart';
import '../lokasi_member/potensial_get_view.dart';

class KunjunganHomeView extends StatefulWidget {
  const KunjunganHomeView({super.key});

  @override
  State<KunjunganHomeView> createState() => _KunjunganHomeViewState();
}

class _KunjunganHomeViewState extends State<KunjunganHomeView> {
  final PageController _bannerController = PageController(viewportFraction: 0.9);
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoProvider>().load();
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<MemberProvider>().load(userId);
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  String _getInitial(String nama) {
    if (nama.isEmpty) return '?';
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatRupiah(double? value) {
    if (value == null) return '-';
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _toggleStatus(String jenis) async {
    final izinProvider = context.read<IzinStatusProvider>();
    final userId = context.read<AuthProvider>().user?.id ?? '';

    if (izinProvider.jenisAktif == jenis) {
      await izinProvider.stop(userId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status $jenis dinonaktifkan.'), backgroundColor: AppColors.action));
      return;
    }
    if (izinProvider.jenisAktif != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Matikan status "${izinProvider.jenisAktif}" terlebih dahulu.')));
      return;
    }

    if (jenis == 'sakit') {
      final keterangan = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Keterangan Sakit'),
            content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Contoh: Demam, flu, dll'), maxLines: 2, autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Aktifkan')),
            ],
          );
        },
      );
      if (keterangan == null || keterangan.isEmpty) return;
      await izinProvider.start(userId: userId, jenis: 'sakit', keterangan: keterangan);
    } else {
      await izinProvider.start(userId: userId, jenis: 'istirahat', keterangan: '');
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status $jenis diaktifkan.'), backgroundColor: AppColors.warning));
  }

  void _showPromoDetail(PromoModel promo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (promo.gambarUrl != null)
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(promo.gambarUrl!, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 180, color: AppColors.primaryLight))),
            const SizedBox(height: 16),
            Text(promo.judul, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(promo.deskripsi, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 14),
            Row(children: [
              if (promo.hargaNormal != null) Text(_formatRupiah(promo.hargaNormal), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 8),
              if (promo.hargaPromo != null) Text(_formatRupiah(promo.hargaPromo), style: const TextStyle(color: AppColors.action, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final promoProvider = context.watch<PromoProvider>();
    final memberProvider = context.watch<MemberProvider>();
    final izinProvider = context.watch<IzinStatusProvider>();
    final nama = authProvider.user?.nama ?? 'Sales';
    final fotoProfil = authProvider.user?.fotoProfil;
    final isMaster = authProvider.user?.role == 'master';

    return Scaffold(
      backgroundColor: AppColors.background,
      // ====== HAMBURGER DRAWER — menggantikan icon numpuk di header ======
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.primary),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      backgroundImage: fotoProfil != null ? NetworkImage(fotoProfil) : null,
                      child: fotoProfil == null ? Text(_getInitial(nama), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(authProvider.user?.role ?? '-', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _drawerToggleTile(
                icon: Icons.sick_outlined,
                label: 'Sakit',
                subtitle: izinProvider.jenisAktif == 'sakit' ? 'Sedang aktif' : 'Ketuk untuk aktifkan',
                active: izinProvider.jenisAktif == 'sakit',
                color: AppColors.error,
                onTap: () => _toggleStatus('sakit'),
              ),
              _drawerToggleTile(
                icon: Icons.coffee_outlined,
                label: 'Istirahat',
                subtitle: izinProvider.jenisAktif == 'istirahat' ? 'Sedang aktif' : 'Ketuk untuk aktifkan',
                active: izinProvider.jenisAktif == 'istirahat',
                color: AppColors.warning,
                onTap: () => _toggleStatus('istirahat'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.route_outlined, color: AppColors.primary),
                title: const Text('Perjalanan'),
                subtitle: const Text('Rekam rute kunjungan', style: TextStyle(fontSize: 11)),
                onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RouteTrackingView())); },
              ),
              if (isMaster)
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: AppColors.primary),
                  title: const Text('Tracking Maps'),
                  subtitle: const Text('Khusus master', style: TextStyle(fontSize: 11)),
                  onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackingMapsView())); },
                ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.primary),
                title: const Text('Profil Saya'),
                onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileView())); },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<PromoProvider>().load();
            final userId = context.read<AuthProvider>().user?.id ?? '';
            await context.read<MemberProvider>().load(userId);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 24),
                decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selamat bekerja,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(nama, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Indikator kecil kalau status Sakit/Istirahat lagi aktif
                    if (izinProvider.jenisAktif != null)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Text(izinProvider.jenisAktif!.toUpperCase(), style: TextStyle(color: izinProvider.jenisAktif == 'sakit' ? AppColors.error : AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (promoProvider.promoList.isNotEmpty) ...[
                SizedBox(
                  height: 140,
                  child: PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (i) => setState(() => _bannerIndex = i),
                    itemCount: promoProvider.promoList.length,
                    itemBuilder: (context, index) {
                      final promo = promoProvider.promoList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => _showPromoDetail(promo),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (promo.gambarUrl != null)
                                  Image.network(promo.gambarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.primaryLight))
                                else
                                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.action], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                                DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.55), Colors.transparent], begin: Alignment.bottomLeft, end: Alignment.topRight))),
                                Positioned(
                                  left: 16, right: 16, bottom: 14,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(promo.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                      if (promo.hargaPromo != null) ...[const SizedBox(height: 2), Text('Mulai ${_formatRupiah(promo.hargaPromo)}', style: const TextStyle(color: Colors.white, fontSize: 12))],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(promoProvider.promoList.length, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: _bannerIndex == i ? 18 : 6, height: 6, decoration: BoxDecoration(color: _bannerIndex == i ? AppColors.primary : AppColors.divider, borderRadius: BorderRadius.circular(4)))),
                ),
                const SizedBox(height: 20),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KunjunganFormView())),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                    child: Row(
                      children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.action.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_a_photo_outlined, color: AppColors.action)),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Buat Laporan Kunjungan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Foto, lokasi, dan catatan otomatis tercatat', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.storefront, color: AppColors.action, size: 22),
                            const SizedBox(height: 8),
                            Text('${memberProvider.members.where((m) => m.sudahKunjungan).length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('Kunjungan Hari Ini', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.people_outline, color: AppColors.primary, size: 22),
                            const SizedBox(height: 8),
                            Text('${memberProvider.members.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Text('Total Member Saya', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PotensialGetView())),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.action.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.action.withOpacity(0.25))),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.action.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.stars_outlined, color: AppColors.action)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('List Potensial Get', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Member yang belum pernah dikunjungi', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerToggleTile({required IconData icon, required String label, required String subtitle, required bool active, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: active ? color.withOpacity(0.1) : null, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: active ? color : AppColors.textSecondary),
        title: Text(label, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: active ? color : AppColors.textSecondary)),
        trailing: Switch(value: active, activeColor: color, onChanged: (_) => onTap()),
        onTap: onTap,
      ),
    );
  }
}
