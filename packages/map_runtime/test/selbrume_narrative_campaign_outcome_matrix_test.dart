import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_runtime/src/application/save_game_use_case.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/infrastructure/file_game_save_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('promoted Selbrume Validator dimensions fail closed on injected defects',
      () {
    final fixture = _loadSelbrume();
    final baseline = validateNarrativeProject(
      fixture.project,
      maps: fixture.mapsById.values.toList(growable: false),
    );

    expect(baseline.narrativelySolvable, NarrativeSymbolicVerdict.pass);
    expect(
      baseline.diagnostics.where(
        (diagnostic) =>
            diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
      ),
      isEmpty,
    );
    final symbolicStates = <NarrativeSymbolicState>[
      ...baseline.symbolicReachability!.exploredStates,
      ...baseline.symbolicReachability!.terminalStates,
    ];
    expect(
      symbolicStates.any(
        (state) =>
            state.factValues['fact_passage_dames_unlocked']?.toJson() == true,
      ),
      isTrue,
      reason:
          'The symbolic proof must expose the fact that removes both Passage des Dames gates.',
    );
    expect(
      symbolicStates.any(
        (state) => state.unlockedFieldAbilities.contains(FieldAbility.surf),
      ),
      isTrue,
      reason:
          'The symbolic proof must expose Surf before the physical causeway proof.',
    );
    final unlockedWorldState = GameState(
      saveId: 'physical-world-rule-proof',
      playerMovementMode: MovementMode.surf,
      progression: const PlayerProgression(
        unlockedFieldAbilities: <FieldAbility>[FieldAbility.surf],
      ),
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
        valuesByFactId: const <String, NarrativeValue>{
          'fact_passage_dames_unlocked': NarrativeValue.boolean(true),
        },
      ),
    );
    expect(
      projectWorldRuleEffects(
        fixture.project,
        unlockedWorldState,
        maps: fixture.mapsById.values.toList(growable: false),
      ).map((effect) => effect.ruleId),
      contains('world_rule_open_passage_to_phare'),
    );
    final passage = fixture.mapsById['map_passage_dames']!;
    final passageWorld = GameplayWorldState.initial(
      map: passage,
      playerPos: const GridPos(x: 30, y: 0),
      playerMovementMode: MovementMode.surf,
      project: fixture.project,
      mapEntityPresencePredicate: (mapId, entity) =>
          entity.id != 'gate_passage_to_phare',
    );
    expect(passageWorld.isBlocked(59, 12), isFalse);
    expect(
      _hasWalkablePath(
        passageWorld,
        start: const GridPos(x: 30, y: 0),
        goal: const GridPos(x: 59, y: 12),
        size: passage.size,
      ),
      isTrue,
      reason:
          'The unlocked Passage des Dames component must reach the lighthouse border.',
    );
    final lighthouseExterior = fixture.mapsById['map_phare_exterieur']!;
    final lighthouseWorld = GameplayWorldState.initial(
      map: lighthouseExterior,
      playerPos: const GridPos(x: 0, y: 12),
      project: fixture.project,
    );
    expect(
      lighthouseWorld.isBlocked(0, 12),
      isFalse,
      reason:
          'The authored landing cell for Passage des Dames must remain walkable.',
    );
    final unlockedSymbolicState = symbolicStates.firstWhere(
      (state) =>
          state.factValues['fact_passage_dames_unlocked']?.toJson() == true &&
          state.unlockedFieldAbilities.contains(FieldAbility.surf),
    );
    final isolatedPhysical = validateNarrativePhysicalReachability(
      project: fixture.project,
      maps: fixture.mapsById.values.toList(growable: false),
      narrativeReport: NarrativeSymbolicReachabilityReport(
        verdict: NarrativeSymbolicVerdict.pass,
        terminalStates: <NarrativeSymbolicState>[unlockedSymbolicState],
        exploredStates: <NarrativeSymbolicState>[unlockedSymbolicState],
        issues: const <NarrativeSymbolicIssue>[],
        reachableSceneIds: const <String>{},
        exploredStateCount: 1,
      ),
    );
    expect(
      isolatedPhysical.reachableMapIds,
      contains('map_phare_exterieur'),
      reason:
          'A symbolic state with the passage fact true must physically reach the lighthouse.',
    );
    final physical = validateNarrativePhysicalReachability(
      project: fixture.project,
      maps: fixture.mapsById.values.toList(growable: false),
      narrativeReport: baseline.symbolicReachability!,
    );
    expect(
      physical.verdict,
      NarrativePhysicalReachabilityVerdict.pass,
      reason: <String>[
        'reachableMaps=${physical.reachableMapIds.toList()..sort()}',
        'completedSteps=${baseline.symbolicReachability!.exploredStates.expand((state) => state.completedStepIds).toSet().toList()..sort()}',
        ...physical.issues.map(
          (issue) => '${issue.code.name}: ${issue.message}',
        ),
      ].join('\n'),
    );

    final missingScene = fixture.project.copyWith(
      scenes: fixture.project.scenes
          .where((scene) => scene.id != 'scene_final_pokemon')
          .toList(growable: false),
    );
    final missingSceneReport = validateNarrativeProject(
      missingScene,
      maps: fixture.mapsById.values.toList(growable: false),
    );
    expect(missingSceneReport.errorCount, greaterThan(0));
    expect(
      missingSceneReport.diagnostics.map((diagnostic) => diagnostic.code),
      contains('narrativeEventSceneMissing'),
    );

    final summit = fixture.mapsById['map_sommet_phare']!;
    final mapsWithoutBossTrigger = <String, MapData>{
      ...fixture.mapsById,
      summit.id: summit.copyWith(
        triggers: summit.triggers
            .where((trigger) => trigger.id != 'tr_sommet_confrontation')
            .toList(growable: false),
      ),
    };
    final missingTriggerReport = validateNarrativeProject(
      fixture.project,
      maps: mapsWithoutBossTrigger.values.toList(growable: false),
    );
    expect(missingTriggerReport.errorCount, greaterThan(0));
    final missingTriggerPhysical = validateNarrativePhysicalReachability(
      project: fixture.project,
      maps: mapsWithoutBossTrigger.values.toList(growable: false),
      narrativeReport: missingTriggerReport.symbolicReachability!,
    );
    expect(
      missingTriggerPhysical.verdict,
      isNot(NarrativePhysicalReachabilityVerdict.pass),
    );
    expect(
      missingTriggerPhysical.issues.map((issue) => issue.code),
      contains(NarrativePhysicalIssueCode.missingSourceTarget),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('real Lysa awaitable blocks save, then End persists across reload',
      () async {
    final fixture = _loadSelbrume();
    final directory =
        await Directory.systemTemp.createTemp('selbrume_lysa_checkpoint_');
    addTearDown(() => directory.delete(recursive: true));
    final gate = NarrativeRuntimeActivityGate();
    final repository = _TempFileGameSaveRepository(directory, gate: gate);
    final save = SaveGameUseCase(repository);
    var state = GameState(
      saveId: 'selbrume_lysa_checkpoint',
      currentMapId: 'map_port_brisants',
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const <String, bool>{
          'fact_port_alert_seen': true,
        },
      ),
    );

    expect(await save.execute(state), isTrue);
    final saveFile = File(await repository.exposedSaveFilePath());
    expect(await saveFile.exists(), isTrue);
    await saveFile.delete();

    final dialogueStarted = Completer<void>();
    final dialogueRelease = Completer<void>();
    final execution = gate.runWithActivity(
      NarrativeRuntimeActivity.sceneSuspended,
      () => executeNarrativeEventScene(
        request: NarrativeSceneExecutionRequest(
          eventId: 'evt_checkpoint_lysa',
          sceneId: 'scene_lysa_port',
          executionId: 'execution_checkpoint_lysa',
          gameState: state,
        ),
        project: fixture.project,
        mapsById: fixture.mapsById,
        currentGameState: () => state,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (intent) => _resolveCondition(
            fixture.project,
            state,
            intent,
          ),
          showDialogue: (_) async {
            dialogueStarted.complete();
            await dialogueRelease.future;
            return 'confident';
          },
          startBattle: (_) => 'victory',
          playCinematic: (_) => 'completed',
        ),
      ),
    );
    await dialogueStarted.future;

    expect(await save.execute(state), isFalse);
    expect(await saveFile.exists(), isFalse);

    dialogueRelease.complete();
    final result = await execution;
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    state = (result as NarrativeSceneExecutionCompleted).updatedGameState;
    expect(
      result.qualifiedOutcomes,
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.victory',
        ),
      ),
    );
    expect(gate.activity, NarrativeRuntimeActivity.idle);
    expect(await save.execute(state), isTrue);

    final reloaded = await repository.load();
    expect(reloaded, isNotNull);
    expect(
      saveDataFromGameState(reloaded!).toJson(),
      saveDataFromGameState(state).toJson(),
    );
    expect(
      reloaded.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_lysa_tone_confident', true),
    );
  });
}

