import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // ❌ JANGAN init background service di sini
  // Init nanti dilakukan saat user aktifkan "Perjalanan"
  // Ini fix utama force close di Android 12+

  runApp(const RkmApp());
}
