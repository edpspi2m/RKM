import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:url_launcher/url_launcher.dart';
import '../models/gps_location_model.dart';

class WhatsappShareService {
  /// Daftar nomor tujuan, pisahkan pakai koma (format internasional, tanpa + atau 0 di depan).
  /// Contoh 1 nomor: '6281234567890'
  /// Contoh 2 nomor: '6281234567890,6289876543210'
  static const String nomorTujuan = '6282132682086,6282132862086';

  List<String> get _daftarNomor =>
      nomorTujuan.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  String _buatPesan(String namaToko, GpsLocationModel lokasi) {
    final mapsUrl = 'https://maps.google.com/?q=${lokasi.latitude},${lokasi.longitude}';
    return 'Laporan Kunjungan RKM\n'
        'Toko: $namaToko\n'
        'Waktu: ${lokasi.capturedAt}\n'
        'Lokasi: $mapsUrl';
  }

  /// Kirim ke nomor pertama di daftar secara otomatis.
  /// Untuk nomor kedua dan seterusnya, gunakan [nomorList] + [kirimKeNomor] dari UI (lihat dialog).
  Future<void> shareKunjungan({
    required dynamic fotoFile,
    required String namaToko,
    required GpsLocationModel lokasi,
  }) async {
    final nomor = _daftarNomor;
    if (nomor.isEmpty) return;
    await kirimKeNomor(nomor.first, namaToko, lokasi);
  }

  /// Buka WhatsApp ke satu nomor spesifik dengan teks laporan siap kirim.
  Future<void> kirimKeNomor(String nomor, String namaToko, GpsLocationModel lokasi) async {
    final pesan = _buatPesan(namaToko, lokasi);
    final waUrl = Uri.parse('https://wa.me/$nomor?text=${Uri.encodeComponent(pesan)}');
    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Kegagalan share tidak boleh menggagalkan proses submit laporan utama
    }
  }

  /// Daftar nomor untuk ditampilkan sebagai pilihan di UI (dialog multi-kirim).
  List<String> get daftarNomor => _daftarNomor;

  String buatPesanUntukUi(String namaToko, GpsLocationModel lokasi) => _buatPesan(namaToko, lokasi);
}