bool _hasWalkablePath(
  GameplayWorldState world, {
  required GridPos start,
  required GridPos goal,
  required GridSize size,
}) {
  final queue = ListQueue<GridPos>()..add(start);
  final visited = <GridPos>{start};
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == goal) return true;
    for (final next in <GridPos>[
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x - 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x, y: current.y - 1),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= size.width ||
          next.y >= size.height ||
          world.isBlocked(next.x, next.y) ||
          !visited.add(next)) {
        continue;
      }
      queue.add(next);
    }
  }
  return false;
}

String _resolveCondition(
  ProjectManifest project,
  GameState state,
  SceneRuntimePlanIntent intent,
) {
  final source = intent.conditionSource;
  if (source == null) {
    throw StateError('The Selbrume checkpoint Scene condition is missing.');
  }
  if (source.sourceKind != SceneConditionSourceKind.fact) {
    throw UnsupportedError(
      'Condition ${source.sourceKind.name} is outside this checkpoint test.',
    );
  }
  return evaluateCanonicalNarrativeFactSceneCondition(
    source: source,
    gameState: state,
    resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
  )
      ? 'true'
      : 'false';
}

({ProjectManifest project, Map<String, MapData> mapsById}) _loadSelbrume() {
  final root = _findRepositoryRoot();
  final projectRoot = Directory(p.join(root.path, 'selbrume'));
  final project = ProjectManifest.fromJson(
    _readJson(File(p.join(projectRoot.path, 'project.json'))),
  );
  return (
    project: project,
    mapsById: <String, MapData>{
      for (final entry in project.maps)
        entry.id: MapData.fromJson(
          _readJson(File(p.join(projectRoot.path, entry.relativePath))),
        ),
    },
  );
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

final class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(
    this.testDirectory, {
    required NarrativeRuntimeActivityGate gate,
  }) : super(activityGate: gate);

  final Directory testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final directory = Directory(p.join(testDirectory.path, 'pokemonProject'));
    await directory.create(recursive: true);
    return p.join(directory.path, 'game_save.json');
  }
}
