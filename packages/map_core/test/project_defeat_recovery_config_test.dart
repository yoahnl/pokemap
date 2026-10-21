import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final fact = NarrativeFactDefinition(
    id: 'recovered',
    label: 'Retour après défaite',
  );
  ProjectManifest project({
    ProjectDefeatRecoveryConfig? config,
    List<NarrativeFactDefinition>? facts,
  }) => ProjectManifest(
    name: 'Recovery',
    maps: const [],
    tilesets: const [],
    facts: facts ?? [fact],
    defeatRecovery: config,
  );
  const config = ProjectDefeatRecoveryConfig(recoveredFactId: 'recovered');
  test(
    'optional recovery contract round trips without changing new game or money policy',
    () {
      final plain = project();
      expect(plain.toJson().containsKey('defeatRecovery'), isFalse);
      final configured = project(config: config);
      expect(
        ProjectManifest.fromJson(configured.toJson()).defeatRecovery,
        config,
      );
      expect(configured.newGame, plain.newGame);
      expect(config.toJson(), {'recoveredFactId': 'recovered'});
      ProjectValidator.validate(configured);
    },
  );
  test('referenced recovery Fact cannot be deleted or retyped', () {
    final configured = project(config: config);
    expect(
      () => removeNarrativeFact(configured, factId: 'recovered'),
      throwsArgumentError,
    );
    final preview = previewNarrativeFactTypeChange(
      configured,
      factId: 'recovered',
      nextKind: NarrativeValueKind.integer,
    );
    expect(preview.canApply, isFalse);
    expect(preview.usages.single.path, 'defeatRecovery.recoveredFactId');
  });
  test('wire refuses empty, unknown, non-string and metadata fields', () {
    for (final json in <Map<String, dynamic>>[
      {},
      {'recoveredFactId': ''},
      {'recoveredFactId': ' recovered'},
      {'recoveredFactId': 1},
      {'recoveredFactId': 'recovered', 'metadata': {}},
      {'recoveredFactId': 'recovered', 'value': false},
    ]) {
      expect(
        () => ProjectDefeatRecoveryConfig.fromJson(json),
        throwsFormatException,
      );
    }
  });
  test('validated recovery requires one unambiguous boolean Fact', () {
    for (final facts in <List<NarrativeFactDefinition>>[
      [],
      [
        NarrativeFactDefinition(
          id: 'recovered',
          label: 'Count',
          initialValue: NarrativeValue.integer(0),
        ),
      ],
      [fact, fact],
      [
        fact,
        NarrativeFactDefinition(
          id: 'alias',
          label: 'Alias',
          legacyFlagName: 'recovered',
        ),
      ],
    ]) {
      expect(
        () => ProjectValidator.validate(project(config: config, facts: facts)),
        throwsA(isA<ValidationException>()),
      );
    }
  });
}
