import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/state_placeholder.dart';
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
      final username = context.read<AuthProvider>().user?.username ?? '';
      context.read<MemberProvider>().load(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final username = context.read<AuthProvider>().user?.username ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Member')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => context.read<MemberProvider>().search(v),
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode member...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<MemberProvider>().load(username),
              child: Builder(builder: (_) {
                if (provider.state == MemberState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.state == MemberState.error) {
                  return StatePlaceholder.error(
                    message: provider.errorMessage ?? 'Gagal memuat data member',
                    onRetry: () => context.read<MemberProvider>().load(username),
                  );
                }
                if (provider.members.isEmpty) {
                  return StatePlaceholder.empty(
                    title: 'Belum ada member terdaftar',
                    message: 'Member yang terdaftar untuk akun Anda akan muncul di sini.',
                  );
                }
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
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                        ),
                        title: Text(member.nama,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          '${member.kodeMember} • ${member.kota ?? '-'}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KunjunganFormView(selectedMember: member),
                            ),
                          );
                        },
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
