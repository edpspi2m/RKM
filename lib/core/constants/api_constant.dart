class ApiConstant {
  static const String baseUrl = "https://api.isreport.my.id/absen";

  static const String login = "/login.php";
  static const String timestamp = "/timestamp.php";
  static const String submitKunjungan = "/rkm.php";
  static const String promo = "/promo.php";

  static const String otpRequest = "/otp_request.php";
  static const String otpVerify = "/otp_verify.php";

  static const String routeTrack = "/route_tracking.php";
  static const String liveLocations = "/get_live_locations_app.php";

  static const Duration timeout = Duration(seconds: 15);
}
