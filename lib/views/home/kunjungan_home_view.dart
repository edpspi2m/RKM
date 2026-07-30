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
      final ok = await izinProvider.stop(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Status $jenis dinonaktifkan.' : (izinProvider.errorMessage ?? 'Gagal menonaktifkan.')),
          backgroundColor: ok ? AppColors.action : AppColors.error,
        ));
      }
      return;
    }
    if (izinProvider.jenisAktif != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Matikan status "${izinProvider.jenisAktif}" terlebih dahulu.')));
      return;
    }

    String keterangan = '';
    if (jenis == 'sakit') {
      final input = await showDialog<String>(
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
      if (input == null || input.isEmpty) return;
      keterangan = input;
    }

    final ok = await izinProvider.start(userId: userId, jenis: jenis, keterangan: keterangan);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Status $jenis diaktifkan.' : (izinProvider.errorMessage ?? 'Gagal mengaktifkan.')),
        backgroundColor: ok ? AppColors.action : AppColors.error,
        duration: const Duration(seconds: 4),
      ));
    }
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

  Widget _headerActionButton({required IconData icon, required String label, required VoidCallback onTap, bool active = false, Color? activeColor}) {
    final color = active ? (activeColor ?? AppColors.action) : Colors.white;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : Colors.white.withOpacity(0.35), width: 1.3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? color : Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: active ? color : Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.primary, // FLAT SOLID, tanpa gradient
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Selamat bekerja,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(nama, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileView())),
                          child: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.3),
                              image: fotoProfil != null ? DecorationImage(image: NetworkImage(fotoProfil), fit: BoxFit.cover) : null,
                            ),
                            child: fotoProfil == null
                                ? Center(child: Text(_getInitial(nama), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // ====== BARIS TOMBOL PENUH — jelas kelihatan sebagai tombol ======
                    Row(
                      children: [
                        _headerActionButton(icon: Icons.sick_outlined, label: 'Sakit', onTap: () => _toggleStatus('sakit'), active: izinProvider.jenisAktif == 'sakit', activeColor: AppColors.error),
                        _headerActionButton(icon: Icons.coffee_outlined, label: 'Istirahat', onTap: () => _toggleStatus('istirahat'), active: izinProvider.jenisAktif == 'istirahat', activeColor: AppColors.warning),
                        _headerActionButton(icon: Icons.route_outlined, label: 'Perjalanan', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RouteTrackingView()))),
                        if (isMaster)
                          _headerActionButton(icon: Icons.map_outlined, label: 'Tracking', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackingMapsView()))),
                      ],
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
                                  Container(color: AppColors.primary),
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
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.actionLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_a_photo_outlined, color: AppColors.action)),
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
                        decoration: BoxDecoration(color: AppColors.actionLight, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.storefront, color: AppColors.action, size: 22),
                            const SizedBox(height: 8),
                            Text('${memberProvider.members.where((m) => m.sudahKunjungan).length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.actionText)),
                            const Text('Kunjungan Hari Ini', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.people_outline, color: AppColors.primary, size: 22),
                            const SizedBox(height: 8),
                            Text('${memberProvider.members.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                  child: Row(
                    children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.stars_outlined, color: AppColors.warning)),
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
}
