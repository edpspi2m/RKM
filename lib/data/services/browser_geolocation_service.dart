import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Service untuk akses Geolocation API Browser (hanya untuk web)
class BrowserGeolocationService {
  static const String _scriptId = 'rkm_geolocation_js';

  /// Initialize JavaScript untuk geolocation
  static void initializeJavaScript() {
    if (web.document.getElementById(_scriptId) != null) return;

    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.id = _scriptId;
    script.type = 'text/javascript';
    script.innerHTML = '''
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

    web.document.head!.appendChild(script);
  }

  /// Get current position sekali
  static Future<Map<String, dynamic>> getCurrentPosition() async {
    initializeJavaScript();

    final jsFunction = web.window.getProperty('rkmGeolocation'.toJS) as JSObject?;
    if (jsFunction == null) {
      throw Exception('Geolocation service tidak tersedia');
    }

    try {
      final getCurrentPositionFn =
          (jsFunction as JSObject).getProperty('getCurrentPosition'.toJS) as JSFunction;
      final result = await getCurrentPositionFn.callAsFunction().toDart;

      if (result is! JSObject) {
        throw Exception('Invalid response dari browser');
      }

      return {
        'latitude': (result.getProperty('latitude'.toJS) as JSNumber).toDartDouble,
        'longitude': (result.getProperty('longitude'.toJS) as JSNumber).toDartDouble,
        'accuracy': (result.getProperty('accuracy'.toJS) as JSNumber).toDartDouble,
        'altitude': (result.getProperty('altitude'.toJS) as JSNumber).toDartDouble,
        'heading': (result.getProperty('heading'.toJS) as JSNumber).toDartDouble,
        'speed': (result.getProperty('speed'.toJS) as JSNumber).toDartDouble,
        'timestamp': (result.getProperty('timestamp'.toJS) as JSString).toDartString,
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

    final jsFunction = web.window.getProperty('rkmGeolocation'.toJS) as JSObject?;
    if (jsFunction == null) {
      controller.addError(Exception('Geolocation service tidak tersedia'));
      return controller.stream;
    }

    try {
      final watchPositionFn =
          (jsFunction as JSObject).getProperty('watchPosition'.toJS) as JSFunction;

      _watchId = (await watchPositionFn.callAsFunction(
        (position) {
          if (position is JSObject) {
            controller.add({
              'latitude': (position.getProperty('latitude'.toJS) as JSNumber).toDartDouble,
              'longitude': (position.getProperty('longitude'.toJS) as JSNumber).toDartDouble,
              'accuracy': (position.getProperty('accuracy'.toJS) as JSNumber).toDartDouble,
              'altitude': (position.getProperty('altitude'.toJS) as JSNumber).toDartDouble,
              'heading': (position.getProperty('heading'.toJS) as JSNumber).toDartDouble,
              'speed': (position.getProperty('speed'.toJS) as JSNumber).toDartDouble,
              'timestamp': (position.getProperty('timestamp'.toJS) as JSString).toDartString,
            });
          }
        }.toJS,
        (error) {
          controller.addError(Exception(error.toString()));
        }.toJS,
      ).toDart as JSNumber).toInt();

      return controller.stream;
    } catch (e) {
      controller.addError(Exception('Watch Position Error: $e'));
      return controller.stream;
    }
  }

  /// Stop watching position
  static void clearWatch() {
    if (_watchId == null) return;

    initializeJavaScript();

    final jsFunction = web.window.getProperty('rkmGeolocation'.toJS) as JSObject?;
    if (jsFunction != null) {
      final clearWatchFn = (jsFunction as JSObject).getProperty('clearWatch'.toJS) as JSFunction;
      clearWatchFn.callAsFunction(_watchId);
      _watchId = null;
    }
  }
}
