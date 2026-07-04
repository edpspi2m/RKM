import 'package:flutter/foundation.dart';
import '../data/services/riwayat_service.dart';

enum RiwayatState { idle, loading, success, error }

class RiwayatProvider extends ChangeNotifier {
  final RiwayatService _service;
  RiwayatProvider(this._service);

  RiwayatState _state = RiwayatState.idle;
  String? _errorMessage;
  List<Map<String, dynamic>> _grouped = [];

  RiwayatState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get grouped => _grouped;

  Future<void> load(String username) async {
    _state = RiwayatState.loading;
    notifyListeners();
    try {
      _grouped = await _service.fetchRiwayat(username);
      _state = RiwayatState.success;
    } catch (e) {
      _state = RiwayatState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
