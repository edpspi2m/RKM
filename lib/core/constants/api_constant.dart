class ApiConstant {
  // Base URL API Production
  static const String baseUrl = "https://api.isreport.my.id/absen";

  // Endpoints
  static const String login = "$baseUrl/login.php";
  static const String timestamp = "$baseUrl/timestamp.php";
  static const String rkm = "$baseUrl/rkm.php";

  // Timeout settings
  static const int connectTimeout = 15000; // 15 detik
  static const int receiveTimeout = 15000;
}
