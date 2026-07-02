import '../../core/security/device_security_service.dart';
import '../../core/security/location_security_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class SecurityViolationException implements Exception {
  final List<String> reasons;
  SecurityViolationException(this.reasons);

  @override
  String toString() => reasons.join('\n');
}

class AuthRepository {
  final AuthService _authService;
  final DeviceSecurityService _deviceSecurityService;
  final LocationSecurityService _locationSecurityService;

  AuthRepository(
    this._authService, {
    DeviceSecurityService? deviceSecurityService,
    LocationSecurityService? locationSecurityService,
  })  : _deviceSecurityService = deviceSecurityService ?? DeviceSecurityService(),
        _locationSecurityService = locationSecurityService ?? LocationSecurityService();

  Future<UserModel> login({required String email, required String password}) async {
    final deviceResult = await _deviceSecurityService.check();
    if (!deviceResult.isSafe) {
      throw SecurityViolationException(deviceResult.reasons);
    }

    final locationResult = await _locationSecurityService.validate();
    if (!locationResult.isValid) {
      throw SecurityViolationException([locationResult.message]);
    }

    return _authService.login(email: email, password: password);
  }
}
