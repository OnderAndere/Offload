import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/handwriting/reading_clock.dart';

/// The clock of the 5-minute stop (T6a.4, DD-021, PO 12-10-2026).
void main() {
  var now = Duration.zero;
  late ReadingClock clock;

  setUp(() {
    now = Duration.zero;
    clock = ReadingClock(() => now);
  });

  test('counts nothing before it runs', () {
    now = const Duration(minutes: 3);
    expect(clock.elapsed, Duration.zero);
    expect(clock.isRunning, isFalse);
  });

  test('counts while it runs', () {
    clock.run();
    now = const Duration(seconds: 90);
    expect(clock.elapsed, const Duration(seconds: 90));
    expect(clock.isRunning, isTrue);
  });

  test('a pause (outside the app) does not count', () {
    clock.run();
    now = const Duration(minutes: 1);
    clock.pause();
    now = const Duration(minutes: 30);
    expect(clock.elapsed, const Duration(minutes: 1));
    clock.run();
    now = const Duration(minutes: 32);
    expect(clock.elapsed, const Duration(minutes: 3));
  });

  test('run twice and pause twice change nothing', () {
    clock.run();
    now = const Duration(seconds: 10);
    clock.run();
    now = const Duration(seconds: 20);
    clock.pause();
    clock.pause();
    expect(clock.elapsed, const Duration(seconds: 20));
  });
}
