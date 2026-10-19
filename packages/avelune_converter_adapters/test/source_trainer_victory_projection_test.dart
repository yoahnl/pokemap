import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_trainer_fixture.dart';

Future<({SourceEventProjection projection, NormalizedSourceProject source,
    SourceEventAnalysis analysis, List<ProjectTrainerEntry> trainers})> _fixture({String mode = 'counter',
    bool badTarget = false, bool omittedTarget = false,
    bool deepTarget = false}) async {
  const rosters = [
    (type: 'FRLG_BUGCATCHER', name: 'Brent', version: 0),
    (type: 'FRLG_BUGCATCHER', name: 'Milo', version: 0),
  ];
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      variableNames: List.generate(34, (id) => 'Count $id'),
      extraFiles: {
        ...nativeTrainerFixtureFiles(rosters),
        'PBS/pokemon.txt': utf8.encode('[RATTATA]\nName = Rattata\n'),
        'Data/species.dat': literalFixtureMarshal({
          const LiteralFixtureSymbol('RATTATA'):
              const LiteralFixtureObject('GameData::Species', {
            '@id': LiteralFixtureSymbol('RATTATA'),
            '@species': LiteralFixtureSymbol('RATTATA'),
            '@form': 0,
            '@real_name': 'Rattata',
          }),
        }),
        'Graphics/Characters/OriginalTrainer.png':
            image.encodePng(image.Image(width: 128, height: 192)),
      },
      maps: [
        LiteralFixtureMap(id: 1, width: 6, height: 3, layers: [
          List.filled(18, 384), List.filled(18, 0), List.filled(18, 0)
        ], events: [
          for (final (index, roster) in rosters.indexed)
            LiteralFixtureEvent(id: index + 1, x: index + 1, y: 1,
                name: 'Trainer(0)', pages: [
              LiteralFixtureEventPage(characterName: 'OriginalTrainer', trigger: 2,
                  commands: [
                    ...nativeTrainerFixtureEvent(roster, index + 1).pages.first.commands.take(5),
                    if (mode == 'counter')
                      const LiteralFixtureEventCommand(122, [33, 33, 1, 0, 1], indent: 1),
                    if (mode == 'foreign') ...[
                      const LiteralFixtureEventCommand(101, ['The key fell!'], indent: 1),
                      const LiteralFixtureEventCommand(355, ['pbSetSelfSwitch(3,"A",true)'], indent: 1),
                    ],
                    ...nativeTrainerFixtureEvent(roster, index + 1).pages.first.commands.skip(5),
                  ]),
              nativeTrainerFixtureEvent(roster, index + 1).pages[1],
            ]),
          LiteralFixtureEvent(id: 3, x: 4, y: 1, name: 'Door state', pages: [
            LiteralFixtureEventPage(commands: [
              if (deepTarget)
                const LiteralFixtureEventCommand(355, ['pbSetSelfSwitch(4,"A",true)']),
              LiteralFixtureEventCommand(badTarget ? 355 : 101,
                  [badTarget ? 'unsupported()' : 'Closed']),
              const LiteralFixtureEventCommand(0, []),
            ]),
            LiteralFixtureEventPage(selfSwitch: mode == 'foreign' ? 'A' : null,
                variableId: mode == 'counter' ? 33 : null, variableThreshold: 2,
                commands: const [LiteralFixtureEventCommand(101, ['Open']),
                  LiteralFixtureEventCommand(0, [])]),
          ]),
          if (deepTarget)
            const LiteralFixtureEvent(id: 4, x: 5, y: 1, name: 'Unavailable dependency',
                pages: [LiteralFixtureEventPage(commands: [
                  LiteralFixtureEventCommand(355, ['unsupported()']),
                  LiteralFixtureEventCommand(0, []),
                ])]),
        ])
      ]);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot, files: fixture.files,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true);
  final analysis = SourceEventAnalyzer.forProject(source,
      profile: SourceEventProfile.forProject(source)).analyze();
  final bindings = await const SourceTrainerEventBindingResolver()
      .read(source: source, analysis: analysis, files: fixture.files);
  expect(bindings.byEventIdentity, hasLength(2), reason: '${bindings.refusals}');
  final charset = source.snapshot.entries.singleWhere((entry) =>
      entry.relativePath == 'Graphics/Characters/OriginalTrainer.png');
  final projection = const SourceEventProjector().project(source: source,
      analysis: omittedTarget ? SourceEventAnalysis(profile: analysis.profile,
          events: analysis.events.where((event) => event.sourceEventId != 3).toList(),
          diagnostics: analysis.diagnostics) : analysis,
      nativeMaps: {1: const MapData(id: 'native_1', name: 'Arena',
          size: GridSize(width: 6, height: 3), layers: [])},
      characterBindings: {
        sourceEventCharacterBindingKey(characterName: 'OriginalTrainer',
            pattern: 0, direction: 2): SourceEventCharacterBinding(
            characterId: 'native_trainer', sourceSnapshotHash: source.snapshot.canonicalHash,
            sourceFileId: charset.fileId, sourceFileHash: charset.sha256!,
            sourcePattern: 0, sourceDirection: 2),
      }, trainerBindings: bindings.byEventIdentity);
  return (projection: projection, source: source, analysis: analysis,
      trainers: bindings.byEventIdentity.values.map((binding) => binding.nativeTrainer).toList());
}

