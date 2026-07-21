import 'dart:js' as js;
import 'dart:async';

/// Service untuk akses Geolocation API Browser (hanya untuk web)
class BrowserGeolocationService {
  static const String _scriptId = 'rkm_geolocation_js';

  /// Initialize JavaScript untuk geolocation
  static void initializeJavaScript() {
    if (js.context['rkmGeolocation'] != null) return;

    final script = '''
      window.rkmGeolocation = {
        getCurrentPosition: function() {
          return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
              reject(new Error('Geolocation tidak tersedia di browser ini'));
              return;
            }

            navigator.geolocation.getCurrentPosition(
              function(position) {
                resolve({
                  latitude: position.coords.latitude,
                  longitude: position.coords.longitude,
                  accuracy: position.coords.accuracy,
                  altitude: position.coords.altitude,
                  altitudeAccuracy: position.coords.altitudeAccuracy,
                  heading: position.coords.heading,
                  speed: position.coords.speed,
                  timestamp: new Date().toISOString()
                });
              },
              function(error) {
                reject(new Error('Gagal mendapat lokasi: ' + error.message));
              },
              {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 0
              }
            );
          });
        },

        watchPosition: function(callback, errorCallback, interval = 5000) {
          if (!navigator.geolocation) {
            errorCallback(new Error('Geolocation tidak tersedia'));
            return null;
          }

          let watchId = navigator.geolocation.watchPosition(
            function(position) {
              const data = {
                latitude: position.coords.latitude,
                longitude: position.coords.longitude,
                accuracy: position.coords.accuracy,
                altitude: position.coords.altitude,
                altitudeAccuracy: position.coords.altitudeAccuracy,
                heading: position.coords.heading,
                speed: position.coords.speed,
                timestamp: new Date().toISOString()
              };
              callback(data);
            },
            function(error) {
              errorCallback(new Error('Error: ' + error.message));
            },
            {
              enableHighAccuracy: true,
              timeout: 10000,
              maximumAge: 0
            }
          );

          return watchId;
        },

        clearWatch: function(watchId) {
          if (navigator.geolocation && watchId !== null) {
            navigator.geolocation.clearWatch(watchId);
          }
        }
      };
    ''';

    js.context.callMethod('eval', [script]);
  }

  /// Get current position sekali
  static Future<Map<String, dynamic>> getCurrentPosition() async {
    initializeJavaScript();

    try {
      final rkmGeolocation = js.context['rkmGeolocation'];
      if (rkmGeolocation == null) {
        throw Exception('Geolocation service tidak tersedia');
      }

      final result = await js.JsObject.fromBrowserObject(rkmGeolocation)
          .callMethod('getCurrentPosition', []) as dynamic;

      if (result is! Map) {
        throw Exception('Invalid response dari browser');
      }

      return {
        'latitude': (result['latitude'] as num).toDouble(),
        'longitude': (result['longitude'] as num).toDouble(),
        'accuracy': (result['accuracy'] as num).toDouble(),
        'altitude': (result['altitude'] as num).toDouble(),
        'heading': (result['heading'] as num).toDouble(),
        'speed': (result['speed'] as num).toDouble(),
        'timestamp': result['timestamp'] as String,
      };
    } catch (e) {
      throw Exception('Browser Geolocation Error: $e');
    }
  }

  /// Watch position continuously
  static int? _watchId;

  static Future<Stream<Map<String, dynamic>>> watchPosition() async {
    initializeJavaScript();

    final controller = StreamController<Map<String, dynamic>>();

    try {
      final rkmGeolocation = js.context['rkmGeolocation'];
      if (rkmGeolocation == null) {
        controller.addError(Exception('Geolocation service tidak tersedia'));
        return controller.stream;
      }

      _watchId = js.JsObject.fromBrowserObject(rkmGeolocation).callMethod(
        'watchPosition',
        [
          (position) {
            if (position is Map) {
              controller.add({
                'latitude': (position['latitude'] as num).toDouble(),
                'longitude': (position['longitude'] as num).toDouble(),
                'accuracy': (position['accuracy'] as num).toDouble(),
                'altitude': (position['altitude'] as num).toDouble(),
                'heading': (position['heading'] as num).toDouble(),
                'speed': (position['speed'] as num).toDouble(),
                'timestamp': position['timestamp'] as String,
              });
            }
          },
          (error) {
            controller.addError(Exception(error.toString()));
          },
        ],
      ) as int;

      return controller.stream;
    } catch (e) {
      controller.addError(Exception('Watch Position Error: $e'));
      return controller.stream;
    }
  }

  /// Stop watching position
  static void clearWatch() {
    if (_watchId == null) return;

    try {
      initializeJavaScript();
      final rkmGeolocation = js.context['rkmGeolocation'];
      if (rkmGeolocation != null) {
        js.JsObject.fromBrowserObject(rkmGeolocation)
            .callMethod('clearWatch', [_watchId]);
        _watchId = null;
      }
    } catch (e) {
      print('Error clearing watch: $e');
    }
  }
}
