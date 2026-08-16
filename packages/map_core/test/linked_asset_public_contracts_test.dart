import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Linked asset public contracts', () {
    test('builds dialogue contracts from manifest dialogues', () {
      final contracts = buildDialoguePublicContracts(
        _manifest(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_intro',
              name: 'Introduction',
              relativePath: 'dialogues/intro.yarn',
              defaultStartNode: 'Start',
            ),
          ],
        ),
      );

      expect(contracts, hasLength(1));
      final contract = contracts.single;
      expect(contract.id, 'dialogue_intro');
      expect(contract.label, 'Introduction');
      expect(contract.sourceRef, 'dialogues/intro.yarn');
      expect(contract.defaultStartNode, 'Start');
      expect(contract.availableStartNodes, isEmpty);
      expect(contract.declaredOutcomes, isEmpty);
      expect(contract.status, LinkedAssetContractStatus.available);
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        contains(LinkedAssetContractDiagnosticCode.missingOutcomeContract),
      );
    });

    test('reports a diagnostic when dialogue label falls back to technical id',
        () {
      final contracts = buildDialoguePublicContracts(
        _manifest(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_intro',
              name: '   ',
              relativePath: 'dialogues/intro.yarn',
            ),
          ],
        ),
      );

      final contract = contracts.single;
      expect(contract.label, 'dialogue_intro');
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          LinkedAssetContractDiagnosticCode.missingLabel,
          LinkedAssetContractDiagnosticCode.rawTechnicalLabel,
        ]),
      );
    });

    test('exposes declared dialogue outcomes without inventing labels', () {
      final dialogue = ProjectDialogueEntry.fromJson({
        'id': 'dialogue_intro',
        'name': 'Introduction',
        'relativePath': 'dialogues/intro.yarn',
        'declaredOutcomes': [
          {'id': 'accepted', 'label': 'Accepter'},
          {'id': 'refused', 'label': 'Refuser'},
        ],
      });

      final contract = buildDialoguePublicContracts(
        _manifest(dialogues: [dialogue]),
      ).single;

      expect(
        contract.declaredOutcomes,
        const [
          LinkedAssetOutcomeContract(id: 'accepted', label: 'Accepter'),
          LinkedAssetOutcomeContract(id: 'refused', label: 'Refuser'),
        ],
      );
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains(
          LinkedAssetContractDiagnosticCode.missingOutcomeContract,
        )),
      );
    });

    test('builds trainer battle contracts without exposing map_battle types',
        () {
      final contracts = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_scout',
              name: 'Mina',
              trainerClass: 'Scout',
              team: [
                ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
              ],
            ),
          ],
        ),
      );

      expect(contracts, hasLength(1));
      final contract = contracts.single;
      expect(contract.id, 'trainer:trainer_scout');
      expect(contract.battleRefId, 'trainer:trainer_scout');
      expect(contract.battleTemplateId, isNull);
      expect(contract.label, 'Scout Mina');
      expect(contract.battleKind, BattlePublicContractKind.trainer);
      expect(contract.trainerId, 'trainer_scout');
      expect(contract.trainerLabel, 'Mina');
      expect(contract.status, LinkedAssetContractStatus.available);
      expect(contract.possibleOutcomes.map((outcome) => outcome.id), [
        'victory',
        'defeat',
      ]);
      expect(contract.diagnostics, isEmpty);
    });

    test('warns when a trainer battle has an empty team', () {
      final contracts = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_empty',
              name: 'Noa',
              trainerClass: 'Guide',
            ),
          ],
        ),
      );

      expect(
        contracts.single.diagnostics.map((diagnostic) => diagnostic.code),
        contains(LinkedAssetContractDiagnosticCode.emptyTrainerTeam),
      );
    });

    test('exposes tagged static encounter profiles as static contracts', () {
      final contract = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'boss_lanturn',
              name: 'Lanturn affolé',
              trainerClass: 'Pokémon du phare',
              team: [
                ProjectTrainerPokemonEntry(speciesId: 'lanturn', level: 14),
              ],
              tags: ['static-encounter', 'boss'],
            ),
          ],
        ),
      ).single;

      expect(contract.id, 'static:boss_lanturn');
      expect(contract.battleRefId, 'static:boss_lanturn');
      expect(contract.battleTemplateId, 'static:boss_lanturn');
      expect(contract.battleKind, BattlePublicContractKind.staticEncounter);
      expect(contract.possibleOutcomes.map((outcome) => outcome.id), [
        'victory',
        'defeat',
      ]);
    });

    test('preserves one stable static template already authored in Scenes', () {
      final contract = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'boss_lanturn',
              name: 'Lanturn affolé',
              trainerClass: 'Pokémon du phare',
              tags: ['static-encounter'],
            ),
          ],
          scenes: [
            _staticBattleScene(
              id: 'scene_lighthouse_boss',
              trainerId: 'boss_lanturn',
              battleTemplateId: 'battle_lighthouse_pokemon',
            ),
          ],
        ),
      ).single;

      expect(contract.battleRefId, 'static:boss_lanturn');
      expect(contract.battleTemplateId, 'battle_lighthouse_pokemon');
      expect(contract.status, LinkedAssetContractStatus.available);
    });

    test('does not invent a fallback for an incomplete existing static Scene',
        () {
      final contract = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'boss_lanturn',
              name: 'Lanturn affolé',
              trainerClass: 'Pokémon du phare',
              tags: ['static-encounter'],
            ),
          ],
          scenes: [
            _staticBattleScene(
              id: 'scene_lighthouse_boss',
              trainerId: 'boss_lanturn',
            ),
          ],
        ),
      ).single;

      expect(contract.battleTemplateId, isNull);
      expect(contract.status, LinkedAssetContractStatus.unavailable);
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          LinkedAssetContractDiagnosticCode.missingBattleTemplateRef,
        ),
      );
    });

    test('fails closed when one static profile has incompatible templates', () {
      final contract = buildBattlePublicContracts(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'boss_lanturn',
              name: 'Lanturn affolé',
              trainerClass: 'Pokémon du phare',
              tags: ['static-encounter'],
            ),
          ],
          scenes: [
            _staticBattleScene(
              id: 'scene_lighthouse_boss_a',
              trainerId: 'boss_lanturn',
              battleTemplateId: 'battle_lighthouse_pokemon',
            ),
            _staticBattleScene(
              id: 'scene_lighthouse_boss_b',
              trainerId: 'boss_lanturn',
              battleTemplateId: 'battle_lighthouse_storm',
            ),
          ],
        ),
      ).single;

      expect(contract.battleTemplateId, isNull);
      expect(contract.status, LinkedAssetContractStatus.unavailable);
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          LinkedAssetContractDiagnosticCode.ambiguousBattleTemplateRef,
        ),
      );
    });

    test('does not build cinematic contracts from Scenario metadata', () {
      final contracts = buildCinematicPublicContracts(
        _manifest(
          scenarios: const [
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Bridge Cutscene',
              entryNodeId: 'start',
              metadata: {
                'authoring.cutsceneSchema': 'cutscene_studio_v2',
              },
            ),
          ],
        ),
      );

      expect(contracts, isEmpty);
    });

    test('builds canonical cinematic asset contracts only', () {
      final contracts = buildCinematicPublicContracts(
        _manifest(
          cinematics: [
            CinematicAsset(
              id: 'cinematic_intro',
              title: 'Intro Cinematic',
              mapId: 'map_lab',
              requiredActors: [
                CinematicActorRef(actorId: 'actor_professor'),
              ],
              timeline: CinematicTimeline(
                steps: [
                  CinematicTimelineStep(
                    id: 'step_wait',
                    kind: CinematicTimelineStepKind.wait,
                    durationMs: 100,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      expect(contracts.map((contract) => contract.id), ['cinematic_intro']);
      final canonical =
          contracts.singleWhere((contract) => contract.id == 'cinematic_intro');
      expect(
        canonical.sourceKind,
        CinematicPublicContractSourceKind.cinematicAsset,
      );
      expect(canonical.status, LinkedAssetContractStatus.available);
      expect(canonical.linear, isTrue);
      expect(canonical.requiredActors, ['actor_professor']);
      expect(canonical.mapId, 'map_lab');
      expect(canonical.declaredOutputs.map((outcome) => outcome.id), [
        'completed',
      ]);
    });

    test('does not expose regular scenarios as cinematic contracts', () {
      final contracts = buildCinematicPublicContracts(
        _manifest(
          scenarios: const [
            ScenarioAsset(
              id: 'regular_scenario',
              name: 'Regular Scenario',
              entryNodeId: 'start',
            ),
          ],
        ),
      );

      expect(contracts, isEmpty);
    });

    test('snapshot aggregates contracts and keeps action and branch disabled',
        () {
      final snapshot = buildLinkedAssetContractsSnapshot(
        _manifest(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_intro',
              name: 'Introduction',
              relativePath: 'dialogues/intro.yarn',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_scout',
              name: 'Mina',
              trainerClass: 'Scout',
              team: [
                ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
              ],
            ),
          ],
          cinematics: [
            CinematicAsset(
              id: 'cinematic_test',
              title: 'Cinematic Test',
              timeline: CinematicTimeline(),
            ),
          ],
        ),
      );

      expect(snapshot.dialogues.map((contract) => contract.id), [
        'dialogue_intro',
      ]);
      expect(snapshot.battles.map((contract) => contract.id), [
        'trainer:trainer_scout',
      ]);
      expect(snapshot.cinematics.map((contract) => contract.id), [
        'cinematic_test',
      ]);
      expect(snapshot.actionContractsAvailable, isFalse);
      expect(snapshot.branchByOutcomeAvailable, isFalse);
      expect(
        snapshot.outcomeProducers.map((producer) => producer.producerRef),
        contains('trainer:trainer_scout'),
      );
      expect(
        snapshot.diagnostics.map((diagnostic) => diagnostic.code),
        contains(LinkedAssetContractDiagnosticCode.unsupportedSource),
      );
    });

    test('builders are deterministic and do not mutate the manifest', () {
      final manifest = _manifest(
        dialogues: const [
          ProjectDialogueEntry(
            id: 'z_dialogue',
            name: 'Zeta',
            relativePath: 'dialogues/z.yarn',
          ),
          ProjectDialogueEntry(
            id: 'a_dialogue',
            name: 'Alpha',
            relativePath: 'dialogues/a.yarn',
          ),
        ],
      );
      final originalDialogues = manifest.dialogues;

      final first = buildDialoguePublicContracts(manifest);
      final second = buildDialoguePublicContracts(manifest);

      expect(first.map((contract) => contract.id), [
        'a_dialogue',
        'z_dialogue',
      ]);
      expect(second, first);
      expect(manifest.dialogues, originalDialogues);
    });
  });
}

ProjectManifest _manifest({
  List<ProjectDialogueEntry> dialogues = const [],
  List<ProjectTrainerEntry> trainers = const [],
  List<CinematicAsset> cinematics = const [],
  List<ScenarioAsset> scenarios = const [],
  List<SceneAsset> scenes = const [],
}) {
  return ProjectManifest(
    name: 'Linked Asset Contract Test Project',
    maps: const [],
    tilesets: const [],
    dialogues: dialogues,
    trainers: trainers,
    cinematics: cinematics,
    scenarios: scenarios,
    scenes: scenes,
  );
}

SceneAsset _staticBattleScene({
  required String id,
  required String trainerId,
  String? battleTemplateId,
}) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: '$id.start',
      nodes: [
        SceneNode(id: '$id.start', kind: SceneNodeKind.start),
        SceneNode(
          id: '$id.battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'static',
            trainerId: trainerId,
            battleTemplateId: battleTemplateId,
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
      ],
      edges: const [],
    ),
  );
}
