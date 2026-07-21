import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../kunjungan/kunjungan_form_view.dart';

class PotensialGetView extends StatefulWidget {
  const PotensialGetView({super.key});

  @override
  State<PotensialGetView> createState() => _PotensialGetViewState();
}

class _PotensialGetViewState extends State<PotensialGetView> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      final response = await context.read<ApiClient>().post('/potensial_get_list.php', body: {'user_id': userId});
      final list = (response['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _data = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Potensial Get'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Semua member sudah pernah dikunjungi.', textAlign: TextAlign.center)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final item = _data[index];
                    final member = MemberModel(
                      id: item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 0,
                      kodeMember: item['kode_member'] ?? '-',
                      nama: item['nama'] ?? '-',
                      kota: item['kota'],
                      latitude: item['latitude'] != null ? double.tryParse(item['latitude'].toString()) : null,
                      longitude: item['longitude'] != null ? double.tryParse(item['longitude'].toString()) : null,
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${item['kecamatan'] ?? '-'}, ${item['kota'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => KunjunganFormView(selectedMember: member))),
                            child: const Text('Kunjungi', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
