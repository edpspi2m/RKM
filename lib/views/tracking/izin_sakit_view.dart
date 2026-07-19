import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/services/izin_sakit_service.dart';
import '../../providers/auth_provider.dart';

class IzinSakitView extends StatefulWidget {
  const IzinSakitView({super.key});

  @override
  State<IzinSakitView> createState() => _IzinSakitViewState();
}

class _IzinSakitViewState extends State<IzinSakitView> {
  bool _isActive = false;
  String _jenis = 'izin';
  bool _loading = false;

  Future<void> _toggle(bool value) async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final service = IzinSakitService(context.read<ApiClient>());

    setState(() => _loading = true);
    try {
      if (value) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
        await service.start(userId: userId, jenis: _jenis, lat: pos.latitude, lng: pos.longitude);
      } else {
        await service.stop(userId);
      }
      setState(() { _isActive = value; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses. Pastikan GPS aktif.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Izin & Sakit')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
              child: Column(
                children: [
                  Icon(Icons.local_hospital_outlined, size: 44, color: _isActive ? AppColors.warning : AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(_isActive ? 'Status: Sedang $_jenis' : 'Tidak sedang izin/sakit', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  if (!_isActive)
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'izin', label: Text('Izin')),
                        ButtonSegment(value: 'sakit', label: Text('Sakit')),
                      ],
                      selected: {_jenis},
                      onSelectionChanged: (v) => setState(() => _jenis = v.first),
                    ),
                  const SizedBox(height: 16),
                  _loading
                      ? const CircularProgressIndicator()
                      : Switch(value: _isActive, activeColor: AppColors.warning, onChanged: _toggle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
