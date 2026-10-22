import 'package:crowned_connections/services/salon_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('salon date rolls over from UTC independently of the device timezone',
      () {
    final date = salonTime(DateTime.parse('2026-10-20T23:30:00Z'));
    expect(date.day, 21);
    expect(date.hour, 1);
    expect(date.minute, 30);
  });
  test('an explicit South African offset keeps its wall-clock hour', () {
    expect(salonTime(DateTime.parse('2026-10-20T08:00:00+02:00')).hour, 8);
  });
}
