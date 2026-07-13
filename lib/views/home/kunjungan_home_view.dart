import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/promo_provider.dart';
import '../../data/models/promo_model.dart';
import '../kunjungan/kunjungan_form_view.dart';
import '../profile/profile_view.dart';
import '../tracking/share_location_view.dart';
import '../tracking/tracking_maps_view.dart';

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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(promo.gambarUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 180, color: AppColors.primaryLight)),
              ),
            const SizedBox(height: 16),
            Text(promo.judul, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(promo.deskripsi, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 14),
            Row(
              children: [
                if (promo.hargaNormal != null)
                  Text(_formatRupiah(promo.hargaNormal),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 8),
                if (promo.hargaPromo != null)
                  Text(_formatRupiah(promo.hargaPromo),
                      style: const TextStyle(color: AppColors.action, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            if (promo.tanggalMulai != null || promo.tanggalSelesai != null) ...[
              const SizedBox(height: 10),
              Text('Periode: ${promo.tanggalMulai ?? '-'} s/d ${promo.tanggalSelesai ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
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
    final nama = authProvider.user?.nama ?? 'Sales';
    final fotoProfil = authProvider.user?.fotoProfil;
    final isMaster = authProvider.user?.role == 'master';
    final belumList = memberProvider.members.where((m) => !m.sudahKunjungan).take(3).toList();
    final totalBelum = memberProvider.members.where((m) => !m.sudahKunjungan).length;

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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selamat bekerja,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(nama, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        if (isMaster)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TrackingMapsView()),
                              ),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                                ),
                                child: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ShareLocationView()),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              ),
                              child: const Icon(Icons.share_location_outlined, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileView()),
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              image: fotoProfil != null
                                  ? DecorationImage(image: NetworkImage(fotoProfil), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: fotoProfil == null
                                ? Center(
                                    child: Text(
                                      _getInitial(nama),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  )
                                : null,
                          ),
                        ),
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
                                  Image.network(promo.gambarUrl!, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: AppColors.primaryLight))
                                else
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.primary, AppColors.action],
                                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                                      begin: Alignment.bottomLeft, end: Alignment.topRight,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 16, right: 16, bottom: 14,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(promo.judul, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                      if (promo.hargaPromo != null) ...[
                                        const SizedBox(height: 2),
                                        Text('Mulai ${_formatRupiah(promo.hargaPromo)}',
                                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
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
                  children: List.generate(promoProvider.promoList.length, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _bannerIndex == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _bannerIndex == i ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KunjunganFormView()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: AppColors.action.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.action),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Buat Laporan Kunjungan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Foto, lokasi, dan catatan otomatis tercatat',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (belumList.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Belum Dikunjungi Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('$totalBelum toko', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ...belumList.map((m) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(m.nama, style: const TextStyle(fontSize: 13))),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => KunjunganFormView(selectedMember: m)),
                              ),
                              child: const Text('Kunjungi', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    )),
              ] else if (memberProvider.state == MemberState.success) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.action.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.action, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Semua member sudah dikunjungi hari ini.', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
