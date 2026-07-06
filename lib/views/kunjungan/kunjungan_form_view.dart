import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kunjungan_provider.dart';

class KunjunganFormView extends StatefulWidget {
  final MemberModel? selectedMember;
  const KunjunganFormView({super.key, this.selectedMember});

  @override
  State<KunjunganFormView> createState() => _KunjunganFormViewState();
}

class _KunjunganFormViewState extends State<KunjunganFormView> {
  final _namaTokoController = TextEditingController();
  final _catatanController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.selectedMember != null) {
      _namaTokoController.text = widget.selectedMember!.nama;
    }
  }

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

    final username = context.read<AuthProvider>().user?.username ?? '';
    final berhasil = await provider.kirim(
      namaToko: _namaTokoController.text.trim(),
      catatan: _catatanController.text.trim(),
      username: username,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(berhasil ? 'Laporan berhasil dikirim & dibagikan ke WhatsApp' : (provider.errorMessage ?? 'Gagal mengirim laporan')),
        backgroundColor: berhasil ? AppColors.action : AppColors.error,
      ),
    );

    if (berhasil) {
      _catatanController.clear();
      provider.reset();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KunjunganProvider>();
    final isBusy = provider.state == SubmitState.processingPhoto || provider.state == SubmitState.uploading;

    return Scaffold(
      backgroundColor: AppColors.background,
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
              // Foto
              GestureDetector(
                onTap: () => _ambilFoto(provider),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: provider.fotoWatermark != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(provider.fotoWatermark!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.primary),
                              ),
                              const SizedBox(height: 10),
                              const Text('Ketuk untuk ambil foto',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Section: Info Toko
              const Text('Informasi Toko',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _namaTokoController,
                readOnly: widget.selectedMember != null,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nama Toko / Outlet',
                  prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: widget.selectedMember != null ? AppColors.divider.withOpacity(0.3) : AppColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Section: Keterangan
              const Text('Keterangan Kunjungan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _catatanController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tulis catatan kunjungan di sini...',
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: AppButton(
                  label: 'Kirim Laporan',
                  icon: Icons.send_outlined,
                  onPressed: provider.fotoWatermark == null ? null : () => _kirim(provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
