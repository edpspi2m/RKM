class ApiConstant {
  ApiConstant._();

  // ============ BASE URL ============
  static const String baseUrl = 'https://api.isreport.my.id/absen';

  // ============ ENDPOINTS ============
  // Route / Trail tracking
  static const String routeTrack = '/route_tracking.php';

  // Live location (untuk marker di web /tracking.php)
  static const String updateLocation = '/update_location.php';

  // Fake GPS report
  static const String reportFakeGps = '/report_fake_gps.php';

  // Auto lock akun fake GPS
  static const String autoLockFakeGps = '/auto_lock_fake_gps.php';

  // ============ TIMEOUT ============
  static const Duration timeoutShort  = Duration(seconds: 8);
  static const Duration timeoutMedium = Duration(seconds: 12);
  static const Duration timeoutLong   = Duration(seconds: 20);
}
