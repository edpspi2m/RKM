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
  bool _istirahatOn = false;
  bool _izinOn = false;
  bool _izinPending = false; // menunggu keterangan diisi sebelum aktif
  final _keteranganController = TextEditingController();
  bool _loading = false;

  Future<void> _toggleIstirahat(bool value) async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final service = IzinSakitService(context.read<ApiClient>());
    setState(() => _loading = true);
    try {
      if (value) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
        await service.start(userId: userId, jenis: 'istirahat', lat: pos.latitude, lng: pos.longitude, keterangan: '');
      } else {
        await service.stop(userId);
      }
      setState(() { _istirahatOn = value; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal, pastikan GPS aktif.')));
    }
  }

  void _onIzinToggle(bool value) {
    if (value) {
      setState(() => _izinPending = true); // munculkan field keterangan dulu
    } else {
      _konfirmasiMatikanIzin();
    }
  }

  Future<void> _konfirmasiIzin() async {
    if (_keteranganController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi keterangan izin terlebih dahulu.')));
      return;
    }
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final service = IzinSakitService(context.read<ApiClient>());
    setState(() => _loading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      await service.start(userId: userId, jenis: 'izin', lat: pos.latitude, lng: pos.longitude, keterangan: _keteranganController.text.trim());
      setState(() { _izinOn = true; _izinPending = false; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal, pastikan GPS aktif.')));
    }
  }

  Future<void> _konfirmasiMatikanIzin() async {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final service = IzinSakitService(context.read<ApiClient>());
    setState(() => _loading = true);
    await service.stop(userId);
    setState(() { _izinOn = false; _izinPending = false; _keteranganController.clear(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Istirahat & Izin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                  child: Row(children: [
                    const Icon(Icons.coffee_outlined, color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Istirahat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    Switch(value: _istirahatOn, activeColor: AppColors.warning, onChanged: _izinOn ? null : _toggleIstirahat),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.event_busy_outlined, color: AppColors.error, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Izin (Sakit/Cuti/dll)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        Switch(value: _izinOn, activeColor: AppColors.error, onChanged: _istirahatOn ? null : _onIzinToggle),
                      ]),
                      // Field otomatis muncul begitu toggle Izin dinyalakan.
                      if (_izinPending && !_izinOn) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _keteranganController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Keterangan Izin (wajib)',
                            hintText: 'Contoh: Sakit demam, Cuti keluarga, dll',
                            filled: true, fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _konfirmasiIzin,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                            child: const Text('Konfirmasi Aktifkan Izin'),
                          ),
                        ),
                      ],
                      if (_izinOn) ...[
                        const SizedBox(height: 10),
                        Text('Keterangan: ${_keteranganController.text}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Manager/SPV dapat melihat status ini beserta lokasi Anda saat mengaktifkan, otomatis tanpa perlu memberi tahu manual.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
              ],
            ),
    );
  }
}
