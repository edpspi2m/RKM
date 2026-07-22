import 'package:flutter/foundation.dart';
import '../data/models/member_model.dart';
import '../data/services/potensial_get_service.dart';

enum PotensialGetState { idle, loading, success, error }

class PotensialGetProvider extends ChangeNotifier {
  final PotensialGetService _service = PotensialGetService();

  PotensialGetState _state = PotensialGetState.idle;
  List<MemberModel> _members = [];
  String? _errorMessage;

  PotensialGetState get state => _state;
  List<MemberModel> get members => _members;
  String? get errorMessage => _errorMessage;

  Future<void> load(String userId) async {
    _state = PotensialGetState.loading;
    notifyListeners();
    try {
      _members = await _service.fetchPotensialGet(userId);
      _state = PotensialGetState.success;
    } catch (e) {
      _state = PotensialGetState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
