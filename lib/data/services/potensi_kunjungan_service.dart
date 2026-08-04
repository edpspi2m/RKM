import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/gps_location_model.dart';

class PotensiKunjunganService {
  static const String _baseUrl = 'https://api.isreport.my.id/absen';

  Future<void> kirim({
    required int potensiId,
    required String userId,
    required String catatan,
    required GpsLocationModel lokasi,
    required File foto,
  }) async {
    final uri = Uri.parse('$_baseUrl/potensi_kunjungan.php');
    final request = http.MultipartRequest('POST', uri);

    request.fields['potensi_id'] = potensiId.toString();
    request.fields['user_id'] = userId;
    request.fields['catatan'] = catatan;
    request.fields['latitude'] = lokasi.latitude.toString();
    request.fields['longitude'] = lokasi.longitude.toString();
    request.fields['timestamp'] = lokasi.capturedAt.toIso8601String();

    request.files.add(await http.MultipartFile.fromPath('foto', foto.path));

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Gagal konek ke $uri\nDetail: $e');
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 404) {
      throw Exception('URL tidak ditemukan (404): $uri\n\nCek di browser HP kamu, kalau muncul halaman error 404 (bukan JSON), berarti file "potensi_kunjungan.php" belum ada / salah nama di server (huruf besar-kecil harus persis sama).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Server merespon status ${response.statusCode} dari $uri\nIsi respons: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
    }
  }
}
