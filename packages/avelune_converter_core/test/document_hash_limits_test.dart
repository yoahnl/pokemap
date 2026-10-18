import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'contracts_test.dart' show fixture;

Object? _reverseKeys(Object? value) => switch (value) {
      Map() => {
          for (final key in value.keys.toList().reversed)
            key: _reverseKeys(value[key])
        },
      List() => value.map(_reverseKeys).toList(),
      _ => value,
    };

void main() {
  test('large admitted plan hashes with its admitted text limits', () {
    final input = fixture('conversion_plan');
    final hash = 'a' * 64;
    input['operations'] = [
      for (var index = 0; index < 12394; index++)
        {
          'operationId': 'world.hash.probe.$index',
          'domain': 'maps',
          'sourceEntityIds': ['s1:$hash'],
          'targetEntityIds': ['native-map-$index'],
          'targetActionId': 'map.save',
          'status': 'planned',
          'evidenceRefs': [
            'native-draft-sha256:$hash',
            'source-study-ack-sha256:$hash',
            'study-settings-sha256:$hash',
          ],
        },
    ];
    const limits =
        ContractLimits(maxNodes: 4000000, maxTextCodeUnits: 16777216);
    expect(
        () => ConversionPlan.fromJson(input),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'json.textQuota')));
    final document = ConversionPlan.fromJson(input, limits: limits);
    final expected = canonicalHashOf(document.toJson(), limits: limits);
    expect(
        utf8.encode(canonicalJsonOf(document.toJson(), limits: limits)).length,
        greaterThan(const ContractLimits().maxTextCodeUnits));
    (input['operations'] as List).clear();
    expect(document.operations, hasLength(12394));
    expect(document.canonicalHash, expected);
    expect(identical(document.canonicalHash, document.canonicalHash), isTrue);
    expect(() => (document.toJson()['operations'] as List).clear(),
        throwsUnsupportedError);
  });

  test('large admitted source hashes with its independent node limits', () {
    final input = fixture('source_map_ir');
    final map = input['map'] as Map;
    map['width'] = 1000;
    map['height'] = 334;
    map['layers'] = [
      for (var z = 0; z < 3; z++)
        {'sourceZ': z, 'cells': List<int>.filled(334000, 0)}
    ];
    const limits = ContractLimits(maxNodes: 1100000);
    expect(
        () => SourceMapIr.fromJson(input),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'json.quota')));
    final document = SourceMapIr.fromJson(input, limits: limits);
    final expected = canonicalHashOf(document.toJson(), limits: limits);
    expect(document.canonicalHash, expected);
    expect(identical(document.canonicalHash, document.canonicalHash), isTrue);
  });

  for (final name in [
    'source_map_ir',
    'asset_candidate',
    'review_decisions',
    'vision_response',
    'target_capabilities',
    'conversion_plan',
    'conversion_report',
  ]) {
    test(
        '$name retains canonical key order and frozen ownership under custom limits',
        () {
      final input = fixture(name);
      const limits =
          ContractLimits(maxNodes: 2000000, maxTextCodeUnits: 8388608);
      final expected = canonicalHashOf(input);
      final document = decodeContract(_reverseKeys(input), limits: limits);
      final typed = switch (document) {
        SourceMapIr() => SourceMapIr.fromJson(input, limits: limits),
        AssetCandidate() => AssetCandidate.fromJson(input, limits: limits),
        ReviewDecisions() => ReviewDecisions.fromJson(input, limits: limits),
        VisionResponse() => VisionResponse.fromJson(input, limits: limits),
        TargetCapabilities() =>
          TargetCapabilities.fromJson(input, limits: limits),
        ConversionPlan() => ConversionPlan.fromJson(input, limits: limits),
        ConversionReport() => ConversionReport.fromJson(input, limits: limits),
      };
      input.clear();
      expect(document.canonicalHash, expected);
      expect(typed.canonicalHash, expected);
      expect(identical(document.canonicalHash, document.canonicalHash), isTrue);
      expect(() => document.toJson().clear(), throwsUnsupportedError);
      expect(
          () => decodeContract(fixture(name),
              limits: const ContractLimits(maxNodes: 1)),
          throwsA(isA<ContractError>()
              .having((error) => error.code, 'code', 'json.quota')));
    });
  }
}
