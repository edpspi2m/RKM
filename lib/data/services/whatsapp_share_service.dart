import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../models/gps_location_model.dart';
import '../../core/utils/date_formatter.dart';

class WhatsappShareService {
  Future<void> shareKunjungan({
    required File fotoFile,
    required String namaToko,
    required GpsLocationModel lokasi,
  }) async {
    final message = _buildMessage(namaToko, lokasi);

    await Share.shareXFiles(
      [XFile(fotoFile.path)],
      text: message,
    );
  }

  String _buildMessage(String namaToko, GpsLocationModel lokasi) {
    return '''
*Laporan Kunjungan RKM*
Toko: $namaToko
Tanggal: ${DateFormatter.fullDateTime(lokasi.capturedAt)}
Alamat: ${lokasi.address}
Koordinat: ${lokasi.coordinateText}
'''
        .trim();
  }
}
