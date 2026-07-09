import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../data/models/gps_location_model.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kunjungan_provider.dart';
import '../../providers/riwayat_provider.dart';

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
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (picked == null) return;
    final berhasil = await provider.prosesFoto(File(picked.path));
    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal memproses foto')),
      );
    }
  }

  Future<void> _tampilkanDialogKirimWA(String namaToko, GpsLocationModel lokasi, KunjunganProvider provider) async {
    final waService = provider.whatsappShareService;
    final nomorList = waService.daftarNomor;
    if (nomorList.isEmpty || !mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Laporan ke WhatsApp'),
        content: Text('Pilih nomor tujuan (${nomorList.length} nomor tersedia):'),
        actions: [
          ...nomorList.asMap().entries.map((entry) {
            final index = entry.key;
            final nomor = entry.value;
            return TextButton(
              onPressed: () {
                waService.kirimKeNomor(nomor, namaToko, lokasi);
              },
              child: Text('Kirim ke Nomor ${index + 1} ($nomor)'),
            );
          }),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _kirim(KunjunganProvider provider) async {
    if (_namaTokoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama toko wajib diisi')),
      );
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak valid, silakan login ulang.')),
      );
      return;
    }

    final namaToko = _namaTokoController.text.trim();
    final lokasiTerakhir = provider.lokasi;

    final berhasil = await provider.kirim(
      userId: userId,
      member: namaToko,
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(berhasil ? 'Laporan berhasil dikirim' : (provider.errorMessage ?? 'Gagal mengirim laporan')),
        backgroundColor: berhasil ? AppColors.action : AppColors.error,
      ),
    );

    if (berhasil) {
      _catatanController.clear();
      provider.reset();

      if (mounted && lokasiTerakhir != null) {
        await _tampilkanDialogKirimWA(namaToko, lokasiTerakhir, provider);
      }

      if (mounted) {
        context.read<RiwayatProvider>().load(userId);
        Navigator.of(context).pop();
      }
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
