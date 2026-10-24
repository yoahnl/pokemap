import 'package:avelune_converter_adapters/src/source_routed_door_program.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/source_invisible_door_fixture.dart';

Future<
        ({
          LiteralTileFixture fixture,
          SourceEventAnalysis analysis,
          SourceEventDefinition event,
          Map<ConverterId, SourceRoutedDoorProgram> programs
        })>
    _read(
        {String variant = 'animated',
        List<LiteralFixtureEventCommand> prefix = const [],
        List<LiteralFixtureEventCommand> suffix = const [],
        List<LiteralFixtureEventCommand> arrivalSuffix = const [],
        int? gateVariableId}) async {
  final fixture = await sourceInvisibleDoorFixture(
      variant: variant,
      departurePrefix: prefix,
      departureSuffix: suffix,
      arrivalSuffix: arrivalSuffix,
      gateVariableId: gateVariableId,
      variableNames: [
        null,
        for (var id = 1; id <= 9; id++) 'Declared integer $id'
      ]);
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
  return (
    fixture: fixture,
    analysis: analysis,
    event: analysis.eventAt(7, 3)!,
    programs:
        sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis)
  );
}

SourceEventDefinition _replacePage(SourceEventDefinition event, int pageIndex,
        List<SourceEventNode> nodes) =>
    SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: event.x,
        y: event.y,
        locator: event.locator,
        pages: [
          for (final (index, page) in event.pages.indexed)
            if (index != pageIndex)
              page
            else
              SourceEventPageAnalysis(
                  sourcePage: page.sourcePage,
                  locator: page.locator,
                  condition: page.condition,
                  graphic: page.graphic,
                  body: SourceEventBlock(span: page.body.span, nodes: nodes),
                  rawDataRef: page.rawDataRef,
                  diagnostics: page.diagnostics),
        ]);

Future<SourceEventProjection> _nativeProjection({
  List<LiteralFixtureEventCommand> prefix = const [],
  List<LiteralFixtureEventCommand> suffix = const [],
  List<LiteralFixtureEventCommand> arrivalSuffix = const [],
}) async {
  final fixture = await sourceInvisibleDoorFixture(
      includeSound: false,
      departurePrefix: prefix,
      departureSuffix: suffix,
      arrivalSuffix: arrivalSuffix,
      variableNames: [
        null,
        for (var id = 1; id <= 9; id++) 'Declared integer $id'
      ]);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: fixture.source.interpretationProfile,
      includeEventSystem: true,
      includeConnections: true);
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final programs = sourceRoutedDoorPrograms(source: source, analysis: analysis);
  expect(programs, hasLength(1));
  final maps = {
    for (final id in [7, 9])
      id: MapData(
          id: 'native_$id',
          name: 'Native $id',
          size: const GridSize(width: 3, height: 3),
          layers: []),
  };
  final base = NativeProjectDraft(
      source: source,
      projectName: 'Door envelope',
      parentPath: '/private/tmp',
      folderName: 'unused-door-envelope',
      mapIds: {
        for (final entry in maps.entries) entry.key: entry.value.id
      },
      artifacts: [],
      compositionEvidence: const {
        'sourceSemantics': {}
      },
      mutations: [
        for (final entry in maps.entries)
          NativeMutation(
              operationId: ConverterId('map_${entry.key}'),
              actionId: 'map.save',
              sourceEntityIds: [
                source.mapIdentity(entry.key)
              ],
              targetEntityIds: [
                ConverterId(entry.value.id)
              ],
              parameters: {
                'mapId': entry.value.id,
                'map': entry.value.toJson()
              })
      ]);
  final contexts = await const SourceEventExecutionContextResolver()
      .readRoutedTransfers(
          source: source,
          base: base,
          nativeMaps: maps,
          files: fixture.files,
          programs: programs,
          analysis: analysis);
  expect(contexts.values.single.refusals, isEmpty);
  return const SourceEventProjector().project(
      source: source,
      analysis: analysis,
      nativeMaps: maps,
      routedDoorPrograms: programs,
      routedDoorContexts: contexts,
      retentionPolicy: MapInstanceRetentionPolicy(
          viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1));
}

