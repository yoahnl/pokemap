import 'dart:async';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import 'package:avelune_converter_adapters/src/source_town_map_binding.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'support/source_town_map_original_fixture.dart';

Map<int, MapData> _nativeMaps(NormalizedSourceProject source,
    {List<MapEntity> occupied = const [], bool blockAide = false}) {
  final resolver = SourceSemanticResolver.forProject(source);
  return {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'native_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          entities: ir.map.sourceMapId == 102 ? occupied : const [],
          layers: [
            MapLayer.collision(
                id: 'collision_${ir.map.sourceMapId}',
                name: 'Collision',
                collisions:
                    List.generate(ir.map.width * ir.map.height, (index) {
                  final x = index % ir.map.width, y = index ~/ ir.map.width;
                  final aide = ir.map.events
                      .where((event) => event.sourceEventId == 10)
                      .firstOrNull;
                  if (blockAide &&
                      ir.map.sourceMapId == 102 &&
                      aide?.x == x &&
                      aide?.y == y) {
                    return true;
                  }
                  return resolver
                          .resolveConnectionEntryTile(
                              resolver.cellAt(ir.map.sourceMapId, x, y))
                          .status ==
                      SourcePassageStatus.blocked;
                }))
          ])
  };
}

Map _eventEvidence(
        SourceEventProjection projection, SourceEventDefinition event) =>
    (projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) => row['sourceIdentity'] == event.identity.value);

MapEntity _anchor(
        SourceEventProjection projection, SourceEventDefinition event) =>
    projection.nativeMaps[event.sourceMapId]!.entities.singleWhere((entity) =>
        entity.properties['sourceEventIdentity'] == event.identity.value);

