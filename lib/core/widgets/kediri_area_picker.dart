import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../constants/kediri_area_data.dart';

/// Widget input wilayah untuk form "Not Get":
/// - Desa/Kelurahan: ketik bebas (sales tinggal ketik nama depannya)
/// - Kecamatan: dropdown (26 Kabupaten Kediri + 3 Kota Kediri, akurat)
/// - Kota/Kabupaten: terisi OTOMATIS begitu kecamatan dipilih (readonly)
class KediriAreaPicker extends StatelessWidget {
  final TextEditingController kelurahanController;
  final TextEditingController kecamatanController;
  final TextEditingController kotaController;

  const KediriAreaPicker({
    super.key,
    required this.kelurahanController,
    required this.kecamatanController,
    required this.kotaController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: kelurahanController,
          decoration: InputDecoration(
            labelText: 'Desa / Kelurahan',
            hintText: 'Ketik nama desa...',
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: kecamatanController.text.isNotEmpty && KediriAreaData.semuaKecamatan.contains(kecamatanController.text)
              ? kecamatanController.text
              : null,
          decoration: InputDecoration(
            labelText: 'Kecamatan',
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          items: KediriAreaData.semuaKecamatan
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) {
            kecamatanController.text = v ?? '';
            kotaController.text = v != null ? KediriAreaData.kabupatenKotaUntuk(v) : '';
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: kotaController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Kota / Kabupaten',
            filled: true,
            fillColor: AppColors.divider.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