void main() {
  test(
      'native departure executes assignments before transfer and terminal wait after fade',
      () async {
    final projection = await _nativeProjection(prefix: const [
      LiteralFixtureEventCommand(122, [4, 4, 0, 0, 17]),
      LiteralFixtureEventCommand(122, [9, 9, 0, 0, -3]),
    ], suffix: const [
      LiteralFixtureEventCommand(106, [6])
    ]);
    expect(projection.scenes, hasLength(2),
        reason: '${projection.semanticEvidence}');
    final scene = projection.scenes
        .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '0');
    final visited = <String>[];
    var state = const GameState(saveId: 'door-envelope');
    final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
    final writer = NarrativeFactRuntimeWriter(resolver);
    final execution = await SceneRuntimeExecutor(
        callbacks: SceneRuntimeExecutionCallbacks(
            evaluateCondition: (_) => throw StateError('Unexpected condition'),
            applyConsequence: (consequence) {
              if (consequence is! SceneSetFactConsequence) {
                throw StateError('Unexpected effect');
              }
              final written = writer.setFactValue(
                  gameState: state,
                  factId: consequence.factId,
                  value: consequence.narrativeValue);
              expect(written.success, isTrue);
              state = written.gameState;
              visited.add('set:${consequence.narrativeValue.intValue}');
              return 'completed';
            },
            executeInteractiveCommand: (intent) {
              final command = intent.interactiveCommand!;
              visited.add(command.kind.name == 'wait'
                  ? 'wait:${command.toJson()['durationMs']}'
                  : command.kind.name);
              return 'completed';
            },
            showDialogue: (_) => throw StateError('Unexpected dialogue'),
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) =>
                throw StateError('Unexpected cinematic'))).execute(
        buildSceneRuntimePlan(scene).plan!);
    expect(execution.status, SceneRuntimeExecutionStatus.completed);
    expect(visited, [
      'set:17',
      'set:-3',
      'worldTone',
      'wait:400',
      'warp',
      'worldTone',
      'wait:300'
    ]);
  });

  test('a literal arrival suffix remains after the closing route', () async {
    final result = await _read(arrivalSuffix: const [
      LiteralFixtureEventCommand(122, [4, 4, 0, 0, 1], indent: 1),
    ]);
    expect(result.programs, hasLength(1));
    final branch =
        result.event.pages.last.body.nodes.first as SourceConditionalNode;
    expect(branch.whenTrue.nodes.last, isA<SourceVariableSetNode>());
  });

  test(
      'native arrival writes its literal only after routes and before the temporary latch',
      () async {
    final projection = await _nativeProjection(arrivalSuffix: const [
      LiteralFixtureEventCommand(122, [4, 4, 0, 0, 23], indent: 1),
    ]);
    expect(projection.scenes, hasLength(2),
        reason: '${projection.semanticEvidence}');
    final scene = projection.scenes
        .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '1');
    final visited = <String>[];
    var state = const GameState(saveId: 'arrival-envelope');
    final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
    final writer = NarrativeFactRuntimeWriter(resolver);
    final execution = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (_) => 'true',
                applyConsequence: (consequence) {
                  if (consequence is SceneSetFactConsequence) {
                    final written = writer.setFactValue(
                        gameState: state,
                        factId: consequence.factId,
                        value: consequence.narrativeValue);
                    expect(written.success, isTrue);
                    state = written.gameState;
                    visited.add('set:${consequence.narrativeValue.intValue}');
                  } else if (consequence
                      is SceneSetMapEventInstanceBooleanConsequence) {
                    visited.add('temp:${consequence.key}');
                  } else {
                    throw StateError('Unexpected effect');
                  }
                  return 'completed';
                },
                executeInteractiveCommand: (intent) {
                  visited.add(intent.interactiveCommand!.kind.name);
                  return 'completed';
                },
                showDialogue: (_) => throw StateError('Unexpected dialogue'),
                startBattle: (_) => throw StateError('Unexpected battle'),
                playCinematic: (_) => throw StateError('Unexpected cinematic')))
        .execute(buildSceneRuntimePlan(scene).plan!);
    expect(execution.status, SceneRuntimeExecutionStatus.completed);
    expect(visited, containsAll(['actorRoute', 'waitForActorRoutes']));
    expect(visited.indexOf('set:23'),
        greaterThan(visited.lastIndexOf('actorRoute')));
    expect(visited.indexOf('set:23'),
        greaterThan(visited.lastIndexOf('waitForActorRoutes')));
    expect(visited.last, 'temp:A');
    final fact = projection.facts
        .singleWhere((fact) => fact.description.endsWith('variable:4'));
    final resolved = resolver.resolve(
        factId: fact.id,
        runtimeState: state.narrativeFactRuntimeState,
        storyFlags: state.storyFlags) as NarrativeFactRuntimeResolved;
    expect(resolved.narrativeValue.intValue, 23);
  });

  test('arrival assignment guards and target bounds remain strict', () async {
    expect(
        (await _read(gateVariableId: 4, arrivalSuffix: const [
          LiteralFixtureEventCommand(122, [4, 4, 0, 0, 1], indent: 1),
        ]))
            .programs,
        isEmpty);
    expect(
        (await _read(arrivalSuffix: const [
          LiteralFixtureEventCommand(122, [4, 4, 0, 0, 1], indent: 1),
          LiteralFixtureEventCommand(122, [4, 4, 0, 0, 2], indent: 1),
        ]))
            .programs,
        isEmpty);
    expect(
        (await _read(arrivalSuffix: [
          for (var id = 2; id <= 6; id++)
            LiteralFixtureEventCommand(122, [id, id, 0, 0, 1], indent: 1),
        ]))
            .programs,
        isEmpty);
  });

  test('a forged arrival assignment cannot reuse its source program proof',
      () async {
    final result = await _read(arrivalSuffix: const [
      LiteralFixtureEventCommand(122, [4, 4, 0, 0, 1], indent: 1),
    ]);
    expect(result.programs, hasLength(1));
    final branch =
        result.event.pages.last.body.nodes.first as SourceConditionalNode;
    final original = branch.whenTrue.nodes.last as SourceVariableSetNode;
    final forged = _replacePage(result.event, 1, [
      SourceConditionalNode(branch.span,
          condition: branch.condition,
          whenTrue: SourceEventBlock(span: branch.whenTrue.span, nodes: [
            ...branch.whenTrue.nodes.take(branch.whenTrue.nodes.length - 1),
            SourceVariableSetNode(original.span,
                firstId: original.firstId,
                lastId: original.lastId,
                sourceValue: 2,
                factIds: original.factIds,
                preserveEqual: original.preserveEqual),
          ]),
          whenFalse: branch.whenFalse),
      ...result.event.pages.last.body.nodes.skip(1),
    ]);
    expect(
        result.programs.values.single.isBoundTo(
            source: result.fixture.source,
            analysis: result.analysis,
            event: forged),
        isFalse);
    expect(
        sourceRoutedDoorPrograms(
            source: result.fixture.source,
            analysis: SourceEventAnalysis(
                profile: result.analysis.profile,
                events: [forged],
                diagnostics: [])),
        isEmpty);
  });

  for (final suffix in <List<LiteralFixtureEventCommand>>[
    [
      const LiteralFixtureEventCommand(122, [4, 5, 0, 0, 1], indent: 1)
    ],
    [
      const LiteralFixtureEventCommand(122, [4, 4, 1, 0, 1], indent: 1)
    ],
    [
      const LiteralFixtureEventCommand(355, ['unknown_arrival()'], indent: 1)
    ],
  ]) {
    test('unsafe arrival suffix remains refused $suffix', () async {
      expect((await _read(arrivalSuffix: suffix)).programs, isEmpty);
    });
  }
  for (final variant in ['animated', 'original']) {
    for (final ticks in [0, 6, 1200]) {
      test(
          '$variant paired door preserves one bounded terminal wait of $ticks ticks',
          () async {
        final result = await _read(variant: variant, suffix: [
          LiteralFixtureEventCommand(106, [ticks])
        ]);
        expect(result.programs, hasLength(1));
        final terminal =
            result.event.pages.first.body.nodes.last as SourceWaitNode;
        expect(terminal.durationTicks, ticks);
        expect(
            result.programs.values.single.isBoundTo(
                source: result.fixture.source,
                analysis: result.analysis,
                event: result.event),
            isTrue);
      });
    }
  }

  test('literal assignments remain before the exact paired door body',
      () async {
    final result = await _read(prefix: const [
      LiteralFixtureEventCommand(122, [4, 4, 0, 0, 17]),
      LiteralFixtureEventCommand(122, [9, 9, 0, 0, -3]),
    ], suffix: const [
      LiteralFixtureEventCommand(106, [6])
    ]);
    expect(result.programs, hasLength(1));
    final nodes = result.event.pages.first.body.nodes;
    expect(
        nodes
            .take(2)
            .whereType<SourceVariableSetNode>()
            .map((node) => node.sourceValue),
        [17, -3]);
    expect(nodes.last, isA<SourceWaitNode>());
  });

  for (final entry in <String, List<LiteralFixtureEventCommand>>{
    'unknown prefix': [
      const LiteralFixtureEventCommand(355, ['original_custom_effect()'])
    ],
    'a range': [
      const LiteralFixtureEventCommand(122, [4, 5, 0, 0, 2])
    ],
    'variable operand': [
      const LiteralFixtureEventCommand(122, [4, 4, 0, 1, 9])
    ],
    'adjustment': [
      const LiteralFixtureEventCommand(122, [4, 4, 1, 0, 2])
    ],
    'random operand': [
      const LiteralFixtureEventCommand(122, [4, 4, 0, 2, 0, 2])
    ],
    'saturated literal': [
      const LiteralFixtureEventCommand(122, [4, 4, 0, 0, 100000000])
    ],
    'duplicate target': [
      const LiteralFixtureEventCommand(122, [4, 4, 0, 0, 2]),
      const LiteralFixtureEventCommand(122, [4, 4, 0, 0, 3])
    ],
    'more than four assignments': [
      for (var id = 2; id <= 6; id++)
        LiteralFixtureEventCommand(122, [id, id, 0, 0, 2])
    ],
  }.entries) {
    test('a paired door refuses ${entry.key}', () async {
      expect((await _read(prefix: entry.value)).programs, isEmpty);
    });
  }

  test('a prefix cannot change its own departure and arrival variable guards',
      () async {
    final result = await _read(gateVariableId: 4, prefix: const [
      LiteralFixtureEventCommand(122, [4, 4, 0, 0, 17])
    ]);
    expect(result.programs, isEmpty);
  });

  for (final suffix in <List<LiteralFixtureEventCommand>>[
    [
      const LiteralFixtureEventCommand(106, [1201])
    ],
    [
      const LiteralFixtureEventCommand(106, [6]),
      const LiteralFixtureEventCommand(106, [6])
    ],
    [
      const LiteralFixtureEventCommand(106, [6]),
      const LiteralFixtureEventCommand(355, ['unexpected_effect()'])
    ],
    [
      const LiteralFixtureEventCommand(122, [4, 4, 0, 0, 2])
    ],
  ]) {
    test(
        'an unqualified or displaced terminal envelope remains refused $suffix',
        () async {
      expect((await _read(suffix: suffix)).programs, isEmpty);
    });
  }

  test('a forged literal assignment cannot reuse the original bound proof',
      () async {
    final result = await _read(prefix: const [
      LiteralFixtureEventCommand(122, [4, 4, 0, 0, 17])
    ]);
    expect(result.programs, hasLength(1));
    final original =
        result.event.pages.first.body.nodes.first as SourceVariableSetNode;
    final forged = _replacePage(result.event, 0, [
      SourceVariableSetNode(original.span,
          firstId: original.firstId,
          lastId: original.lastId,
          sourceValue: 18,
          preserveEqual: original.preserveEqual,
          factIds: original.factIds),
      ...result.event.pages.first.body.nodes.skip(1),
    ]);
    expect(
        result.programs.values.single.isBoundTo(
            source: result.fixture.source,
            analysis: result.analysis,
            event: forged),
        isFalse);
    expect(
        sourceRoutedDoorPrograms(
            source: result.fixture.source,
            analysis: SourceEventAnalysis(
                profile: result.analysis.profile,
                events: [forged],
                diagnostics: [])),
        isEmpty);
  });

  test('a forged terminal wait cannot reuse the original bound proof',
      () async {
    final result = await _read(suffix: const [
      LiteralFixtureEventCommand(106, [6])
    ]);
    expect(result.programs, hasLength(1));
    final original = result.event.pages.first.body.nodes.last as SourceWaitNode;
    final forged = _replacePage(result.event, 0, [
      ...result.event.pages.first.body.nodes
          .take(result.event.pages.first.body.nodes.length - 1),
      SourceWaitNode(original.span,
          durationTicks: 7, profileHash: original.profileHash),
    ]);
    expect(
        result.programs.values.single.isBoundTo(
            source: result.fixture.source,
            analysis: result.analysis,
            event: forged),
        isFalse);
    expect(
        sourceRoutedDoorPrograms(
            source: result.fixture.source,
            analysis: SourceEventAnalysis(
                profile: result.analysis.profile,
                events: [forged],
                diagnostics: [])),
        isEmpty);
  });
}
