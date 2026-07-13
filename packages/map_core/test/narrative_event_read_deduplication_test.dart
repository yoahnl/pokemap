import 'package:map_core/src/read_models/narrative_event_read_deduplication.dart';
import 'package:test/test.dart';

void main() {
  test('Phase D diagnostic dedup keeps first values sorted and immutable', () {
    final result = deduplicateNarrativeEventReadValues(
      values: const [
        (key: 'b', payload: 'first b'),
        (key: 'a', payload: 'first a'),
        (key: 'b', payload: 'second b'),
      ],
      keyOf: (value) => value.key,
      compare: (left, right) => left.key.compareTo(right.key),
    );

    expect(result, const [
      (key: 'a', payload: 'first a'),
      (key: 'b', payload: 'first b'),
    ]);
    expect(
      () => result.add((key: 'c', payload: 'third')),
      throwsUnsupportedError,
    );
  });
}