SceneAsset _scene(SourceEventProjection projection, SourceEventDefinition event,
        int pageIndex) =>
    projection.scenes.singleWhere((scene) =>
        scene.metadata['sourceEventIdentity'] == event.identity.value &&
        scene.metadata['sourcePageIndex'] == '$pageIndex');

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original Town Map native projection', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceEventDefinition event;
    late Map<int, MapData> maps;
    late SourceTownMapBinding binding;
    late SourceEventProjection projection;
    SourceEventProjection project(
            {SourceEventAnalysis? overrideAnalysis,
            Map<int, MapData>? overrideMaps,
            bool bind = true}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: overrideAnalysis ?? analysis,
            nativeMaps: overrideMaps ?? maps,
            townMapBinding: bind ? binding : null);
    setUpAll(() async {
      final fixture = await readOriginalTownMapSource(
          archivePath: archive!, sourceRoot: root!);
      source = fixture.$1;
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      event = full.eventAt(102, 6)!;
      analysis = SourceEventAnalysis(
          profile: full.profile, events: [event], diagnostics: const []);
      maps = _nativeMaps(source);
      binding = await const SourceTownMapBindingResolver().read(
          source: source,
          files: fixture.$2,
          nativeMapIds: {
            for (final entry in maps.entries) entry.key: entry.value.id
          });
      projection = project();
    });
    test(
        'original wall map exposes exact two-cell native action and awaitable service',
        () {
      final evidence = _eventEvidence(projection, event);
      expect(evidence['status'], 'adaptedStaticSemantics',
          reason: '${evidence['gaps']}');
      final entity = _anchor(projection, event);
      expect(entity.pos, const GridPos(x: 14, y: 3));
      expect(entity.size, const GridSize(width: 2, height: 1));
      expect(entity.kind, MapEntityKind.custom);
      expect(entity.blocksMovement, false);
      expect(entity.npc, isNull);
      final scene = _scene(projection, event, 0);
      final actions = scene.graph.nodes
          .map((n) => n.payload)
          .whereType<SceneActionPayload>()
          .toList();
      expect(actions, hasLength(1));
      expect(actions.single.interactiveCommand!.kind.name, 'openRegionalMap');
      expect(projection.scenes, hasLength(1));
      expect(projection.facts, isEmpty);
      expect(projection.itemCatalog, isNull);
      expect(projection.semanticEvidence['usedTownMap'], true);
    });
    test('both source cells receive real native front action', () {
      final map = projection.nativeMaps[102]!;
      final entity = _anchor(projection, event);
      for (final x in [14, 15]) {
        final result = stepGameplayWorld(
            GameplayWorldState.initial(
                map: map,
                playerPos: GridPos(x: x, y: 4),
                playerFacing: Direction.north),
            const InteractIntent());
        expect(result, isA<EntityInteracted>());
        expect((result as EntityInteracted).entity.id, entity.id);
      }
    });
    for (final outcome in ['completed', 'cancelled', 'unknown']) {
      test('native region screen outcome $outcome never writes source state',
          () async {
        final trace = <String>[];
        final result = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (_) => throw StateError('No condition'),
                showDialogue: (intent) {
                  trace.add('text');
                  expect(projection.dialogueSources[intent.dialogueId],
                      contains('A Town Map.'));
                  return 'completed';
                },
                startBattle: (_) => throw StateError('No battle'),
                playCinematic: (_) => throw StateError('No cinematic'),
                applyConsequence: (_) => throw StateError('No mutation'),
                executeInteractiveCommand: (intent) {
                  expect(
                      intent.interactiveCommand!.kind.name, 'openRegionalMap');
                  trace.add('region');
                  return outcome;
                })).execute(
            buildSceneRuntimePlan(_scene(projection, event, 0)).plan!);
        expect(trace, ['text', 'region']);
        expect(
            result.status,
            outcome == 'unknown'
                ? SceneRuntimeExecutionStatus.failed
                : SceneRuntimeExecutionStatus.completed);
      });
    }
    test('converted scene waits for the native screen to close', () async {
      final entered = Completer<void>();
      final close = Completer<String>();
      var completed = false;
      final execution = SceneRuntimeExecutor(
              callbacks: SceneRuntimeExecutionCallbacks(
                  evaluateCondition: (_) => throw StateError('No condition'),
                  showDialogue: (_) => 'completed',
                  startBattle: (_) => throw StateError('No battle'),
                  playCinematic: (_) => throw StateError('No cinematic'),
                  applyConsequence: (_) => throw StateError('No mutation'),
                  executeInteractiveCommand: (intent) {
                    expect(intent.interactiveCommand!.kind.name,
                        'openRegionalMap');
                    entered.complete();
                    return close.future;
                  }))
          .execute(buildSceneRuntimePlan(_scene(projection, event, 0)).plan!)
          .then((result) {
        completed = true;
        return result;
      });
      await entered.future.timeout(const Duration(seconds: 3));
      expect(completed, false);
      close.complete('completed');
      expect((await execution).status, SceneRuntimeExecutionStatus.completed);
    });

    test('missing regional binding leaves no active scene or map decoration',
        () {
      final result = project(bind: false);
      expect(_eventEvidence(result, event)['status'], 'quarantinedWholeEvent');
      expect(result.scenes, isEmpty);
      expect(result.nativeMaps[102]!.entities, isEmpty);
      expect(result.semanticEvidence['usedTownMap'], false);
    });
    test('native collision must prove both source footprint cells', () {
      final map = maps[102]!;
      for (final x in [14, 15]) {
        final changed = map.copyWith(layers: [
          MapLayer.collision(
              id: 'collision',
              name: 'Collision',
              collisions: List.generate(
                  map.size.width * map.size.height,
                  (index) => index == 3 * map.size.width + x
                      ? false
                      : (map.layers.single as CollisionLayer)
                          .collisions[index]))
        ]);
        final result = project(overrideMaps: {...maps, 102: changed});
        expect(
            _eventEvidence(result, event)['status'], 'quarantinedWholeEvent');
        expect(result.scenes, isEmpty);
      }
    });
    test('occupied native footprint and forged source position cannot qualify',
        () {
      final map = maps[102]!;
      final occupied = map.copyWith(entities: [
        MapEntity(
            id: 'occupied',
            kind: MapEntityKind.custom,
            pos: const GridPos(x: 13, y: 3),
            size: const GridSize(width: 2, height: 1),
            blocksMovement: true)
      ]);
      expect(
          _eventEvidence(
              project(overrideMaps: {...maps, 102: occupied}), event)['status'],
          'quarantinedWholeEvent');
      final moved = SourceEventDefinition(
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId,
          identity: event.identity,
          name: event.name,
          x: 13,
          y: 3,
          locator: event.locator,
          pages: event.pages);
      final result = project(
          overrideAnalysis: SourceEventAnalysis(
              profile: analysis.profile,
              events: [moved],
              diagnostics: const []));
      expect(_eventEvidence(result, event)['status'], 'quarantinedWholeEvent');
      expect(result.scenes, isEmpty);
    });
    test(
        'empty body and missing raw attestation cannot fall back to plain dialogue',
        () {
      final page = event.pages.single;
      for (final missingRaw in [false, true]) {
        final replacement = SourceEventDefinition(
            sourceMapId: event.sourceMapId,
            sourceEventId: event.sourceEventId,
            sourceFileId: event.sourceFileId,
            identity: event.identity,
            name: event.name,
            x: event.x,
            y: event.y,
            locator: event.locator,
            pages: [
              SourceEventPageAnalysis(
                  sourcePage: page.sourcePage,
                  locator: page.locator,
                  condition: page.condition,
                  graphic: page.graphic,
                  body: missingRaw
                      ? page.body
                      : SourceEventBlock(nodes: const [], span: page.body.span),
                  rawDataRef: missingRaw ? null : page.rawDataRef,
                  diagnostics: const [])
            ]);
        final result = project(
            overrideAnalysis: SourceEventAnalysis(
                profile: analysis.profile,
                events: [replacement],
                diagnostics: const []));
        expect(
            _eventEvidence(result, event)['status'], 'quarantinedWholeEvent');
        expect(result.scenes, isEmpty);
      }
    });
  },
      skip: archive == null || root == null
          ? 'Original source and archive required.'
          : false);
}
