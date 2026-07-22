import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class IzinStatusProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://api.isreport.my.id/absen';

  String? _jenisAktif; // 'sakit' | 'istirahat' | null
  String? _keterangan;
  bool _isLoading = false;

  String? get jenisAktif => _jenisAktif;
  String? get keterangan => _keterangan;
  bool get isLoading => _isLoading;

  Future<void> loadStatus(String userId) async {
    if (userId.isEmpty) return;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/izin_sakit_status.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null && (data['is_active'] == true || data['is_active'] == 1)) {
        _jenisAktif = data['jenis'] as String?;
        _keterangan = data['keterangan'] as String?;
      } else {
        _jenisAktif = null;
        _keterangan = null;
      }
      notifyListeners();
    } catch (_) {
      // Diamkan — biarkan status tetap seperti sebelumnya kalau gagal load.
    }
  }

  Future<bool> start({
    required String userId,
    required String jenis,
    required String keterangan,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      double? lat;
      double? lng;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        // Lokasi opsional untuk fitur ini — tetap lanjut kalau gagal ambil.
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/izin_sakit_toggle.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'action': 'start',
              'jenis': jenis,
              'keterangan': keterangan,
              'latitude': lat?.toString() ?? '',
              'longitude': lng?.toString() ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        _jenisAktif = jenis;
        _keterangan = keterangan;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> stop(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/izin_sakit_toggle.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'action': 'stop'}),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        _jenisAktif = null;
        _keterangan = null;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
