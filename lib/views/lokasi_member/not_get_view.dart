import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class NotGetView extends StatefulWidget {
  const NotGetView({super.key});

  @override
  State<NotGetView> createState() => _NotGetViewState();
}

class _NotGetViewState extends State<NotGetView> {
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
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.post('/not_get_list.php', body: {});
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
      appBar: AppBar(title: const Text('Member Not Get')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _data.isEmpty
                  ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Belum ada data.')))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (context, index) {
                        final item = _data[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item['member'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('${item['kecamatan'] ?? '-'}, ${item['kota'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Alasan: ${item['catatan']?.toString().isNotEmpty == true ? item['catatan'] : '-'}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Text('Sales: ${item['nama_sales'] ?? '-'} • ${item['waktu']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
