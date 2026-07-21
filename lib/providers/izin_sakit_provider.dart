import 'package:flutter/foundation.dart';
import '../data/models/izin_sakit_model.dart';
import '../data/services/izin_sakit_service.dart';

enum IzinSakitStatus { normal, sakit, istirahat }

class IzinSakitProvider extends ChangeNotifier {
  final IzinSakitService _service;

  IzinSakitProvider(this._service);

  IzinSakitStatus _status = IzinSakitStatus.normal;
  String? _keterangan;
  DateTime? _mulaiTime;
  DateTime? _selesaiTime;
  bool _isLoading = false;
  String? _errorMessage;
  int? _durasiIstirahatMenit;

  // Getters
  IzinSakitStatus get status => _status;
  String? get keterangan => _keterangan;
  DateTime? get mulaiTime => _mulaiTime;
  DateTime? get selesaiTime => _selesaiTime;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get durasiIstirahatMenit => _durasiIstirahatMenit;

  bool get isSakit => _status == IzinSakitStatus.sakit;
  bool get isIstirahat => _status == IzinSakitStatus.istirahat;
  bool get isNormal => _status == IzinSakitStatus.normal;

  /// Start sick leave
  Future<void> startSakit({
    required String userId,
    required double latitude,
    required double longitude,
    required String keterangan,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.start(
        userId: userId,
        jenis: 'sakit',
        lat: latitude,
        lng: longitude,
        keterangan: keterangan,
      );

      _status = IzinSakitStatus.sakit;
      _keterangan = keterangan;
      _mulaiTime = DateTime.now();
      _selesaiTime = null;
      _durasiIstirahatMenit = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memulai izin sakit: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Start rest/istirahat with duration
  Future<void> startIstirahat({
    required String userId,
    required double latitude,
    required double longitude,
    required int durasiMenit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.start(
        userId: userId,
        jenis: 'istirahat',
        lat: latitude,
        lng: longitude,
        keterangan: 'Istirahat selama $durasiMenit menit',
      );

      _status = IzinSakitStatus.istirahat;
      _keterangan = 'Istirahat selama $durasiMenit menit';
      _mulaiTime = DateTime.now();
      _durasiIstirahatMenit = durasiMenit;
      _selesaiTime = DateTime.now().add(Duration(minutes: durasiMenit));

      // Auto-stop after duration
      Future.delayed(Duration(minutes: durasiMenit), () {
        if (_status == IzinSakitStatus.istirahat) {
          stop(userId);
        }
      });

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memulai istirahat: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Stop sick leave / istirahat and return to normal status
  Future<void> stop(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.stop(userId);

      _status = IzinSakitStatus.normal;
      _keterangan = null;
      _selesaiTime = DateTime.now();
      _durasiIstirahatMenit = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal menghentikan izin: ${e.toString()}';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Reset state (call on logout or app restart)
  void reset() {
    _status = IzinSakitStatus.normal;
    _keterangan = null;
    _mulaiTime = null;
    _selesaiTime = null;
    _durasiIstirahatMenit = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