SceneAsset _scene(SourceEventProjection projection, int event, int page) {
  final identity = (projection.semanticEvidence['events'] as List).cast<Map>()
      .singleWhere((row) => (row['locator'] as Map)['eventId'] == event)['sourceIdentity'];
  return projection.scenes.singleWhere((scene) =>
      scene.metadata['sourceEventIdentity'] == identity &&
      scene.metadata['sourcePageIndex'] == '$page');
}

Future<({GameState state, List<String> steps})> _execute(
    SourceEventProjection projection, SceneAsset scene, String outcome,
    {GameState initial = const GameState(saveId: 'victory')}) async {
  var state = initial;
  final steps = <String>[];
  final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  final plan = buildSceneRuntimePlan(SceneAsset.fromJson(
      jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>));
  expect(plan.plan, isNotNull, reason: '${plan.diagnostics}');
  final execution = await SceneRuntimeExecutor(callbacks: SceneRuntimeExecutionCallbacks(
    evaluateCondition: (intent) {
      final source = intent.conditionSource!;
      final value = resolver.resolve(factId: source.sourceId,
          runtimeState: state.narrativeFactRuntimeState,
          storyFlags: state.storyFlags) as NarrativeFactRuntimeResolved;
      return value.narrativeValue.matches(source.resolvedFactOperator,
          source.resolvedExpectedFactValue) ? 'true' : 'false';
    },
    showDialogue: (intent) {
      final document = const YarnDialogueCompiler().compile(
          projection.dialogueSources[intent.dialogueId]!);
      steps.addAll(document.nodes.single.steps.whereType<RuntimeDialogueLine>()
          .map((line) => line.text));
      return 'completed';
    },
    startBattle: (_) {
      steps.add('battle:$outcome');
      if (outcome == 'cancel') throw StateError('Battle cancelled');
      return outcome;
    },
    applyConsequence: (consequence) {
      final write = switch (consequence) {
        SceneSetFactConsequence() => writer.setFactValue(gameState: state,
            factId: consequence.factId, value: consequence.narrativeValue),
        SceneAdjustIntegerFactConsequence() => writer.adjustIntegerFact(
            gameState: state, factId: consequence.factId, delta: consequence.delta,
            minimum: consequence.minimum, maximum: consequence.maximum),
        _ => throw StateError('Unexpected consequence ${consequence.kind}'),
      };
      steps.add(consequence is SceneAdjustIntegerFactConsequence
          ? 'increment' : 'selfA');
      expect(write.success, isTrue);
      state = write.gameState;
      return 'completed';
    },
    playCinematic: (_) => throw StateError('No cinematic'),
    executeInteractiveCommand: (_) => 'completed',
  )).execute(plan.plan!);
  expect(execution.status, outcome == 'cancel'
      ? SceneRuntimeExecutionStatus.failed : SceneRuntimeExecutionStatus.completed);
  return (state: GameState.fromJson(jsonDecode(jsonEncode(state.toJson()))
      as Map<String, dynamic>), steps: steps);
}

Object? _fact(SourceEventProjection projection, GameState state, String id) =>
    (NarrativeFactRuntimeResolver.fromFacts(projection.facts).resolve(factId: id,
        runtimeState: state.narrativeFactRuntimeState,
        storyFlags: state.storyFlags) as NarrativeFactRuntimeResolved).narrativeValue.toJson();

NarrativeEventDispatchAuthorityReady _authority(SourceEventProjection projection,
    List<ProjectTrainerEntry> trainers, int x) {
  final map = projection.nativeMaps[1]!;
  final entity = map.entities.singleWhere((entity) => entity.pos.x == x);
  final project = ProjectManifest(name: 'Trainer victories', tilesets: const [],
      maps: [ProjectMapEntry(id: map.id, name: map.name,
          relativePath: 'maps/native_1.json')], eventRegistry: projection.registry,
      facts: projection.facts, scenes: projection.scenes,
      dialogues: projection.dialogues, trainers: trainers);
  final authority = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(projection.registry),
      occurrence: NarrativeEventOccurrence(source:
          NarrativeEventSourceRef.entityInteract(map.id, entity.id)),
      factResolver: NarrativeFactRuntimeResolver.fromFacts(projection.facts),
      projectCatalog: buildNarrativeEventProjectCatalog(project: project, maps: [map]),
      project: project, maps: [map]);
  expect(authority, isA<NarrativeEventDispatchAuthorityReady>());
  return authority as NarrativeEventDispatchAuthorityReady;
}

String _dispatch(SourceEventProjection projection, List<ProjectTrainerEntry> trainers,
    GameState state, int x) {
  final decision = _authority(projection, trainers, x).plan(gameState: state);
  expect(decision, isA<NarrativeEventDispatchHandled>());
  return (decision as NarrativeEventDispatchHandled).sceneId;
}

