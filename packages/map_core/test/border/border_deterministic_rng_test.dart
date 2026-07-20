import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/border_deterministic_rng_golden.dart';

void main() {
  group('Border RNG key framing', () {
    test('matches literal signed-int64 preimage and FNV/xorshift goldens', () {
      for (final vector in borderSignedInt64RngGoldenVectors) {
        final component = BorderRngKeyComponent.signedInt64(
          BorderSignedInt64.parse(vector.signedInt64),
        );
        final preimage = encodeBorderRngKey([component]);

        expect(_hex(preimage), vector.preimageHex, reason: vector.name);
        expect(
          _hex64(borderFnv1a64(preimage)),
          vector.fnv1a64Hex,
          reason: vector.name,
        );
        expect(
          _hex64(
            BorderDeterministicRng.fromComponents([component]).nextUint64(),
          ),
          vector.firstUint64Hex,
          reason: vector.name,
        );
      }
    });

    test('uses UTF-8 payload lengths rather than UTF-16 code units', () {
      final encoded = encodeBorderRngKey([
        BorderRngKeyComponent.text('côte'),
        BorderRngKeyComponent.text('🌊'),
      ]);

      expect(_hex(encoded), borderUtf8TuplePreimageHex);
    });

    test('length framing distinguishes ambiguous text tuples', () {
      final abC = encodeBorderRngKey([
        BorderRngKeyComponent.text('ab'),
        BorderRngKeyComponent.text('c'),
      ]);
      final aBc = encodeBorderRngKey([
        BorderRngKeyComponent.text('a'),
        BorderRngKeyComponent.text('bc'),
      ]);

      expect(_hex(abC), borderAbCPreimageHex);
      expect(_hex(aBc), borderABcPreimageHex);
      expect(abC, isNot(aBc));
    });

    test('type framing distinguishes text from signed int64', () {
      final text = encodeBorderRngKey([BorderRngKeyComponent.text('0')]);
      final integer = encodeBorderRngKey([
        BorderRngKeyComponent.signedInt64(BorderSignedInt64.zero),
      ]);

      expect(text, isNot(integer));
    });

    test('rejects unpaired surrogates instead of creating UTF-8 collisions',
        () {
      for (final malformed in <String>['\uD800', '\uDC00']) {
        expect(
          () => encodeBorderRngKey([BorderRngKeyComponent.text(malformed)]),
          throwsArgumentError,
        );
      }
    });
  });

  group('BorderDeterministicRng', () {
    test('matches literal raw-state vectors including zero fallback', () {
      for (final vector in borderRawStateRngGoldenVectors) {
        final rng = BorderDeterministicRng.fromState(
          BigInt.parse(vector.stateHex, radix: 16),
        );

        expect(
          _hex64(rng.nextUint64()),
          vector.firstUint64Hex,
          reason: vector.name,
        );
      }
    });

    test('nextIndex is deterministic and validates its exclusive bound', () {
      final rng = BorderDeterministicRng.fromComponents([
        BorderRngKeyComponent.text('index'),
      ]);

      expect(rng.nextIndex(7), 5);
      expect(() => rng.nextIndex(0), throwsArgumentError);
      expect(() => rng.nextIndex(-1), throwsArgumentError);
    });

    test('independent component tuples create independent local streams', () {
      final first = BorderDeterministicRng.fromComponents([
        BorderRngKeyComponent.text('region-a'),
        BorderRngKeyComponent.signedInt64(BorderSignedInt64.fromInt(3)),
      ]);
      final equal = BorderDeterministicRng.fromComponents([
        BorderRngKeyComponent.text('region-a'),
        BorderRngKeyComponent.signedInt64(BorderSignedInt64.fromInt(3)),
      ]);
      final other = BorderDeterministicRng.fromComponents([
        BorderRngKeyComponent.text('region-b'),
        BorderRngKeyComponent.signedInt64(BorderSignedInt64.fromInt(3)),
      ]);

      expect(first.nextUint64(), equal.nextUint64());
      expect(
        other.nextUint64(),
        isNot(
          BorderDeterministicRng.fromComponents([
            BorderRngKeyComponent.text('region-a'),
            BorderRngKeyComponent.signedInt64(BorderSignedInt64.fromInt(3)),
          ]).nextUint64(),
        ),
      );
    });
  });

  group('stable Border weighted choice', () {
    test('sorts by stable ID and ignores insertion order', () {
      final candidates = [
        BorderWeightedCandidate(id: 'b', value: 'second', weight: 2),
        BorderWeightedCandidate(id: 'a', value: 'first', weight: 1),
      ];
      final reversed = candidates.reversed.toList();

      final first = chooseBorderWeightedCandidate(
        BorderDeterministicRng.fromComponents([
          BorderRngKeyComponent.text('weighted'),
        ]),
        candidates,
      );
      final second = chooseBorderWeightedCandidate(
        BorderDeterministicRng.fromComponents([
          BorderRngKeyComponent.text('weighted'),
        ]),
        reversed,
      );

      expect(first?.id, 'b');
      expect(first, second);
    });

    test('excludes zero/negative weights and returns null without a choice',
        () {
      final candidates = [
        BorderWeightedCandidate(id: 'negative', value: 1, weight: -5),
        BorderWeightedCandidate(id: 'zero', value: 2, weight: 0),
      ];

      expect(
        chooseBorderWeightedCandidate(
          BorderDeterministicRng.fromComponents([
            BorderRngKeyComponent.text('none'),
          ]),
          candidates,
        ),
        isNull,
      );
    });

    test('rejects duplicate positive candidate IDs as nondeterministic input',
        () {
      expect(
        () => chooseBorderWeightedCandidate(
          BorderDeterministicRng.fromComponents([
            BorderRngKeyComponent.text('duplicates'),
          ]),
          [
            BorderWeightedCandidate(id: 'same', value: 1, weight: 1),
            BorderWeightedCandidate(id: 'same', value: 2, weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

String _hex64(BigInt value) => value.toRadixString(16).padLeft(16, '0');
