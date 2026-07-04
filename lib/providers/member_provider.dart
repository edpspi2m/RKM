import 'package:flutter/foundation.dart';
import '../data/models/member_model.dart';
import '../data/services/member_service.dart';

enum MemberState { idle, loading, success, error }

class MemberProvider extends ChangeNotifier {
  final MemberService _service;
  MemberProvider(this._service);

  MemberState _state = MemberState.idle;
  String? _errorMessage;
  List<MemberModel> _members = [];
  String _searchQuery = '';

  MemberState get state => _state;
  String? get errorMessage => _errorMessage;
  List<MemberModel> get members {
    if (_searchQuery.isEmpty) return _members;
    return _members
        .where((m) => m.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.kodeMember.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> load(String username) async {
    _state = MemberState.loading;
    notifyListeners();
    try {
      _members = await _service.fetchMembers(username);
      _state = MemberState.success;
    } catch (e) {
      _state = MemberState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
