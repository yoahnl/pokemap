import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_field_obstacle_binding.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_cut_original_fixture.dart';

Map<int, MapData> cutNativeMaps(NormalizedSourceProject source) {
  final resolver = SourceSemanticResolver.forProject(source);
  return {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'native_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          layers: [
            MapLayer.collision(
                id: 'collision_${ir.map.sourceMapId}',
                name: 'Collision',
                collisions: List.generate(
                    ir.map.width * ir.map.height,
                    (i) =>
                        resolver
                            .resolveConnectionEntryTile(resolver.cellAt(
                                ir.map.sourceMapId,
                                i % ir.map.width,
                                i ~/ ir.map.width))
                            .status ==
                        SourcePassageStatus.blocked))
          ])
  };
}

Map cutEventEvidence(
        SourceEventProjection projection, SourceEventDefinition event) =>
    (projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) => row['sourceIdentity'] == event.identity.value);

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original Cut native objects', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceFieldObstacleBindings bindings;
    late Map<int, MapData> maps;
    SourceEventProjection project(
            {Map<int, MapData>? targets,
            SourceEventAnalysis? events,
            bool bind = true}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: events ?? analysis,
            nativeMaps: targets ?? maps,
            fieldObstacleBindings: bind ? bindings.byEventIdentity : const {});
    setUpAll(() async {
      source = await readOriginalCutSource(archive!);
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      analysis = full;
      expect(analysis.events.where((event) => event.pages
          .expand((page) => page.body.nodes)
          .any((node) => node is SourceFieldObstacleProgramNode)), hasLength(5));
      bindings = (await const SourceFieldObstacleBindingResolver().read(
          source: source,
          analysis: analysis,
          files: CutSourceFiles(source, root!)))!;
      maps = cutNativeMaps(source);
    });
    test('all five exact source anchors become typed blocking objects', () {
      final projected = project();
      for (final event in analysis.events.where((event) => bindings.byEventIdentity.containsKey(event.identity))) {
        final evidence = cutEventEvidence(projected, event);
        expect(evidence['status'], 'adaptedStaticSemantics',
            reason: '${evidence['gaps']}');
        final object = projected.nativeMaps[event.sourceMapId]!.entities
            .singleWhere((entity) =>
                entity.properties['sourceEventIdentity'] ==
                event.identity.value);
        expect(object.pos, GridPos(x: event.x, y: event.y));
        expect(object.kind, MapEntityKind.custom);
        expect(object.fieldObstacle?.kind, FieldObstacleKind.cutTree);
        expect(object.blocksMovement, isTrue);
        expect(object.npc, isNull);
        expect(object.editorVisual?.elementId, bindings.elements.single.id);
        expect(object.size, const GridSize(width: 1, height: 1));
      }
      expect(projected.nativeMaps.values.expand((map) => map.entities)
          .where((entity) => entity.fieldObstacle != null), hasLength(5));
      expect(projected.nativeMaps.keys, {98, 100});
      expect(projected.semanticEvidence['usedFieldObstacles'], true);
    });
    test('the character importer never receives Cut tree sprites', () {
      expect(
          const SourceEventProjector().characterImportCandidates(
              source: source,
              analysis: analysis,
              nativeMaps: maps,
              fieldObstacleBindings: bindings.byEventIdentity)
              .where((event) => bindings.byEventIdentity.containsKey(event.identity)),
          isEmpty);
    });
    test('missing gameplay binding quarantines the whole event', () {
      final projected = project(bind: false);
      for (final event in analysis.events.where((event) => bindings.byEventIdentity.containsKey(event.identity))) {
        expect(cutEventEvidence(projected, event)['gaps'],
            contains('sourceFieldObstacleBindingsMissing'));
      }
      expect(
          projected.nativeMaps.values.expand((map) => map.entities)
              .where((entity) => entity.fieldObstacle != null), isEmpty);
    });
    test('blocked underlying native floor cannot claim collision liberation',
        () {
      final event = analysis.events.firstWhere((event) => bindings.byEventIdentity.containsKey(event.identity));
      final map = maps[event.sourceMapId]!;
      final cells = List<bool>.filled(map.size.width * map.size.height, false);
      cells[event.y * map.size.width + event.x] = true;
      final projected = project(targets: {
        ...maps,
        event.sourceMapId: map.copyWith(layers: [
          MapLayer.collision(id: 'bad', name: 'Bad floor', collisions: cells)
        ])
      });
      expect(cutEventEvidence(projected, event)['gaps'],
          contains('sourceFieldObstacleNativeFloorBlocked'));
    });
    test('a wide native entity covering the anchor refuses the Cut object', () {
      final event = analysis.events.firstWhere((event) => bindings.byEventIdentity.containsKey(event.identity));
      final map = maps[event.sourceMapId]!;
      final projected = project(targets: {
        ...maps,
        event.sourceMapId: map.copyWith(entities: [
          MapEntity(
              id: 'wide',
              kind: MapEntityKind.custom,
              pos: GridPos(x: event.x - 1, y: event.y),
              size: const GridSize(width: 2, height: 1))
        ])
      });
      expect(cutEventEvidence(projected, event)['gaps'],
          contains('sourceFieldObstacleNativeFootprintOccupied'));
    });
    test('an existing native identity away from the tree cannot be overwritten',
        () {
      final event = analysis.events.firstWhere((event) => bindings.byEventIdentity.containsKey(event.identity));
      final original = project()
          .nativeMaps[event.sourceMapId]!
          .entities
          .singleWhere((entity) =>
              entity.properties['sourceEventIdentity'] == event.identity.value);
      final projected = project(targets: {
        ...maps,
        event.sourceMapId: maps[event.sourceMapId]!.copyWith(
            entities: [original.copyWith(pos: const GridPos(x: 0, y: 0))])
      });
      expect(cutEventEvidence(projected, event)['gaps'],
          contains('sourceFieldObstacleNativeIdentityOccupied'));
    });
    test('an altered analysis name cannot borrow the original raw programme',
        () {
      final event = analysis.events.firstWhere((event) => bindings.byEventIdentity.containsKey(event.identity));
      final changed = SourceEventDefinition(
          sourceMapId: event.sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId,
          identity: event.identity,
          name: 'Unattested tree',
          x: event.x,
          y: event.y,
          locator: event.locator,
          pages: event.pages);
      final projected = project(
          events: SourceEventAnalysis(
              profile: analysis.profile,
              events: [changed],
              diagnostics: const []));
      expect(cutEventEvidence(projected, changed)['gaps'],
          contains('sourceFieldObstacleSourceBindingInvalid'));
    });
    test('a spatial target keeps the source event quarantined', () {
      final event = analysis.events.firstWhere((event) => bindings.byEventIdentity.containsKey(event.identity));
      final projected = project(targets: {
        ...maps,
        event.sourceMapId:
            maps[event.sourceMapId]!.copyWith(version: ProjectVersion.v9)
      });
      expect(cutEventEvidence(projected, event)['gaps'],
          contains('sourceFieldObstacleSpatialUnsupported'));
    });
  },
      skip: archive == null || root == null
          ? 'Requires exact original source fixtures.'
          : false);
}
