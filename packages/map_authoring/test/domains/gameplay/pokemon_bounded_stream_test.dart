import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('bounded stream keeps data up to the limit', () async {
    final result = await collectPokemonExternalBytes(
      Stream.fromIterable([
        [1, 2],
        [3],
      ]),
      maximumBytes: 3,
      timeout: const Duration(seconds: 1),
    );
    expect(result, [1, 2, 3]);
  });

  test('oversized stream is cancelled instead of reading the remainder',
      () async {
    var cancelled = false;
    final stream = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    final result = collectPokemonExternalBytes(
      stream.stream,
      maximumBytes: 3,
      timeout: const Duration(seconds: 1),
    );
    stream.add([1, 2]);
    stream.add([3, 4]);
    await expectLater(result, throwsFormatException);
    expect(cancelled, isTrue);
    await stream.close();
  });

  test('stalled stream is cancelled at the total deadline', () async {
    var cancelled = false;
    final stream = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    final result = collectPokemonExternalBytes(
      stream.stream,
      maximumBytes: 3,
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(result, throwsA(isA<TimeoutException>()));
    expect(cancelled, isTrue);
    await stream.close();
  });
}
