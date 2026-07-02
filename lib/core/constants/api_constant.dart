class ApiConstant {
  ApiConstant._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.rkm-internal.co.id/v1',
  );

  static const String login = '/auth/login';
  static const String submitKunjungan = '/kunjungan/submit';

  static const Duration timeout = Duration(seconds: 15);
}
