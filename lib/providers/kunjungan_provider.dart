import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:flutter/foundation.dart';
import '../data/models/gps_location_model.dart';
import '../data/models/kunjungan_model.dart';
import '../data/repositories/kunjungan_repository.dart';
import '../data/services/whatsapp_share_service.dart';

typedef AppFile = dynamic;

enum SubmitState { idle, processingPhoto, uploading, success, error }

class KunjunganProvider extends ChangeNotifier {
  final KunjunganRepository _repository;
  final WhatsappShareService _whatsappShareService;

  KunjunganProvider({required KunjunganRepository repository, WhatsappShareService? whatsappShareService})
      : _repository = repository,
        _whatsappShareService = whatsappShareService ?? WhatsappShareService();

  SubmitState _state = SubmitState.idle;
  String? _errorMessage;
  AppFile? _fotoWatermark;
  GpsLocationModel? _lokasi;

  SubmitState get state => _state;
  String? get errorMessage => _errorMessage;
  AppFile? get fotoWatermark => _fotoWatermark;
  GpsLocationModel? get lokasi => _lokasi;

  Future<bool> prosesFoto(AppFile fotoAsli) async {
    _state = SubmitState.processingPhoto;
    _errorMessage = null;
    notifyListeners();
    try {
      final hasil = await _repository.prosesFoto(fotoAsli);
      _fotoWatermark = hasil.fotoFinal;
      _lokasi = hasil.lokasi;
      _state = SubmitState.idle;
      return true;
    } catch (e) {
      _state = SubmitState.error;
      _errorMessage = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> kirim({required String namaToko, required String catatan, required String username}) async {
    if (_fotoWatermark == null || _lokasi == null) {
      _errorMessage = 'Foto dan lokasi belum diproses.';
      notifyListeners();
      return false;
    }
    _state = SubmitState.uploading;
    notifyListeners();
    try {
      final String path = _fotoWatermark is io.File ? _fotoWatermark.path : 'web_image_path';
      final kunjungan = KunjunganModel(
        namaToko: namaToko,
        catatan: catatan,
        lokasi: _lokasi!,
        fotoPath: path,
        username: username,
      );
      await _repository.kirimKunjungan(kunjungan: kunjungan, fotoWatermark: _fotoWatermark!);
      _state = SubmitState.success;
      notifyListeners();
      await bagikanKeWhatsapp(namaToko);
      return true;
    } catch (e) {
      _state = SubmitState.error;
      _errorMessage = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> bagikanKeWhatsapp(String namaToko) async {
    if (_fotoWatermark == null || _lokasi == null) return;
    await _whatsappShareService.shareKunjungan(fotoFile: _fotoWatermark!, namaToko: namaToko, lokasi: _lokasi!);
  }

  void reset() {
    _state = SubmitState.idle;
    _errorMessage = null;
    _fotoWatermark = null;
    _lokasi = null;
    notifyListeners();
  }
}
