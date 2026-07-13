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
import '../../providers/member_provider.dart';
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

    final berhasil = await provider.kirim(
      userId: userId,
      member: _namaTokoController.text.trim(),
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
      if (mounted) {
        // Refresh riwayat & daftar member (biar yang baru dikunjungi hilang dari "belum dikunjungi")
        context.read<RiwayatProvider>().load(userId);
        context.read<MemberProvider>().load(userId);
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildNamaTokoField() {
    // Kalau member sudah dipilih dari tab Member, field jadi read-only.
    if (widget.selectedMember != null) {
      return TextField(
        controller: _namaTokoController,
        readOnly: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Nama Toko / Outlet',
          prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.divider.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );
    }

    // Kalau input manual, tampilkan search dari daftar member milik sales yang login.
    final members = context.watch<MemberProvider>().members;

    return Autocomplete<MemberModel>(
      textEditingController: _namaTokoController,
      displayStringForOption: (m) => m.nama,
      optionsBuilder: (TextEditingValue value) {
        if (value.text.trim().isEmpty) return const Iterable<MemberModel>.empty();
        final query = value.text.toLowerCase();
        return members.where((m) => m.nama.toLowerCase().contains(query));
      },
      onSelected: (m) => setState(() => _namaTokoController.text = m.nama),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Nama Toko / Outlet',
            hintText: 'Ketik untuk cari member...',
            prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.primary),
                    title: Text(option.nama, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(option.kota ?? '-', style: const TextStyle(fontSize: 11)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
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
              _buildNamaTokoField(),
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
