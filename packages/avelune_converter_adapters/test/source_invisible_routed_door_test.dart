import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_invisible_door_fixture.dart';

bool _matches(NarrativeEventConditionExpression expression, int value,
        bool temporary) =>
    switch (expression) {
      NarrativeEventConditionLeaf(:final condition) => condition.whenTyped(
          fact: (_, operation, expected) =>
              NarrativeValue.integer(value).matches(operation, expected),
          narrativeEventConsumed: (_, __) =>
              throw StateError('Unexpected consumed condition'),
          mapEventInstanceBoolean: (_, __, ___, expected) =>
              temporary == expected),
      NarrativeEventConditionAll(:final children) =>
        children.every((child) => _matches(child, value, temporary)),
      NarrativeEventConditionAny(:final children) =>
        children.any((child) => _matches(child, value, temporary)),
      NarrativeEventConditionNot(:final child) =>
        !_matches(child, value, temporary),
    };

Set<String> _reachable(SceneAsset scene, String start, String port) {
  final pending = scene.graph.edges
      .where((edge) => edge.fromNodeId == start && edge.fromPortId == port)
      .map((edge) => edge.toNodeId)
      .toList();
  final seen = <String>{};
  while (pending.isNotEmpty) {
    final node = pending.removeLast();
    if (seen.add(node)) {
      pending.addAll(scene.graph.edges
          .where((edge) => edge.fromNodeId == node)
          .map((edge) => edge.toNodeId));
    }
  }
  return seen;
}

Future<SourceEventProjection> _project(
    {bool context = true,
    int arrivalStep = 1,
    bool annotated = false,
    bool shortArrival = false,
    bool lockedPage = false,
    int? gateVariableId,
    bool trailingSwitch = false,
    bool untrustedGrass = false}) async {
  final fixture = await sourceInvisibleDoorFixture(
      includeSound: false,
      arrivalStep: arrivalStep,
      annotated: annotated,
      shortArrival: shortArrival,
      lockedPage: lockedPage,
      gateVariableId: gateVariableId,
      trailingSwitch: trailingSwitch);
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
  final maps = {
    for (final id in [7, 9])
      id: MapData(
          id: 'map_$id',
          name: 'Map $id',
          size: const GridSize(width: 3, height: 3),
          layers: []),
  };
  final base = NativeProjectDraft(
    source: source,
    projectName: 'Invisible door',
    parentPath: '/private/tmp',
    folderName: 'unused-invisible-door',
    mapIds: {for (final entry in maps.entries) entry.key: entry.value.id},
    artifacts: [],
    compositionEvidence: const {'sourceSemantics': {}},
    mutations: [
      if (untrustedGrass)
        NativeMutation(
            operationId: ConverterId('untrusted-grass'),
            actionId: 'smart_tile.animation.upsert',
            sourceEntityIds: [],
            targetEntityIds: [],
            parameters: {
              'animation': {'id': 'untrusted'}
            }),
      for (final entry in maps.entries)
        NativeMutation(
            operationId: ConverterId('map_${entry.key}'),
            actionId: 'map.save',
            sourceEntityIds: [source.mapIdentity(entry.key)],
            targetEntityIds: [ConverterId(entry.value.id)],
            parameters: {'mapId': entry.value.id, 'map': entry.value.toJson()}),
    ],
  );
  final contexts = context
      ? await const SourceEventExecutionContextResolver().readRoutedTransfers(
          source: source,
          base: base,
          nativeMaps: maps,
          files: fixture.files,
          programs: programs,
          analysis: analysis)
      : <ConverterId, SourceEventExecutionContext>{};
  for (final value in contexts.values) {
    expect(value.refusals,
        untrustedGrass ? contains('sourceExecutionBaseUnsupported') : isEmpty);
  }
  return const SourceEventProjector().project(
    source: source,
    analysis: analysis,
    nativeMaps: maps,
    routedDoorPrograms: programs,
    routedDoorContexts: contexts,
    retentionPolicy: MapInstanceRetentionPolicy(
        viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1),
  );
}

