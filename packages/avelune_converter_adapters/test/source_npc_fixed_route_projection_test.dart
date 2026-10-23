import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_trainer_event_bindings.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/fixed_route_source_fixture.dart';

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original five native autonomous NPC routes', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceTrainerEventBindings trainers;
    late Map<int, MapData> maps;
    late SourceEventProjection projection;
    SourceEventProjection project(
            {SourceEventAnalysis? overrideAnalysis,
            Map<int, MapData>? overrideMaps}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: overrideAnalysis ?? analysis,
            nativeMaps: overrideMaps ?? maps,
            characterBindings: fixedRouteCharacters(source, analysis),
            trainerBindings: trainers.byEventIdentity);

    setUpAll(() async {
      final input = await readFixedRouteSource(archive!, root!);
      source = input.$1;
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      analysis = SourceEventAnalysis(
          profile: full.profile,
          events: full.events
              .where((event) =>
                  (event.sourceMapId == 98 &&
                      [6, 8, 11].contains(event.sourceEventId)) ||
                  (event.sourceMapId == 102 &&
                      [11, 15].contains(event.sourceEventId)))
              .toList(),
          diagnostics: const []);
      trainers = await const SourceTrainerEventBindingResolver()
          .read(source: source, analysis: analysis, files: input.$2);
      maps = fixedRouteNativeMaps(source);
      projection = project();
    });

    for (final identity in [(98, 6), (98, 8), (98, 11), (102, 11), (102, 15)]) {
      test(
          'admits original ${identity.$1}:${identity.$2} without erasing its route',
          () {
        final event = analysis.eventAt(identity.$1, identity.$2)!;
        final evidence = (projection.semanticEvidence['events'] as List)
            .cast<Map>()
            .singleWhere(
                (row) => row['sourceIdentity'] == event.identity.value);
        expect(evidence['status'], 'adaptedStaticSemantics',
            reason: '${evidence['gaps']}');
        final entity = projection.nativeMaps[event.sourceMapId]!.entities
            .singleWhere((entity) =>
                entity.properties['sourceEventIdentity'] ==
                event.identity.value);
        final movement = entity.npc!.movement;
        expect(movement.mode, MapEntityNpcMovementMode.fixedRoute);
        expect(movement.routeSteps, isNotEmpty);
        expect(movement.waypoints, isEmpty);
        expect(movement.stepDurationMs, 250);
        expect(movement.pauseDurationMs, identity == (102, 11) ? 2550 : 1600);
        expect(movement.suspendWhenInstanceBoolean?.key,
            identity.$1 == 98 ? 'npc.autonomousRouteStopped' : null);
        final native = evidence['nativeFixedRoute'] as Map;
        expect(native['sourceParity'], false);
        expect(native['sourceProgramQualified'], true);
        expect(native['sourceScriptsExecuted'], 0);
        expect(native['pages'], hasLength(event.pages.length));
        final policies = (native['movementPolicies'] as List).cast<Map>();
        expect(policies, hasLength(event.pages.length));
        for (final page in event.pages) {
          final policy = policies.singleWhere((value) => value['sourcePageIndex'] == page.originalPageIndex);
          final variant = entity.presentation!.variants.singleWhere((value) => value.id == 'page_${page.originalPageIndex}');
          expect(policy['movement'], variant.movement.toJson());
        }
        if (identity.$1 == 98) {
          expect(entity.npc!.trainerId,
              trainers.byEventIdentity[event.identity]!.nativeTrainer.id);
          expect(native['sourceDefeatedPageLineOfSightAfterNewInstanceParity'],
              false);
          final before = projection.scenes.singleWhere((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value &&
              scene.metadata['sourcePageIndex'] == '0');
          final battle = before.graph.nodes
              .singleWhere((node) => node.payload is SceneBattlePayload);
          final victory = _reachable(before, battle.id, 'victory');
          final defeat = _reachable(before, battle.id, 'defeat');
          expect(_routeStops(victory), hasLength(1));
          expect(_routeStops(defeat), isEmpty);
          final stop = _routeStops(victory).single;
          expect(stop.mapId, projection.nativeMaps[event.sourceMapId]!.id);
          expect(stop.eventId, entity.id);
          expect(stop.value, true);
          final after = projection.scenes.singleWhere((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value &&
              scene.metadata['sourcePageIndex'] == '1');
          expect(
              after.graph.nodes
                  .where((node) => node.payload is SceneBattlePayload),
              isEmpty);
          expect(_routeStops(after.graph.nodes), isEmpty);
          expect(
              after.graph.nodes
                  .where((node) => node.payload is SceneYarnDialoguePayload),
              isNotEmpty);
        }
      });
    }

    test('all five remain eligible for real character import', () {
      expect(
          const SourceEventProjector().characterImportCandidates(
              source: source,
              analysis: analysis,
              nativeMaps: maps,
              trainerBindings: trainers.byEventIdentity),
          hasLength(5));
    });

    test('source counter remains reachable at every declared route position',
        () {
      final event = analysis.eventAt(102, 15)!;
      final map = projection.nativeMaps[102]!;
      final entity = map.entities.singleWhere((entity) =>
          entity.properties['sourceEventIdentity'] == event.identity.value);
      expect(entity.npc!.counterInteractionSides, contains(EntityFacing.north));
      final resolver = SourceSemanticResolver.forProject(source);
      for (final x in [10, 11, 12]) {
        final counter =
            resolver.resolveCell(resolver.cellAt(102, x, 5)).counter;
        final relocated = map.copyWith(entities: [
          for (final candidate in map.entities)
            candidate.id == entity.id
                ? candidate.copyWith(pos: GridPos(x: x, y: 6))
                : candidate
        ]);
        final result = stepGameplayWorld(
            GameplayWorldState.initial(
                map: relocated,
                playerPos: GridPos(x: x, y: 4),
                playerFacing: Direction.south),
            const InteractIntent());
        if (counter) {
          expect(result, isA<NpcInteracted>());
          expect((result as NpcInteracted).entity.id, entity.id);
        } else {
          expect(result, isA<NothingToInteract>());
        }
      }
    });

    test(
        'declared counter side never enables interaction through an ordinary wall',
        () {
      final event = analysis.eventAt(102, 15)!;
      final base = projection.nativeMaps[102]!;
      final entity = base.entities.singleWhere((entity) =>
          entity.properties['sourceEventIdentity'] == event.identity.value);
      expect(entity.npc!.counterInteractionSides,
          isNot(contains(EntityFacing.west)));
      final wall = base.copyWith(layers: [
        for (final layer in base.layers)
          if (layer is CollisionLayer)
            layer.copyWith(collisions: [
              for (var index = 0; index < layer.collisions.length; index++)
                index == 6 * base.size.width + 10
                    ? true
                    : layer.collisions[index]
            ])
          else
            layer
      ]);
      final result = stepGameplayWorld(
          GameplayWorldState.initial(
              map: wall,
              playerPos: const GridPos(x: 9, y: 6),
              playerFacing: Direction.east),
          const InteractIntent());
      expect(result, isA<NothingToInteract>());
    });

    test('changing source counter collision refuses the entire moving NPC', () {
      final event = analysis.eventAt(102, 15)!;
      final resolver = SourceSemanticResolver.forProject(source);
      final x = [10, 11, 12].firstWhere(
          (x) => resolver.resolveCell(resolver.cellAt(102, x, 5)).counter);
      final base = maps[102]!;
      final changed = base.copyWith(layers: [
        for (final layer in base.layers)
          if (layer is CollisionLayer)
            layer.copyWith(collisions: [
              for (var index = 0; index < layer.collisions.length; index++)
                index == 5 * base.size.width + x
                    ? false
                    : layer.collisions[index]
            ])
          else
            layer
      ]);
      final result = project(overrideMaps: {...maps, 102: changed});
      final evidence = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == event.identity.value);
      expect(evidence['status'], 'quarantinedWholeEvent');
      expect(evidence['gaps'],
          contains('sourceFixedRouteCounterReachUnqualified'));
      expect(
          result.nativeMaps[102]!.entities.where((entity) =>
              entity.properties['sourceEventIdentity'] == event.identity.value),
          isEmpty);
    });

    test('forged body cannot acquire a route approval', () {
      final original = analysis.eventAt(102, 11)!;
      final page = original.pages.single;
      final forged = SourceEventDefinition(
          sourceMapId: original.sourceMapId,
          sourceEventId: original.sourceEventId,
          sourceFileId: original.sourceFileId,
          identity: original.identity,
          name: original.name,
          x: original.x,
          y: original.y,
          locator: original.locator,
          pages: [
            SourceEventPageAnalysis(
                sourcePage: page.sourcePage,
                locator: page.locator,
                condition: page.condition,
                graphic: page.graphic,
                rawDataRef: page.rawDataRef,
                body: SourceEventBlock(nodes: const [], span: page.body.span),
                diagnostics: page.diagnostics)
          ]);
      final result = project(
          overrideAnalysis: SourceEventAnalysis(
              profile: analysis.profile,
              events: [
                for (final event in analysis.events)
                  event.identity == forged.identity ? forged : event
              ],
              diagnostics: analysis.diagnostics));
      final row = (result.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) => row['sourceIdentity'] == forged.identity.value);
      expect(row['status'], 'quarantinedWholeEvent');
      expect(row['nativeFixedRoute'], isNull);
    });

    test('duplicate logical event identities cannot share route admission', () {
      final event = analysis.eventAt(102, 11)!;
      expect(
          () => project(
              overrideAnalysis: SourceEventAnalysis(
                  profile: analysis.profile,
                  events: [event, event],
                  diagnostics: analysis.diagnostics)),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'events.source.binding')));
    });

    test('3D refuses native routes before creating NPCs', () {
      final result = project(overrideMaps: {
        for (final entry in maps.entries)
          entry.key: entry.value.copyWith(version: ProjectVersion.v9)
      });
      expect(result.nativeMaps.values.expand((map) => map.entities), isEmpty);
      expect(
          (result.semanticEvidence['events'] as List)
              .cast<Map>()
              .every((row) => row['status'] == 'quarantinedWholeEvent'),
          true);
    });
  },
      skip: archive == null || root == null
          ? 'Original pinned Kanto source required.'
          : false);
}

Iterable<SceneSetMapEventInstanceBooleanConsequence> _routeStops(
    Iterable<SceneNode> nodes) sync* {
  for (final node in nodes) {
    final payload = node.payload;
    if (payload is SceneActionPayload &&
        payload.consequence is SceneSetMapEventInstanceBooleanConsequence) {
      final consequence =
          payload.consequence as SceneSetMapEventInstanceBooleanConsequence;
      if (consequence.key == 'npc.autonomousRouteStopped') yield consequence;
    }
  }
}

List<SceneNode> _reachable(SceneAsset scene, String battle, String port) {
  final pending = scene.graph.edges
      .where((edge) => edge.fromNodeId == battle && edge.fromPortId == port)
      .map((edge) => edge.toNodeId)
      .toList();
  final visited = <String>{};
  while (pending.isNotEmpty) {
    final id = pending.removeLast();
    if (!visited.add(id)) continue;
    pending.addAll(scene.graph.edges
        .where((edge) => edge.fromNodeId == id)
        .map((edge) => edge.toNodeId));
  }
  return scene.graph.nodes.where((node) => visited.contains(node.id)).toList();
}
