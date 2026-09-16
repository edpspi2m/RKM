import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/background/background_location_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Init background service — DIBUNGKUS TRY/CATCH
  // Kalau gagal, app tetap jalan (cuma tracking yang gak aktif)
  try {
    await BackgroundLocationHandler.initialize();
  } catch (e, st) {
    debugPrint('⚠️ Init background service gagal: $e');
    debugPrint('$st');
  }

  runApp(const RkmApp());
}
