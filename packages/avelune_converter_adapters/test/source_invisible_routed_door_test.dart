import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_invisible_door_fixture.dart';

Future<SourceEventProjection> _project({bool context = true}) async {
  final fixture = await sourceInvisibleDoorFixture(includeSound: false);
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
    expect(value.refusals, isEmpty);
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
