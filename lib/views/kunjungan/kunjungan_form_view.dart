import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/fake_gps_dialog.dart';
import '../../core/widgets/kediri_region_picker.dart';
import '../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kunjungan_provider.dart';
import '../../providers/riwayat_provider.dart';
import '../../providers/member_provider.dart';

class KunjunganFormView extends StatefulWidget {
  final MemberModel? selectedMember;
  const KunjunganFormView({super.key, this.selectedMember});

  @override
  State<KunjunganFormView> createState() => _KunjunganFormViewState();
}

class _KunjunganFormViewState extends State<KunjunganFormView> {
  final _namaTokoController = TextEditingController();
  final _catatanController = TextEditingController();
  final _kelurahanController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _kotaController = TextEditingController();
  final _picker = ImagePicker();
  bool _isNotGet = false;
  String _manualMemberName = '';

  @override
  void initState() {
    super.initState();
    if (widget.selectedMember != null) {
      _namaTokoController.text = widget.selectedMember!.nama;
    } else {
      // PENTING: pastikan daftar member sudah dimuat walau masuk dari tombol Home,
      // bukan dari tab Member — ini root cause dropdown autocomplete tidak muncul.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userId = context.read<AuthProvider>().user?.id ?? '';
        context.read<MemberProvider>().load(userId);
      });
    }
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _catatanController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kotaController.dispose();
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

  String get _namaToko => widget.selectedMember != null ? _namaTokoController.text.trim() : _manualMemberName.trim();

  Future<void> _kirim(KunjunganProvider provider) async {
    if (_namaToko.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama toko wajib diisi')));
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi login tidak valid, silakan login ulang.')));
      return;
    }

    final berhasil = await provider.kirim(
      userId: userId,
      member: _namaToko,
      catatan: _catatanController.text.trim(),
      statusKunjungan: _isNotGet ? 'not_get' : 'berhasil',
      kelurahan: _isNotGet ? _kelurahanController.text.trim() : '',
      kecamatan: _isNotGet ? _kecamatanController.text.trim() : '',
      kota: _isNotGet ? _kotaController.text.trim() : '',
      fromMemberList: widget.selectedMember != null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(berhasil ? 'Laporan berhasil dikirim' : (provider.errorMessage ?? 'Gagal mengirim laporan')),
      backgroundColor: berhasil ? AppColors.action : AppColors.error,
    ));

    if (berhasil) {
      _catatanController.clear();
      provider.reset();
      if (mounted) {
        context.read<RiwayatProvider>().load(userId);
        context.read<MemberProvider>().load(userId);
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildNamaTokoField() {
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

    final members = context.watch<MemberProvider>().members;

    return Autocomplete<MemberModel>(
      displayStringForOption: (m) => m.nama,
      optionsBuilder: (TextEditingValue value) {
        _manualMemberName = value.text;
        if (value.text.trim().isEmpty) return const Iterable<MemberModel>.empty();
        final query = value.text.toLowerCase();
        return members.where((m) => m.nama.toLowerCase().contains(query));
      },
      onSelected: (m) => setState(() => _manualMemberName = m.nama),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (v) => _manualMemberName = v,
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
              constraints: const BoxConstraints(maxHeight: 220, minWidth: 280),
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
        message: provider.state == SubmitState.processingPhoto ? 'Memproses foto & lokasi...' : 'Mengirim laporan...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Text('Informasi Toko', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              _buildNamaTokoField(),
              const SizedBox(height: 20),
              const Text('Keterangan Kunjungan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _catatanController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(hintText: 'Tulis catatan kunjungan di sini...', filled: true, fillColor: AppColors.inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),

              // Checkbox "Not Get" HANYA muncul kalau input manual (bukan dari list Member),
              // sesuai permintaan: kalau klik dari Member, tidak perlu opsi ini.
              if (widget.selectedMember == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                  child: CheckboxListTile(
                    value: _isNotGet,
                    onChanged: (v) => setState(() => _isNotGet = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tandai sebagai Not Get', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Member menolak / tidak mau menjadi member', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    activeColor: AppColors.error,
                  ),
                ),
                if (_isNotGet) ...[
                  const SizedBox(height: 12),
                  const Text('Detail Lokasi Member Not Get', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                  const SizedBox(height: 8),
                  KediriRegionPicker(
                    kotaController: _kotaController,
                    kecamatanController: _kecamatanController,
                    desaController: _kelurahanController,
                  ),
                ],
              ],

              const SizedBox(height: 28),
              SizedBox(height: 52, child: AppButton(label: 'Kirim Laporan', icon: Icons.send_outlined, onPressed: provider.fotoWatermark == null ? null : () => _kirim(provider))),
            ],
          ),
        ),
      ),
    );
  }
}
