class ApiConstant {
  ApiConstant._();

  // ============ BASE URL ============
  static const String baseUrl = 'https://api.isreport.my.id/absen';

  // ============ TIMEOUT ============
  static const Duration timeout = Duration(seconds: 15);

  // ============ AUTH ============
  static const String login = '/login.php';

  // ============ KUNJUNGAN ============
  static const String submitKunjungan = '/submit_kunjungan.php';

  // ============ PROMO ============
  static const String promo = '/promo.php';

  // ============ OTP ============
  static const String otpRequest = '/otp_request.php';
  static const String otpVerify  = '/otp_verify.php';

  // ============ TRACKING ============
  static const String routeTrack      = '/route_tracking.php';
  static const String updateLocation  = '/update_location.php';
  static const String liveLocations   = '/get_live_locations.php';
  static const String reportFakeGps   = '/report_fake_gps.php';
  static const String autoLockFakeGps = '/auto_lock_fake_gps.php';

  // ============ TIMEOUT LAIN (kalau dipakai) ============
  static const Duration timeoutShort  = Duration(seconds: 8);
  static const Duration timeoutMedium = Duration(seconds: 12);
  static const Duration timeoutLong   = Duration(seconds: 20);
}
