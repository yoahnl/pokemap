import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final config = {
    'enabledFactId': 'savings-enabled',
    'balanceFactId': 'savings-balance',
    'percentage': 25,
    'maximumBalance': 999999,
  };
  final facts = [
    NarrativeFactDefinition(id: 'savings-enabled', label: 'Saving enabled'),
    NarrativeFactDefinition(
      id: 'savings-balance',
      label: 'Savings',
      initialValue: NarrativeValue.integer(0),
    ),
  ];
  ProjectManifest project(Object? value) => ProjectManifest.fromJson({
    ...ProjectManifest(
      name: 'Savings',
      maps: [],
      tilesets: [],
      facts: facts,
    ).toJson(),
    'battleSavings': value,
  });
  test('battle savings policy survives native manifest serialization', () {
    expect(project(config).toJson()['battleSavings'], config);
    expect(
      ProjectManifest(
        name: 'Legacy',
        maps: [],
        tilesets: [],
      ).toJson().containsKey('battleSavings'),
      isFalse,
    );
  });
  test('referenced savings Facts cannot be deleted or retyped', () {
    final configured = project(config);
    expect(
      () => removeNarrativeFact(configured, factId: 'savings-enabled'),
      throwsArgumentError,
    );
    expect(
      () => removeNarrativeFact(configured, factId: 'savings-balance'),
      throwsArgumentError,
    );
    for (final id in ['savings-enabled', 'savings-balance']) {
      final preview = previewNarrativeFactTypeChange(
        configured,
        factId: id,
        nextKind: id == 'savings-enabled'
            ? NarrativeValueKind.integer
            : NarrativeValueKind.boolean,
      );
      expect(preview.canApply, isFalse);
      expect(preview.usages.single.path, startsWith('battleSavings.'));
    }
  });
  test('invalid policies fail before a reward or authoring write', () {
    for (final invalid in [
      {...config, 'percentage': -1},
      {...config, 'percentage': 101},
      {...config, 'percentage': 25.0},
      {...config, 'maximumBalance': -1},
      {...config, 'enabledFactId': ' savings-enabled'},
      {...config, 'extra': true},
    ]) {
      expect(() => project(invalid), throwsFormatException);
    }
  });
  test('policy references must remain declared with compatible Fact types', () {
    for (final invalid in [
      {...config, 'enabledFactId': 'missing'},
      {
        ...config,
        'enabledFactId': 'savings-balance',
        'balanceFactId': 'savings-enabled',
      },
      {...config, 'balanceFactId': 'missing'},
    ]) {
      expect(
        () => ProjectValidator.validate(project(invalid)),
        throwsA(isA<ValidationException>()),
      );
    }
  });
}
