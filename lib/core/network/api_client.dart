import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConstant.baseUrl}$path'),
            headers: _jsonHeaders,
            body: jsonEncode(body ?? {}),
          )
          .timeout(ApiConstant.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw ApiException('Gagal terhubung ke server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required File file,
    String fileFieldName = 'foto',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConstant.baseUrl}$path'));
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(fileFieldName, file.path));

      final streamed = await request.send().timeout(ApiConstant.timeout);
      final response = await http.Response.fromStream(streamed);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengirim data: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final contentType = response.headers['content-type'] ?? '';
    final trimmedBody = response.body.trim();

    // Deteksi respons yang BUKAN JSON (halaman 404 server, error PHP fatal,
    // maintenance page, dsb). Sebelum ada pengecekan ini, isi mentah halaman
    // seperti itu bisa lolos ke UI dan tampil sebagai teks error ke user.
    final looksLikeJson = contentType.contains('application/json') ||
        trimmedBody.startsWith('{') ||
        trimmedBody.startsWith('[');

    if (!looksLikeJson) {
      if (statusCode == 404) {
        throw ApiException(
          'Layanan tidak ditemukan di server (404). Endpoint mungkin belum tersedia atau salah alamat.',
          statusCode: statusCode,
        );
      }
      if (statusCode >= 500) {
        throw ApiException(
          'Server sedang bermasalah (kode $statusCode). Coba lagi beberapa saat lagi.',
          statusCode: statusCode,
        );
      }
      throw ApiException(
        'Server mengirim respons yang tidak dikenali (kode $statusCode).',
        statusCode: statusCode,
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = trimmedBody.isEmpty ? {} : jsonDecode(trimmedBody) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Gagal membaca respons server (format JSON tidak valid).', statusCode: statusCode);
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    if (statusCode == 401) {
      throw ApiException('Sesi Anda telah berakhir, silakan login kembali.', statusCode: statusCode);
    }

    final message = decoded['message']?.toString() ?? 'Permintaan gagal diproses (kode $statusCode).';
    throw ApiException(message, statusCode: statusCode);
  }
}
