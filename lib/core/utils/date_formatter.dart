import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String fullDateTime(DateTime date) =>
      DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);

  static String dateOnly(DateTime date) => DateFormat('dd/MM/yyyy', 'id_ID').format(date);

  static String timeOnly(DateTime date) => DateFormat('HH:mm:ss', 'id_ID').format(date);
}
