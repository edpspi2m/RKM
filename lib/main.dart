import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/background/background_location_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Init background service
  // Biar HP restart pun service auto-nyala (autoStartOnBoot: true)
  await BackgroundLocationHandler.initialize();

  runApp(const RkmApp());
}
