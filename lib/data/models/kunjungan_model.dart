import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/kunjungan_model.dart';
import '../data/models/gps_location_model.dart';

// Enum state untuk mengatur tampilan loading di UI
enum SubmitState { idle, processingPhoto, uploading, success, error }

class KunjunganProvider extends ChangeNotifier {
  SubmitState _state = SubmitState.idle;
  SubmitState get state => _state;

  File? _fotoWatermark;
  File? get fotoWatermark => _fotoWatermark;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  GpsLocationModel? _lokasi; 

  // ---------------------------------------------------------
  // 1. PROSES FOTO & DAPATKAN LOKASI
  // ---------------------------------------------------------
  Future<bool> prosesFoto(File fotoBiasa) async {
    _setState(SubmitState.processingPhoto);
    _errorMessage = null;

    try {
      // TODO: Panggil fungsi untuk mendapatkan titik GPS asli di sini
      // Contoh mock data (ganti dengan logic aslinya):
      _lokasi = GpsLocationModel(
        latitude: -6.200000, 
        longitude: 106.816666, 
        capturedAt: DateTime.now(),
      );

      // TODO: Panggil fungsi Watermark kamu di sini
      // Contoh: _fotoWatermark = await WatermarkService.addWatermark(fotoBiasa, _lokasi!);
      _fotoWatermark = fotoBiasa; // <- Hapus ini jika sudah pakai logic watermark asli

      _setState(SubmitState.idle);
      return true;
    } catch (e) {
      _errorMessage = "Gagal memproses foto: ${e.toString()}";
      _setState(SubmitState.idle);
      return false;
    }
  }

  // ---------------------------------------------------------
  // 2. KIRIM DATA KE SERVER & WHATSAPP
  // ---------------------------------------------------------
  Future<bool> kirim({
    required String namaToko,
    required String catatan,
    required String username,
  }) async {
    if (_fotoWatermark == null || _lokasi == null) {
      _errorMessage = "Foto atau lokasi belum tersedia";
      return false;
    }

    _setState(SubmitState.uploading);
    _errorMessage = null;

    try {
      // 🔥 INI BAGIAN YANG SUDAH DIPERBAIKI 🔥
      // Parameter di model adalah 'member', sedangkan dari UI kita bawa variabel 'namaToko'
      final kunjungan = KunjunganModel(
        userId: username,
        member: namaToko, // <--- Ini perbaikannya (sebelumnya namaToko: namaToko)
        catatan: catatan,
        lokasi: _lokasi!,
      );

      // Contoh print field untuk memastikan data format Map-nya benar
      // print(kunjungan.toFields());

      // TODO: Panggil API kirim data (Multipart Request) di sini
      // Contoh: await ApiService.uploadLaporan(kunjungan.toFields(), _fotoWatermark!);

      // TODO: Panggil fungsi Share ke WhatsApp di sini
      // Contoh: await WhatsAppService.shareData(kunjungan);

      _setState(SubmitState.success);
      return true;
    } catch (e) {
      _errorMessage = "Gagal mengirim laporan: ${e.toString()}";
      _setState(SubmitState.error);
      return false;
    }
  }

  // ---------------------------------------------------------
  // 3. RESET FORM
  // ---------------------------------------------------------
  void reset() {
    _state = SubmitState.idle;
    _fotoWatermark = null;
    _errorMessage = null;
    _lokasi = null;
    notifyListeners();
  }

  // Helper untuk update state UI
  void _setState(SubmitState newState) {
    _state = newState;
    notifyListeners();
  }
}
