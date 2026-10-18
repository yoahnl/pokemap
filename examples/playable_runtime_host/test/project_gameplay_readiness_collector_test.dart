import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/project_gameplay_readiness_collector.dart';

void main() {
  final project = _readinessProject();

  test('collects executable product and structural project readiness', () {
    final result = const ProjectGameplayReadinessCollector().collect(
      project: project,
      receipt: _receipt(),
      expectedCommit: 'a' * 40,
      actualProjectTreeHashSha256: 'b' * 64,
      capabilityTruth: _truth(),
    );

    expect(result.isReady, isTrue);
    expect(result.issues, isEmpty);
    expect(result.report.isPlayable, isTrue);
    expect(result.report.infos, hasLength(11));
  });

  test('rejects stale commit and changed project tree', () {
    final result = const ProjectGameplayReadinessCollector().collect(
      project: project,
      receipt: _receipt(),
      expectedCommit: 'c' * 40,
      actualProjectTreeHashSha256: 'd' * 64,
      capabilityTruth: _truth(),
    );

    expect(result.isReady, isFalse);
    expect(result.issues, hasLength(2));
    expect(result.issues.join(' '), contains('commit'));
    expect(result.issues.join(' '), contains('tree hash'));
  });

  test('rejects missing, duplicate or failed product observations', () {
    final missingCriteria = _criteria()
        .where((item) => item.criterion != MvpProductCriterion.mvp09PcOverflow)
        .toList(growable: false);
    final duplicateCriteria = <MvpProductCriterionEvidence>[
      ..._criteria(),
      const MvpProductCriterionEvidence(
        criterion: MvpProductCriterion.mvp16Shop,
        status: MvpProductCriterionStatus.passed,
        summary: 'Duplicate.',
        source: 'duplicate',
      ),
    ];
    final failedCriteria = _criteria()
        .map(
          (item) => item.criterion == MvpProductCriterion.mvp18SaveLoad
              ? const MvpProductCriterionEvidence(
                  criterion: MvpProductCriterion.mvp18SaveLoad,
                  status: MvpProductCriterionStatus.failed,
                  summary: 'Reload failed.',
                  source: 'journey',
                )
              : item,
        )
        .toList(growable: false);

    for (final criteria in <List<MvpProductCriterionEvidence>>[
      missingCriteria,
      duplicateCriteria,
      failedCriteria,
    ]) {
      final result = const ProjectGameplayReadinessCollector().collect(
        project: project,
        receipt: _receipt(criteria: criteria),
        expectedCommit: 'a' * 40,
        actualProjectTreeHashSha256: 'b' * 64,
        capabilityTruth: _truth(),
      );
      expect(result.isReady, isFalse);
    }
  });

  test('a non-zero journey execution fails every derived check closed', () {
    final result = const ProjectGameplayReadinessCollector().collect(
      project: project,
      receipt: _receipt(exitCode: 1),
      expectedCommit: 'a' * 40,
      actualProjectTreeHashSha256: 'b' * 64,
      capabilityTruth: _truth(),
    );

    expect(result.isReady, isFalse);
    expect(result.issues.join(' '), contains('exit code 1'));
    expect(result.report.errors, isNotEmpty);
  });

  test(
    'fails event-command readiness on an incomplete promoted capability',
    () {
      final result = const ProjectGameplayReadinessCollector().collect(
        project: project,
        receipt: _receipt(),
        expectedCommit: 'a' * 40,
        actualProjectTreeHashSha256: 'b' * 64,
        capabilityTruth: const [
          ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'narrative.command.test',
            authoringControl: 'Event Builder',
            contractField: 'SceneConsequence.test',
            runtimeConsumer: '',
            playerSurface: 'Scene flow',
            positiveTest: 'positive_test.dart',
            negativeTest: 'negative_test.dart',
          ),
        ],
      );

      expect(result.isReady, isFalse);
      expect(
        result.report.errors
            .singleWhere(
              (diagnostic) =>
                  diagnostic.check ==
                  ProjectGameplayReadinessCheck.eventCommands,
            )
            .summary,
        contains('missingRuntimeConsumer'),
      );
    },
  );
}

