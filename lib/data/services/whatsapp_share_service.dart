import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:share_plus/share_plus.dart';
import '../models/gps_location_model.dart';

class WhatsappShareService {
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
      if (fotoFile is io.File) {
        await Share.shareXFiles(
          [XFile(fotoFile.path)],
          text: pesan,
        );
      } else {
        await Share.share(pesan);
      }
    } catch (_) {
      // Kegagalan share tidak boleh menggagalkan proses submit laporan utama
    }
  }
}
