import 'package:flutter_test/flutter_test.dart';

import 'package:transit_tracker/utils/formatters.dart';

void main() {
  test('formats distance in meters and kilometers', () {
    expect(formatDistanceMeters(950), '950 m');
    expect(formatDistanceMeters(1250), '1.25 km');
  });

  test('formats duration compactly', () {
    expect(formatDuration(const Duration(seconds: 42)), '42s');
    expect(formatDuration(const Duration(minutes: 4, seconds: 7)), '4m 7s');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1h 2m 3s');
  });

  test('formats speed in km/h', () {
    expect(formatSpeedMps(10), '36.0 km/h');
  });
}
