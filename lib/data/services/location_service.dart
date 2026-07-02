import 'package:geocoding/geocoding.dart';
import '../../core/security/location_security_service.dart';
import '../models/gps_location_model.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  final LocationSecurityService _securityService;

  LocationService({LocationSecurityService? securityService})
      : _securityService = securityService ?? LocationSecurityService();

  Future<GpsLocationModel> getCurrentValidatedLocation() async {
    final result = await _securityService.validate();

    if (!result.isValid || result.position == null) {
      throw LocationException(result.message);
    }

    final position = result.position!;
    var address = 'Alamat tidak ditemukan';

    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality, p.administrativeArea]
            .where((e) => e != null && e.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) address = parts.join(', ');
      }
    } catch (_) {
      // Reverse geocoding gagal tidak menggagalkan proses utama, alamat tetap fallback.
    }

    return GpsLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      capturedAt: DateTime.now(),
    );
  }
}