void main() {
  test('unattested smart tile actions cannot authorize a door context',
      () async {
    final projection = await _project(untrustedGrass: true);
    expect(projection.scenes, isEmpty);
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['gaps'], contains('sourceExecutionBaseUnsupported'));
  });
  for (final direction in [1, 4]) {
    for (final shortArrival in [false, true]) {
      test(
          'automatic door projection preserves arrival step $direction, short=$shortArrival',
          () async {
        final projection = await _project(
            arrivalStep: direction,
            annotated: true,
            shortArrival: shortArrival);
        final row =
            (projection.semanticEvidence['events'] as List).single as Map;
        expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
        final routes = projection.scenes
            .expand((scene) => scene.graph.nodes)
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.interactiveCommand)
            .whereType<SceneInteractiveCommand>()
            .map((command) => command.toJson())
            .where((command) => command['kind'] == 'actorRoute')
            .toList();
        expect(routes, hasLength(1));
        expect((routes.single['steps'] as List).single,
            containsPair('direction', direction == 1 ? 'south' : 'north'));
        expect(projection.allEnabledOriginalEventsHaveExecutionContext, isTrue);
      });
    }
  }

  test('annotated variable gate retains locked page and exact threshold',
      () async {
    final projection = await _project(
        annotated: true,
        shortArrival: true,
        lockedPage: true,
        gateVariableId: 1);
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
    expect(projection.scenes, hasLength(3));
    final guards = projection.registry.records
        .expand((record) => record.definitionOrNull!.conditions)
        .map((condition) => condition.toJson())
        .where((condition) => condition['kind'] == 'fact')
        .toList();
    expect(guards, isNotEmpty);
    for (final guard in guards) {
      expect(guard['valueType'], 'int');
      expect(guard['operator'], 'greaterThanOrEqual');
      expect(guard['expectedValue'], 7);
    }
    for (final value in [0, 6, 7, 8]) {
      for (final temporary in [false, true]) {
        final selected = projection.registry.records
            .map((record) => record.definitionOrNull!)
            .where((definition) =>
                _matches(definition.conditionExpression, value, temporary));
        expect(
            selected.single.priority,
            value < 7
                ? 0
                : temporary
                    ? 1
                    : 2);
      }
    }
    expect(projection.allEnabledOriginalEventsHaveExecutionContext, isTrue);
  });

  test('a departure switch remains a native consequence after the transfer',
      () async {
    final projection = await _project(shortArrival: true, trailingSwitch: true);
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
    final departure = projection.scenes
        .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '0');
    final consequences = departure.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.consequence)
        .whereType<SceneSetFactConsequence>()
        .toList();
    expect(consequences, hasLength(1));
    expect(consequences.single.value, isTrue);
    final switchNode = departure.graph.nodes.singleWhere((node) =>
        node.payload is SceneActionPayload &&
        (node.payload as SceneActionPayload).consequence ==
            consequences.single);
    final warpNode = departure.graph.nodes.singleWhere((node) =>
        node.payload is SceneActionPayload &&
        (node.payload as SceneActionPayload).interactiveCommand?.kind ==
            SceneInteractiveCommandKind.warp);
    expect(_reachable(departure, warpNode.id, 'completed'),
        contains(switchNode.id));
    expect(_reachable(departure, warpNode.id, 'blocked'),
        isNot(contains(switchNode.id)));
  });

  test('animated doors cannot acquire an unqualified trailing consequence',
      () async {
    for (final trailingSwitch in [false, true]) {
      final fixture = await sourceInvisibleDoorFixture(
          variant: 'animated', trailingSwitch: trailingSwitch);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      final programs =
          sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis);
      expect(programs.length, trailingSwitch ? 0 : 1);
    }
  });

  for (final direction in [2, 3, 5]) {
    test('unqualified arrival step $direction remains refused', () async {
      final fixture = await sourceInvisibleDoorFixture(
          arrivalStep: direction, shortArrival: true);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      expect(
          sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis),
          isEmpty);
    });
  }

  test('mismatched variable guards cannot qualify a paired door', () async {
    final fixture = await sourceInvisibleDoorFixture(
        shortArrival: true,
        lockedPage: true,
        gateVariableId: 1,
        mismatchedArrivalThreshold: true);
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    expect(sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis),
        isEmpty);
  });

  test('source invisible door with literal arrival rotations is recognized',
      () async {
    final fixture = await sourceInvisibleDoorFixture();
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    final event = analysis.eventAt(7, 3)!;
    expect(event.isQuarantined, isFalse);
    final programs =
        sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis);
    expect(programs, hasLength(1));
    final program = programs.values.single;
    expect(
        program.isBoundTo(
            source: fixture.source, analysis: analysis, event: event),
        isTrue);
    expect(program.toJson()['presentationAdaptation'], {
      'kind': 'nativeInvisibleDoorOwnerRoutePauses',
      'explicitWaitsPreserved': true,
      'invisibleTurnsYieldPreserved': false,
    });
    expect(program.toJson()['sourceProgramPlaybackQualified'], isFalse);
  });

  for (final variant in [
    'route',
    'barrier',
    'charset',
    'guards',
    'repeat',
    'actor',
    'skippable',
    'emptyAnimated'
  ]) {
    test('invisible door refuses changed $variant', () async {
      final fixture = await sourceInvisibleDoorFixture(variant: variant);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      expect(analysis.eventAt(7, 3)!.isQuarantined, isFalse);
      expect(
          sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis),
          isEmpty);
    });
  }

  test(
      'invisible owner rotations become explicit pauses and retain player movement',
      () async {
    final projection = await _project();
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
    expect(projection.scenes, hasLength(2));
    final commands = projection.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((action) => action.interactiveCommand)
        .whereType<SceneInteractiveCommand>()
        .map((command) => command.toJson())
        .toList();
    final routes =
        commands.where((command) => command['kind'] == 'actorRoute').toList();
    expect(routes, hasLength(1));
    expect((routes.single['target'] as Map)['kind'], 'player');
    expect((routes.single['steps'] as List).single,
        isNot(contains('initialCollisionOwnerEntityId')));
    expect(
        (routes.single['steps'] as List).single, containsPair('kind', 'move'));
    expect(commands.where((command) => command['kind'] == 'waitForActorRoutes'),
        hasLength(3));
    expect(commands.where((command) => command['kind'] == 'actorVisibility'),
        hasLength(2));
    expect(
        commands
            .where((command) => command['kind'] == 'wait')
            .map((command) => command['durationMs']),
        unorderedEquals([400, 400, 300]));
    expect(canonicalJsonOf(projection.semanticEvidence),
        contains('nativeInvisibleDoorOwnerRoutePauses'));
    expect(projection.allEnabledOriginalEventsHaveExecutionContext, isTrue);
    final project = ProjectManifest(
        name: 'Invisible door validation',
        maps: [
          for (final map in projection.nativeMaps.values)
            ProjectMapEntry(
                id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ],
        tilesets: const [],
        scenes: projection.scenes,
        facts: projection.facts,
        eventRegistry: projection.registry);
    for (final scene in projection.scenes) {
      final diagnostics = diagnoseSceneAgainstProject(scene, project,
          mapsById: {
            for (final map in projection.nativeMaps.values) map.id: map
          });
      expect(
          diagnostics.diagnostics.where((diagnostic) =>
              diagnostic.code.name == 'commandInvalidActorTarget'),
          isEmpty);
      expect(diagnostics.hasErrors, isFalse,
          reason: diagnostics.diagnostics.toString());
    }
  });

  test('invisible owner timing adaptation requires its exact execution context',
      () async {
    final projection = await _project(context: false);
    expect(projection.scenes, isEmpty);
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'quarantinedWholeEvent');
  });
}
