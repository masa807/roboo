import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

class SchoolTime {
  static void initialize() => data.initializeTimeZones();
  static tz.Location get location => tz.getLocation('Asia/Damascus');
  static DateTime now() => tz.TZDateTime.now(location);
  static DateTime sessionStart(DateTime date, String time) {
    final parts = time.split(':');
    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
