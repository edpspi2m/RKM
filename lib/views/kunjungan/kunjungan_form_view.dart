import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../providers/kunjungan_provider.dart';

class KunjunganFormView extends StatefulWidget {
  const KunjunganFormView({super.key});

  @override
  State<KunjunganFormView> createState() => _KunjunganFormViewState();
}

class _KunjunganFormViewState extends State<KunjunganFormView> {
  final _namaTokoController = TextEditingController();
  final _catatanController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _namaTokoController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _ambilFoto(KunjunganProvider provider) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;

    final berhasil = await provider.prosesFoto(File(picked.path));

    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal memproses foto')),
      );
    }
  }

  Future<void> _kirim(KunjunganProvider provider) async {
    if (_namaTokoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama toko wajib diisi')),
      );
      return;
    }

    final berhasil = await provider.kirim(
      namaToko: _namaTokoController.text.trim(),
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(berhasil ? 'Laporan berhasil dikirim' : (provider.errorMessage ?? 'Gagal mengirim laporan')),
        backgroundColor: berhasil ? AppColors.action : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KunjunganProvider>();
    final isBusy = provider.state == SubmitState.processingPhoto || provider.state == SubmitState.uploading;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Kunjungan')),
      body: LoadingOverlay(
        isLoading: isBusy,
        message: provider.state == SubmitState.processingPhoto
            ? 'Memproses foto & lokasi...'
            : 'Mengirim laporan...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => _ambilFoto(provider),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: provider.fotoWatermark != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(provider.fotoWatermark!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('Ketuk untuk ambil foto', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _namaTokoController,
                decoration: const InputDecoration(labelText: 'Nama Toko / Outlet'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan Kunjungan'),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Kirim Laporan',
                icon: Icons.send_outlined,
                onPressed: provider.fotoWatermark == null ? null : () => _kirim(provider),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Bagikan ke WhatsApp',
                icon: Icons.share_outlined,
                color: AppColors.primary,
                onPressed: provider.fotoWatermark == null
                    ? null
                    : () => provider.bagikanKeWhatsapp(_namaTokoController.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
