import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/potensial_get_provider.dart';
import '../kunjungan/kunjungan_form_view.dart';

class PotensialGetView extends StatefulWidget {
  const PotensialGetView({super.key});

  @override
  State<PotensialGetView> createState() => _PotensialGetViewState();
}

class _PotensialGetViewState extends State<PotensialGetView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<PotensialGetProvider>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PotensialGetProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('List Potensial Get')),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = context.read<AuthProvider>().user?.id ?? '';
          await context.read<PotensialGetProvider>().load(userId);
        },
        child: Builder(builder: (context) {
          if (provider.state == PotensialGetState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.members.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(40),
              children: const [
                SizedBox(height: 60),
                Icon(Icons.celebration_outlined, size: 56, color: AppColors.action),
                SizedBox(height: 12),
                Text(
                  'Semua member sudah pernah dikunjungi minimal 1 kali. Kerja bagus!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final m = provider.members[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            '${m.kecamatan ?? '-'}, ${m.kota ?? '-'}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => KunjunganFormView(selectedMember: m)),
                      ),
                      child: const Text('Kunjungi', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
