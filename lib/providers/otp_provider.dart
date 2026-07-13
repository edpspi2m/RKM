import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/services/otp_service.dart';

enum OtpState { idle, requestingOtp, otpSent, verifying, success, error }

class OtpProvider extends ChangeNotifier {
  final OtpService _service;
  OtpProvider(this._service);

  OtpState _state = OtpState.idle;
  String? _errorMessage;
  String? _pendingUsername;
  String? _pendingPassword;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  OtpState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get pendingUsername => _pendingUsername;
  int get secondsRemaining => _secondsRemaining;

  String get formattedCountdown {
    final m = (_secondsRemaining ~/ 60).toString();
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = 300; // 5 menit
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        _secondsRemaining--;
      }
      notifyListeners();
    });
  }

  Future<bool> requestOtp(String username, String password) async {
    _state = OtpState.requestingOtp;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.requestOtp(username: username, password: password);
      _pendingUsername = username;
      _pendingPassword = password; // disimpan sementara di memori, tidak ditulis ke disk, hanya untuk resend
      _state = OtpState.otpSent;
      _startCountdown();
      return true;
    } catch (e) {
      _state = OtpState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> resendOtp() async {
    if (_pendingUsername == null || _pendingPassword == null) return false;
    return requestOtp(_pendingUsername!, _pendingPassword!);
  }

  Future<UserModel?> verifyOtp(String otp) async {
    if (_pendingUsername == null) return null;

    _state = OtpState.verifying;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _service.verifyOtp(username: _pendingUsername!, otp: otp);
      _state = OtpState.success;
      _countdownTimer?.cancel();
      return user;
    } catch (e) {
      _state = OtpState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _countdownTimer?.cancel();
    _state = OtpState.idle;
    _errorMessage = null;
    _pendingUsername = null;
    _pendingPassword = null;
    _secondsRemaining = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
