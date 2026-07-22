import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../kunjungan/kunjungan_form_view.dart';

class MemberView extends StatefulWidget {
  const MemberView({super.key});

  @override
  State<MemberView> createState() => _MemberViewState();
}

class _MemberViewState extends State<MemberView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      context.read<MemberProvider>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? '';
    final isMaster = authProvider.user?.role == 'master';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isMaster ? 'Semua Member (Master)' : 'Daftar Member')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (v) => context.read<MemberProvider>().search(v),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau kode member...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                if (provider.state == MemberState.success) ...[
                  const SizedBox(height: 10),
                  Text(
                    isMaster
                        ? '${provider.members.length} member dari semua salesman'
                        : '${provider.members.where((m) => !m.sudahKunjungan).length} member belum dikunjungi hari ini',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<MemberProvider>().load(userId),
              child: Builder(builder: (_) {
                if (provider.state == MemberState.loading) return const Center(child: CircularProgressIndicator());
                if (provider.state == MemberState.error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(provider.errorMessage ?? 'Gagal memuat data member', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                    ),
                  );
                }
                if (provider.members.isEmpty) return const Center(child: Text('Belum ada member terdaftar untuk Anda'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.members.length,
                  itemBuilder: (context, index) {
                    final member = provider.members[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: member.sudahKunjungan ? AppColors.action.withOpacity(0.3) : AppColors.divider),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: member.sudahKunjungan ? AppColors.action.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(member.sudahKunjungan ? Icons.check_circle : Icons.storefront_outlined, color: member.sudahKunjungan ? AppColors.action : AppColors.primary),
                        ),
                        title: Text(member.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Row(
                          children: [
                            Expanded(child: Text('${member.kodeMember} • ${member.kota ?? '-'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                            if (isMaster && member.salesman != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(member.salesman!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ],
                          ],
                        ),
                        trailing: member.sudahKunjungan
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.action.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Selesai', style: TextStyle(color: AppColors.action, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => KunjunganFormView(selectedMember: member))),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
