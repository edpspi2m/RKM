import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/fake_gps_dialog.dart';
import '../../core/network/api_client.dart';
import '../../data/services/potensi_kunjungan_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kunjungan_provider.dart';

class PotensiKunjunganFormView extends StatefulWidget {
  final int potensiId;
  final String namaLokasi;
  const PotensiKunjunganFormView({super.key, required this.potensiId, required this.namaLokasi});

  @override
  State<PotensiKunjunganFormView> createState() => _PotensiKunjunganFormViewState();
}

class _PotensiKunjunganFormViewState extends State<PotensiKunjunganFormView> {
  final _catatanController = TextEditingController();
  final _picker = ImagePicker();
  bool _submitting = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  bool _isFakeGpsError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('gps') || lower.contains('mock') || lower.contains('palsu') || lower.contains('fake') || lower.contains('tidak valid');
  }

  Future<void> _ambilFoto(KunjunganProvider provider) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1280, maxHeight: 1280);
    if (picked == null) return;
    final berhasil = await provider.prosesFoto(File(picked.path));
    if (!berhasil && mounted) {
      final msg = provider.errorMessage ?? 'Gagal memproses foto';
      if (_isFakeGpsError(msg)) {
        await FakeGpsDialog.show(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _kirim(KunjunganProvider provider) async {
    if (provider.fotoWatermark == null || provider.lokasi == null) return;

    setState(() => _submitting = true);
    try {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      final service = PotensiKunjunganService(context.read<ApiClient>());
      
      await service.kirim(
        potensiId: widget.potensiId,
        userId: userId,
        catatan: _catatanController.text.trim(),
        latitude: provider.lokasi!.latitude,   // Diambil langsung nilai double-nya
        longitude: provider.lokasi!.longitude, // Diambil langsung nilai double-nya
        foto: provider.fotoWatermark!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan kunjungan berhasil dikirim'), backgroundColor: AppColors.action));
        provider.reset();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KunjunganProvider>();
    final isBusy = provider.state == SubmitState.processingPhoto || _submitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kunjungi Lokasi Potensial')),
      body: LoadingOverlay(
        isLoading: isBusy,
        message: provider.state == SubmitState.processingPhoto ? 'Memproses foto & lokasi...' : 'Mengirim laporan...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.stars_outlined, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.namaLokasi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _ambilFoto(provider),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                  child: provider.fotoWatermark != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(provider.fotoWatermark!, fit: BoxFit.cover))
                      : Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.primary)),
                            const SizedBox(height: 10),
                            const Text('Ketuk untuk ambil foto', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ]),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Keterangan Kunjungan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _catatanController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(hintText: 'Tulis catatan kunjungan di sini...', filled: true, fillColor: AppColors.inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 28),
              SizedBox(height: 52, child: AppButton(label: 'Kirim Laporan', icon: Icons.send_outlined, onPressed: provider.fotoWatermark == null ? null : () => _kirim(provider))),
            ],
          ),
        ),
      ),
    );
  }
}
