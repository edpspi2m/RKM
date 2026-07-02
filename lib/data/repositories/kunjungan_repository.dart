import 'dart:io';
import '../models/gps_location_model.dart';
import '../models/kunjungan_model.dart';
import '../services/camera_watermark_service.dart';
import '../services/kunjungan_service.dart';
import '../services/location_service.dart';

class KunjunganRepository {
  final LocationService _locationService;
  final CameraWatermarkService _watermarkService;
  final KunjunganService _kunjunganService;

  KunjunganRepository({
    LocationService? locationService,
    CameraWatermarkService? watermarkService,
    required KunjunganService kunjunganService,
  })  : _locationService = locationService ?? LocationService(),
        _watermarkService = watermarkService ?? CameraWatermarkService(),
        _kunjunganService = kunjunganService;

  Future<({File fotoFinal, GpsLocationModel lokasi})> prosesFoto(File fotoAsli) async {
    final lokasi = await _locationService.getCurrentValidatedLocation();
    final fotoFinal = await _watermarkService.applyWatermark(
      originalPhoto: fotoAsli,
      location: lokasi,
    );
    return (fotoFinal: fotoFinal, lokasi: lokasi);
  }

  Future<void> kirimKunjungan({
    required KunjunganModel kunjungan,
    required File fotoWatermark,
  }) {
    return _kunjunganService.submit(kunjungan: kunjungan, fotoWatermark: fotoWatermark);
  }
}
