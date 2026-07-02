import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

enum AuthState { idle, loading, success, error, securityBlocked }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ApiClient _apiClient;

  AuthProvider({
    required AuthRepository authRepository,
    required ApiClient apiClient,
  })  : _authRepository = authRepository,
        _apiClient = apiClient;

  AuthState _state = AuthState.idle;
  String? _errorMessage;
  UserModel? _user;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(email: email, password: password);
      _user = user;
      _apiClient.setToken(user.token);
      await _persistSession(user);
      _state = AuthState.success;
    } on SecurityViolationException catch (e) {
      _state = AuthState.securityBlocked;
      _errorMessage = e.reasons.join('\n');
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', user.token);
    await prefs.setString('user_id', user.id);
  }

  Future<void> logout() async {
    _user = null;
    _apiClient.clearToken();
    _state = AuthState.idle;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
