import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gps_location_model.dart';

class WhatsappShareService {
  /// Ganti nomor ini dengan nomor tujuan tetap (format internasional, tanpa + atau 0 di depan)
  static const String nomorTujuan = '6282132862086';

  Future<void> shareKunjungan({
    required dynamic fotoFile,
    required String namaToko,
    required GpsLocationModel lokasi,
  }) async {
    final mapsUrl = 'https://maps.google.com/?q=${lokasi.latitude},${lokasi.longitude}';
    final pesan = 'Laporan Kunjungan RKM\n'
        'Toko: $namaToko\n'
        'Waktu: ${lokasi.capturedAt}\n'
        'Lokasi: $mapsUrl';

    try {
      // Buka langsung ke nomor tujuan dengan teks siap kirim.
      // Sales tinggal lampirkan foto (jika perlu) dan tap kirim sekali.
      final waUrl = Uri.parse('https://wa.me/$nomorTujuan?text=${Uri.encodeComponent(pesan)}');

      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else if (fotoFile is io.File) {
        // Fallback: kalau wa.me gagal dibuka, pakai share sheet biasa
        await Share.shareXFiles([XFile(fotoFile.path)], text: pesan);
      }
    } catch (_) {
      // Kegagalan share tidak boleh menggagalkan proses submit laporan utama
    }
  }
}
