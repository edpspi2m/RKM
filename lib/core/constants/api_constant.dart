class ApiConstant {
  // Base URL API Production
  static const String baseUrl = "https://api.isreport.my.id/absen";

  // Endpoints
  static const String login = "/login.php";
  static const String timestamp = "/timestamp.php";
  static const String submitKunjungan = "/rkm.php";

  // Timeout
  static const Duration timeout = Duration(seconds: 15);
}
