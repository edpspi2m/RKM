import 'package:geolocator/geolocator.dart';

enum LocationSecurityStatus {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  mockLocationDetected,
}

class LocationSecurityResult {
  final LocationSecurityStatus status;
  final Position? position;
  final String message;

  const LocationSecurityResult({
    required this.status,
    required this.message,
    this.position,
  });

  bool get isValid => status == LocationSecurityStatus.granted;
}

class LocationSecurityService {
  Future<LocationSecurityResult> validate() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationSecurityResult(
        status: LocationSecurityStatus.serviceDisabled,
        message: 'GPS tidak aktif. Mohon aktifkan layanan lokasi terlebih dahulu.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationSecurityResult(
          status: LocationSecurityStatus.permissionDenied,
          message: 'Izin akses lokasi ditolak.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationSecurityResult(
        status: LocationSecurityStatus.permissionDeniedForever,
        message: 'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan aplikasi.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // position.isMocked hanya reliable di Android, default false di iOS.
    if (position.isMocked) {
      return LocationSecurityResult(
        status: LocationSecurityStatus.mockLocationDetected,
        message: 'Fake GPS / Mock Location terdeteksi. Akses ditolak demi validitas data lapangan.',
        position: position,
      );
    }

    return LocationSecurityResult(
      status: LocationSecurityStatus.granted,
      message: 'Lokasi valid.',
      position: position,
    );
  }
}
