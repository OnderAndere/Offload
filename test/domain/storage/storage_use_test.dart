import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/storage/storage_use.dart';

/// Sizes in Settings → Storage (T7.5): decimal units, as Android shows them.
void main() {
  test('nothing is 0 kB; any content at least 1 kB', () {
    expect(byteAmount(0), (value: 0.0, unit: ByteUnit.kilobytes));
    expect(byteAmount(1), (value: 1.0, unit: ByteUnit.kilobytes));
    expect(byteAmount(2500), (value: 3.0, unit: ByteUnit.kilobytes));
  });

  test('megabytes and gigabytes with one decimal', () {
    expect(byteAmount(999000), (value: 999.0, unit: ByteUnit.kilobytes));
    // The unit follows the rounded value (review).
    expect(byteAmount(999999), (value: 1.0, unit: ByteUnit.megabytes));
    expect(byteAmount(999960000), (value: 1.0, unit: ByteUnit.gigabytes));
    expect(byteAmount(1000000), (value: 1.0, unit: ByteUnit.megabytes));
    expect(byteAmount(2449999), (value: 2.4, unit: ByteUnit.megabytes));
    expect(byteAmount(1250000000), (value: 1.3, unit: ByteUnit.gigabytes));
  });
}
