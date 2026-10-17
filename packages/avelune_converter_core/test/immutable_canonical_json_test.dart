import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  test('canonical immutable values detach containers and normalize numbers',
      () {
    final shared = List.generate(128, (index) => '$index').join();
    final list = <Object?>[1.0, -0.0, shared];
    final nested = <String, Object?>{
      'z': list,
      'a': {'b': 2, 'a': false}
    };
    final expected = canonicalJsonOf(nested);
    final result = immutableCanonicalJsonOf(nested) as Map<String, Object?>;
    expect(result.keys, orderedEquals(['a', 'z']));
    expect((result['a'] as Map).keys, orderedEquals(['a', 'b']));
    expect((result['z'] as List)[0], isA<int>());
    expect((result['z'] as List)[1], 0);
    expect(identical((result['z'] as List)[2], shared), isTrue);
    list.clear();
    nested.clear();
    expect(canonicalJsonOf(result), expected);
    expect(() => result.clear(), throwsUnsupportedError);
    expect(() => (result['a'] as Map).clear(), throwsUnsupportedError);
    expect(() => (result['z'] as List).clear(), throwsUnsupportedError);
  });

  test('every inert scalar and typed byte list keep canonical JSON equality',
      () {
    for (final value in [
      null,
      false,
      true,
      0,
      -1,
      9007199254740993,
      1.5,
      -0.0,
      9007199254740992.0,
      'Pokémon\n\t\u0000',
      String.fromCharCode(0xd800),
      Uint8List.fromList([0, 1, 255]),
      <String, Object?>{},
      <Object?>[],
    ]) {
      expect(canonicalJsonOf(immutableCanonicalJsonOf(value)),
          canonicalJsonOf(value));
    }
  });

  test(
      'canonical value and canonical text have the same isolated quota boundaries',
      () {
    final value = <String, Object?>{
      'a': [
        'one',
        'two',
        {'a': 1, 'z': 2}
      ],
      'z': {'nested': null}
    };
    final cases = [
      for (var n = 1; n < 30; n++) ContractLimits(maxNodes: n),
      for (var n = 1; n < 8; n++) ContractLimits(maxDepth: n),
      for (var n = 1; n < 50; n++) ContractLimits(maxTextCodeUnits: n),
      for (var n = 1; n < 10; n++) ContractLimits(maxStringCodeUnits: n),
    ];
    for (final limits in cases) {
      String? code;
      try {
        canonicalJsonOf(value, limits: limits);
      } on ContractError catch (error) {
        code = error.code;
      }
      if (code == null) {
        expect(canonicalJsonOf(immutableCanonicalJsonOf(value, limits: limits)),
            canonicalJsonOf(value));
      } else {
        expect(
            () => immutableCanonicalJsonOf(value, limits: limits),
            throwsA(isA<ContractError>()
                .having((error) => error.code, 'code', code)));
      }
    }
  });

  test('non JSON values and cycles remain invalid', () {
    final list = <Object?>[];
    list.add(list);
    for (final value in [
      list,
      double.nan,
      double.infinity,
      {1: 'bad'},
      Object()
    ]) {
      String? code;
      try {
        canonicalJsonOf(value);
      } on ContractError catch (error) {
        code = error.code;
      }
      expect(code, isNotNull);
      expect(
          () => immutableCanonicalJsonOf(value),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', code)));
    }
  });
}