void main() {
  for (final outcome in ['victory', 'defeat', 'cancel']) {
    test('trainer continuation changes state only on $outcome', () async {
      final fixture = await _fixture();
      final projection = fixture.projection;
      final event = fixture.analysis.eventAt(1, 1)!;
      final row = (projection.semanticEvidence['events'] as List)
          .cast<Map>().singleWhere((row) => row['sourceIdentity'] == event.identity.value);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final result = await _execute(projection, _scene(projection, 1, 0), outcome);
      expect(result.steps, outcome == 'victory'
          ? ['Ready?', 'battle:victory', 'Good game!', 'increment', 'selfA']
          : ['Ready?', 'battle:$outcome']);
      final analyzer = SourceEventAnalyzer.forProject(fixture.source,
          profile: fixture.analysis.profile);
      final count = sourceEventIntegerVariableBindingId(analyzer.variableFactId(33));
      expect(_fact(projection, result.state, count),
          NarrativeValue.integer(outcome == 'victory' ? 1 : 0).toJson());
      final own = sourceEventFactBindingId(analyzer.selfFactId(1, 1, 'A'));
      expect(_fact(projection, result.state, own),
          NarrativeValue.boolean(outcome == 'victory').toJson());
    });
  }

  test('two distinct victories persist counter without replaying a defeated trainer', () async {
    final fixture = await _fixture();
    final projection = fixture.projection;
    final first = await _execute(projection, _scene(projection, 1, 0), 'victory');
    expect(_dispatch(projection, fixture.trainers, first.state, 1),
        _scene(projection, 1, 1).id);
    final reloaded = await _execute(projection, _scene(projection, 1, 1), 'victory',
        initial: first.state);
    expect(reloaded.steps, ['See you!']);
    final second = await _execute(projection, _scene(projection, 2, 0), 'victory',
        initial: reloaded.state);
    final analyzer = SourceEventAnalyzer.forProject(fixture.source,
        profile: fixture.analysis.profile);
    final count = sourceEventIntegerVariableBindingId(analyzer.variableFactId(33));
    expect(_fact(projection, first.state, count), NarrativeValue.integer(1).toJson());
    expect(_fact(projection, reloaded.state, count), NarrativeValue.integer(1).toJson());
    expect(_fact(projection, second.state, count), NarrativeValue.integer(2).toJson());
    expect(_dispatch(projection, fixture.trainers, first.state, 4),
        _scene(projection, 3, 0).id);
    expect(_dispatch(projection, fixture.trainers, second.state, 4),
        _scene(projection, 3, 1).id);
  });

  test('cancelled event transaction discards provisional victory writes', () async {
    final fixture = await _fixture();
    const initial = GameState(saveId: 'victory');
    final transactions = NarrativeEventStateTransactions(initial);
    final coordinator = NarrativeEventExecutionCoordinator(
        activityPort: NoopNarrativeEventActivityPort(),
        stateTransactions: transactions,
        planner: NarrativeEventDispatchPlanner(),
        executionIdFactory: () => 'evx_019abcde-0000-7000-8000-000000000001',
        correlationIdFactory: () => 'corr_019abcde-0000-7000-8000-000000000002',
        deliveryIdFactory: () => 'outd_019abcde-0000-7000-8000-000000000003',
        executeScene: (request) async {
          final provisional = await _execute(fixture.projection,
              _scene(fixture.projection, 1, 0), 'victory', initial: request.gameState);
          expect(provisional.steps, contains('increment'));
          expect(provisional.state.toJson(), isNot(request.gameState.toJson()));
          return NarrativeSceneExecutionResult.cancelled('userCancelled');
        });
    final result = await coordinator.execute(authority:
        _authority(fixture.projection, fixture.trainers, 1));
    expect(result, isA<NarrativeEventExecutionCancelled>());
    expect((await transactions.read()).toJson(), initial.toJson());
  });

  for (final mode in ['qualified', 'unsupported', 'omitted', 'transitive']) {
    test('foreign victory effects require a completely qualified target $mode', () async {
      final fixture = await _fixture(mode: 'foreign', badTarget: mode == 'unsupported',
          omittedTarget: mode == 'omitted', deepTarget: mode == 'transitive');
      final event = fixture.analysis.eventAt(1, 1)!;
      final row = (fixture.projection.semanticEvidence['events'] as List)
          .cast<Map>().singleWhere((row) => row['sourceIdentity'] == event.identity.value);
      expect(row['status'], mode == 'qualified'
          ? 'adaptedStaticSemantics' : 'quarantinedWholeEvent', reason: '${row['gaps']}');
      if (mode == 'qualified') {
        final result = await _execute(fixture.projection,
            _scene(fixture.projection, 1, 0), 'victory');
        expect(result.steps, ['Ready?', 'battle:victory', 'Good game!',
          'The key fell!', 'selfA', 'selfA']);
      } else {
        expect(row['gaps'], contains('sourceSelfSwitchTargetUnavailable'));
      }
    });
  }
}
