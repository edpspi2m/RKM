import 'dart:js' as js;

/// Versi web — jembatan ke Geolocation API browser lewat JavaScript.
/// File ini HANYA dikompilasi kalau build target-nya web (dart.library.html
/// tersedia). Android/iOS otomatis pakai browser_geolocation_stub.dart.
class BrowserGeolocationService {
  int? _watchId;

  bool get isSupported {
    _ensureBridgeScript();
    return js.context['rkmGeolocation'] != null;
  }

  Future<Map<String, dynamic>?> getCurrentPosition() async {
    _ensureBridgeScript();
    try {
      final rkmGeolocation = js.context['rkmGeolocation'];
      if (rkmGeolocation == null) return null;

      final result = await js.JsObject.fromBrowserObject(rkmGeolocation)
          .callMethod('getCurrentPosition', []);
      if (result == null) return null;

      return {
        'latitude': result['latitude'],
        'longitude': result['longitude'],
        'accuracy': result['accuracy'],
      };
    } catch (_) {
      return null;
    }
  }

  void startWatching(
    void Function(Map<String, dynamic> position) onUpdate, {
    void Function(String error)? onError,
  }) {
    _ensureBridgeScript();
    try {
      final rkmGeolocation = js.context['rkmGeolocation'];
      if (rkmGeolocation == null) return;

      _watchId = js.JsObject.fromBrowserObject(rkmGeolocation).callMethod(
        'startWatching',
        [
          js.allowInterop((lat, lng, acc) {
            onUpdate({'latitude': lat, 'longitude': lng, 'accuracy': acc});
          }),
          js.allowInterop((err) {
            onError?.call(err.toString());
          }),
        ],
      );
    } catch (_) {
      // Diamkan — kegagalan bridge JS tidak boleh crash app.
    }
  }

  void stopWatching() {
    try {
      final rkmGeolocation = js.context['rkmGeolocation'];
      if (rkmGeolocation != null && _watchId != null) {
        js.JsObject.fromBrowserObject(rkmGeolocation)
            .callMethod('stopWatching', [_watchId]);
      }
    } catch (_) {}
    _watchId = null;
  }

  void _ensureBridgeScript() {
    if (js.context['rkmGeolocation'] != null) return;

    const script = '''
      window.rkmGeolocation = {
        getCurrentPosition: function() {
          return new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(
              (pos) => resolve({
                latitude: pos.coords.latitude,
                longitude: pos.coords.longitude,
                accuracy: pos.coords.accuracy
              }),
              (err) => reject(err),
              { enableHighAccuracy: true, timeout: 10000 }
            );
          });
        },
        startWatching: function(onUpdate, onError) {
          return navigator.geolocation.watchPosition(
            (pos) => onUpdate(pos.coords.latitude, pos.coords.longitude, pos.coords.accuracy),
            (err) => onError(err.message),
            { enableHighAccuracy: true }
          );
        },
        stopWatching: function(watchId) {
          navigator.geolocation.clearWatch(watchId);
        }
      };
    ''';
    js.context.callMethod('eval', [script]);
  }
}
