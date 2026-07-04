import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/promo_provider.dart';

class PromoView extends StatefulWidget {
  const PromoView({super.key});

  @override
  State<PromoView> createState() => _PromoViewState();
}

class _PromoViewState extends State<PromoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoProvider>().load();
    });
  }

  String _formatRupiah(double? value) {
    if (value == null) return '-';
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Promo')),
      body: RefreshIndicator(
        onRefresh: () => context.read<PromoProvider>().load(),
        child: Builder(
          builder: (_) {
            if (provider.state == PromoState.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.state == PromoState.error) {
              return Center(child: Text(provider.errorMessage ?? 'Gagal memuat promo'));
            }
            if (provider.promoList.isEmpty) {
              return const Center(child: Text('Belum ada promo aktif'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.promoList.length,
              itemBuilder: (context, index) {
                final promo = provider.promoList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.promo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('PROMO',
                                style: TextStyle(color: AppColors.promo, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(promo.judul,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(promo.deskripsi, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (promo.hargaNormal != null)
                            Text(_formatRupiah(promo.hargaNormal),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          if (promo.hargaPromo != null)
                            Text(_formatRupiah(promo.hargaPromo),
                                style: const TextStyle(
                                    color: AppColors.action, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}