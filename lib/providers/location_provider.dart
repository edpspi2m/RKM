import 'package:flutter/foundation.dart';
import '../data/models/gps_location_model.dart';
import '../data/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;

  LocationProvider({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  bool _isLoading = false;
  String? _errorMessage;
  GpsLocationModel? _currentLocation;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GpsLocationModel? get currentLocation => _currentLocation;

  Future<bool> fetchCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentLocation = await _locationService.getCurrentValidatedLocation();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