MvpReleaseEvidenceReceipt _receipt({
  int exitCode = 0,
  List<MvpProductCriterionEvidence>? criteria,
}) => MvpReleaseEvidenceReceipt.validated(
  command: 'flutter test test/synthetic_player_journey_test.dart',
  exitCode: exitCode,
  releaseCandidateCommit: 'a' * 40,
  capturedAtUtc: DateTime.utc(2026, 7, 23),
  source: 'test/synthetic_player_journey_test.dart',
  projectTreeHashSha256: 'b' * 64,
  criteria: criteria ?? _criteria(),
);

List<MvpProductCriterionEvidence> _criteria() => MvpProductCriterion.values
    .map(
      (criterion) => MvpProductCriterionEvidence(
        criterion: criterion,
        status: MvpProductCriterionStatus.passed,
        summary: '${criterion.id} observed in the product journey.',
        source: 'journey:${criterion.id}',
      ),
    )
    .toList(growable: false);

List<ProjectCapabilityTruthRecord> _truth() {
  final catalog = NarrativeCommandCatalog.canonical();
  final attestation = ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in catalog.publishable)
        command.id: 'verified_adapter.dart#${command.id}',
    },
  );
  return buildNarrativeCommandCapabilityTruthMatrix(
    catalog: catalog,
    authoring: attestation,
    runtime: attestation,
    playerSurface: attestation,
    positiveTests: attestation,
    negativeTests: attestation,
  );
}

ProjectManifest _readinessProject() => ProjectManifest(
  name: 'Synthetic readiness project',
  maps: [
    for (final id in ['alpha', 'beta', 'gamma'])
      ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
  ],
  tilesets: [],
  newGame: const ProjectNewGameConfig(
    enabled: true,
    startMapId: 'alpha',
    preSessionSceneId: 'prepare',
    starterOptions: [
      ProjectStarterOption(
        id: 'choice',
        label: 'Test companion',
        pokemon: PlayerPokemon(
          speciesId: 'fixture-species',
          natureId: 'fixture-nature',
          abilityId: 'fixture-ability',
        ),
      ),
    ],
  ),
  encounterTables: const [
    ProjectEncounterTable(
      id: 'encounters',
      name: 'Test encounters',
      encounterKind: EncounterKind.walk,
      entries: [
        ProjectEncounterEntry(
          speciesId: 'fixture-species',
          minLevel: 2,
          maxLevel: 3,
        ),
      ],
    ),
  ],
  trainers: const [
    ProjectTrainerEntry(
      id: 'trainer',
      name: 'Test trainer',
      trainerClass: 'Test',
      team: [
        ProjectTrainerPokemonEntry(speciesId: 'fixture-species', level: 3),
      ],
    ),
  ],
  shops: const [
    ShopDefinition(
      id: 'shop',
      label: 'Test shop',
      entries: [ShopEntryDefinition(itemId: 'fixture-item', price: 10)],
    ),
  ],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'dialogue',
      name: 'Test dialogue',
      relativePath: 'dialogues/intro.yarn',
    ),
  ],
  facts: [NarrativeFactDefinition(id: 'ready', label: 'Ready')],
  storylines: [
    StorylineAsset(
      id: 'story',
      title: 'Test progression',
      type: StorylineType.main,
    ),
  ],
  scenes: [
    SceneAsset(
      id: 'prepare',
      name: 'Test setup',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'unlock',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload(
              consequence: SceneUnlockFieldAbilityConsequence(
                ability: FieldAbility.cut,
              ),
            ),
          ),
          SceneNode(id: 'condition', kind: SceneNodeKind.condition),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
      ),
    ),
  ],
);
