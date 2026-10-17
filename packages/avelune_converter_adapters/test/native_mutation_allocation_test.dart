import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  NativeMutation mutation(Map<String, Object?> parameters,
          {ContractLimits limits = const ContractLimits()}) =>
      NativeMutation(
          operationId: ConverterId('allocation-operation'),
          actionId: 'map.save',
          sourceEntityIds: [ConverterId('source-map')],
          targetEntityIds: [ConverterId('native-map')],
          parameters: parameters,
          limits: NativeWriteLimits(jsonLimits: limits));

  Map<String, Object?> envelope(Map<String, Object?> parameters) => {
        'operationId': 'allocation-operation',
        'actionId': 'map.save',
        'actionVersion': 1,
        'sourceEntityIds': ['source-map'],
        'targetEntityIds': ['native-map'],
        'parameters': parameters
      };

  test(
      'repeated immutable tile identities remain shared without mutable aliases',
      () {
    final shared = List.generate(1024, (index) => 'tile-${index % 10}').join();
    final nested = <String, Object?>{'z': 1.0, 'a': -0.0};
    final rows = <Object?>[
      for (var index = 0; index < 32; index++)
        {'tilesetId': shared, 'tileId': index}
    ];
    final parameters = <String, Object?>{'z': rows, 'a': nested};
    final expected = canonicalJsonOf(parameters);
    final result = mutation(parameters);
    expect(canonicalJsonOf(result.parameters), expected);
    expect(result.parameters.keys, orderedEquals(['a', 'z']));
    final retained = result.parameters['z'] as List;
    for (final row in retained.cast<Map>()) {
      expect(identical(row['tilesetId'], shared), isTrue);
    }
    nested['z'] = 2;
    rows.clear();
    parameters.clear();
    expect(canonicalJsonOf(result.parameters), expected);
    expect(() => result.parameters['new'] = 1, throwsUnsupportedError);
    expect(
        () => (result.parameters['a'] as Map)['z'] = 2, throwsUnsupportedError);
    expect(() => retained.clear(), throwsUnsupportedError);
    expect(
        () => (retained.first as Map)['tileId'] = 999, throwsUnsupportedError);
  });

  test(
      'metadata and parameter budgets match the canonical envelope at every boundary',
      () {
    final parameters = <String, Object?>{
      'nested': [
        {'z': 2.0, 'a': 'value'},
        {'a': true, 'b': null}
      ]
    };
    final cases = <ContractLimits>[
      for (var nodes = 1; nodes < 32; nodes++) ContractLimits(maxNodes: nodes),
      for (var depth = 1; depth < 9; depth++) ContractLimits(maxDepth: depth),
      for (var text = 1; text < 192; text++)
        ContractLimits(maxTextCodeUnits: text),
      for (var length = 1; length < 32; length++)
        ContractLimits(maxStringCodeUnits: length),
    ];
    for (final limits in cases) {
      String? expectedCode;
      try {
        canonicalJsonOf(envelope(parameters), limits: limits);
      } on ContractError catch (error) {
        expectedCode = error.code;
      }
      if (expectedCode == null) {
        expect(canonicalJsonOf(mutation(parameters, limits: limits).toJson(0)),
            canonicalJsonOf({...envelope(parameters), 'ordinal': 0}));
      } else {
        expect(
            () => mutation(parameters, limits: limits),
            throwsA(isA<ContractError>()
                .having((error) => error.code, 'code', expectedCode)));
      }
    }
  });

  test('multiple invalid fields preserve the original first diagnostic', () {
    final cycle = <Object?>[];
    cycle.add(cycle);
    for (final parameters in <Map<String, Object?>>[
      {'z': Object(), 'a': double.nan},
      {'z': double.infinity, 'a': Object()},
      {
        'z': {'z': Object(), 'a': double.nan},
        'a': cycle
      },
      {
        'z': cycle,
        'a': {1: 'bad'}
      },
    ]) {
      ContractError? expected;
      try {
        canonicalJsonOf(envelope(parameters));
      } on ContractError catch (error) {
        expected = error;
      }
      expect(expected, isNotNull);
      expect(
          () => mutation(parameters),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', expected!.code)
              .having((error) => error.path, 'path', expected.path)));
    }
  });

  test('cycles nonfinite numbers and non JSON values retain their refusals',
      () {
    final cycle = <Object?>[];
    cycle.add(cycle);
    for (final value in [
      cycle,
      double.nan,
      double.infinity,
      {1: 'value'},
      Object()
    ]) {
      String? expectedCode;
      try {
        canonicalJsonOf(envelope({'value': value}));
      } on ContractError catch (error) {
        expectedCode = error.code;
      }
      expect(expectedCode, isNotNull);
      expect(
          () => mutation({'value': value}),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', expectedCode)));
    }
  });
}
