import 'package:flutter/foundation.dart';
import '../data/models/promo_model.dart';
import '../data/services/promo_service.dart';

enum PromoState { idle, loading, success, error }

class PromoProvider extends ChangeNotifier {
  final PromoService _service;
  PromoProvider(this._service);

  PromoState _state = PromoState.idle;
  String? _errorMessage;
  List<PromoModel> _promoList = [];

  PromoState get state => _state;
  String? get errorMessage => _errorMessage;
  List<PromoModel> get promoList => _promoList;

  Future<void> load() async {
    _state = PromoState.loading;
    notifyListeners();
    try {
      _promoList = await _service.fetchPromo();
      _state = PromoState.success;
    } catch (e) {
      _state = PromoState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
