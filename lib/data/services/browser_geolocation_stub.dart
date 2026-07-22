/// Versi mobile (Android/iOS) — tidak melakukan apa-apa.
/// Geolocation di mobile sudah ditangani package `geolocator` secara native,
/// jadi bridge ke browser JavaScript ini memang tidak dipakai di mobile.
class BrowserGeolocationService {
  bool get isSupported => false;

  Future<Map<String, dynamic>?> getCurrentPosition() async => null;

  void startWatching(
    void Function(Map<String, dynamic> position) onUpdate, {
    void Function(String error)? onError,
  }) {
    // No-op di mobile.
  }

  void stopWatching() {
    // No-op di mobile.
  }
}
