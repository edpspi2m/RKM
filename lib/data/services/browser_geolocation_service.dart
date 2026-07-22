/// File ini otomatis memilih implementasi yang sesuai platform saat kompilasi:
/// - Android/iOS (mobile) -> pakai versi stub (tidak melakukan apa-apa,
///   karena geolocation di mobile sudah ditangani package `geolocator`,
///   bukan lewat browser JavaScript).
/// - Web -> pakai versi asli yang manggil JS browser lewat dart:js.
///
/// Ini yang bikin build Android sebelumnya GAGAL: dart:js cuma ada di web,
/// tapi file lama meng-import-nya langsung tanpa pengecualian platform.
export 'browser_geolocation_stub.dart'
    if (dart.library.html) 'browser_geolocation_web.dart';
