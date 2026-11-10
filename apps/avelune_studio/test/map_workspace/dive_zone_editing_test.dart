import 'package:avelune_studio/features/map_workspace/application/dive_pair_publishing_session.dart';

import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_connection_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_dive_pair_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

MapData endpoint(String id, DiveZoneRole role) => workspaceMap(id).copyWith(
  layers: const [],
  entities: [
    MapEntity(
      id: '$id-spawn',
      name: 'Arrivée locale',
      kind: MapEntityKind.spawn,
      pos: const GridPos(x: 2, y: 2),
      spawn: const MapEntitySpawnData(),
    ),
  ],
  gameplayZones: [
    MapGameplayZone(
      id: 'terrain',
      kind: GameplayZoneKind.movement,
      area: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 6, height: 6),
      ),
      movement: MovementZonePayload(
        requiredMode: role == DiveZoneRole.surface
            ? MovementMode.surf
            : MovementMode.dive,
      ),
    ),
    MapGameplayZone(
      id: 'point',
      name: 'Point de Plongée',
      kind: GameplayZoneKind.fieldAction,
      area: const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
      fieldAction: FieldActionZonePayload(
        actionKind: FieldActionZoneKind.dive,
        dive: DiveZonePayload(role: role),
      ),
    ),
  ],
);
void main() {
  test('opposite map and point are temporary selections; dirty maps cannot publish', () async {
    final source = endpoint('a', DiveZoneRole.surface),
        target = endpoint('b', DiveZoneRole.underwater);
    final memory = WorkspaceMemoryPort()
      ..saved.addAll({'a': source, 'b': target});
    final session = ProjectSession(
      sessionId: 'memory',
      name: 'Dive',
      directoryPath: '/tmp/studio-dive-memory',
    );
    final controller = MapWorkspaceController(session, memory);
    addTearDown(controller.dispose);
    await controller.initialize();
    final document = controller.active!;
    final publisher = _DivePublisher();
    final publishing = DivePairPublishingSession(
      controller: controller,
      port: publisher,
    );
    addTearDown(publishing.dispose);
    await publishing.selectMap('b');
    publishing.targetZoneId = 'point';
    expect(document.dirty, isFalse);
    expect(document.canUndo, isFalse);
    expect(publisher.writes, 0);
    document.commit(document.current.copyWith(name: 'Brouillon'));
    await publishing.publish(document, document.current.gameplayZones.last);
    expect(publishing.message, contains('Enregistrez les brouillons'));
    expect(publisher.writes, 0);
    expect(document.current.gameplayZones.last.fieldAction!.dive!.link, isNull);
  });
  test(
    'Dive role, exact local spawn and movement mode stay draft with Undo redo',
    () {
      final map = endpoint('a', DiveZoneRole.surface);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'initial', mapId: 'a'),
      );
      final commands = GameplayZoneEditingCommands(document, workspaceProject);
      commands.configureDive('point', arrivalSpawnId: 'a-spawn');
      final configured = document.current;
      expect(document.dirty, isTrue);
      expect(document.saved, map);
      document.restore(redo: false);
      expect(document.current, map);
      document.restore(redo: true);
      expect(document.current, configured);
      commands.updateMovement('terrain', requiredMode: MovementMode.dive);
      final deep = document.current;
      expect(
        deep.gameplayZones.first.movement!.requiredMode,
        MovementMode.dive,
      );
      document.restore(redo: false);
      expect(document.current, configured);
      document.restore(redo: true);
      expect(document.current, deep);
    },
  );
  test('Studio publishes both clean maps, refreshes history, cold reopens and refuses stale preimages', () async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
    );
    await parent.create(recursive: true);
    final root = await parent.createTemp('studio-dive-');
    addTearDown(() => root.delete(recursive: true));
    final canonical = Directory(await root.resolveSymbolicLinks());
    final maps =
        [
              endpoint('a', DiveZoneRole.surface),
              endpoint('b', DiveZoneRole.underwater),
            ]
            .map(
              (map) => map.copyWith(
                gameplayZones: [
                  map.gameplayZones.first,
                  map.gameplayZones.last.copyWith(
                    fieldAction: map.gameplayZones.last.fieldAction!.copyWith(
                      dive: map.gameplayZones.last.fieldAction!.dive!.copyWith(
                        arrivalSpawnId: '${map.id}-spawn',
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList();
    final project = ProjectManifest(
      name: 'Dive Studio',
      tilesets: const [],
      maps: [
        for (final map in maps)
          ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
      ],
    );
    await Directory('${canonical.path}/maps').create();
    await File('${canonical.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    for (final map in maps) {
      await File('${canonical.path}/maps/${map.id}.json')
          .writeAsString(jsonEncode(map.toJson()));
    }
    final session = ProjectSession(
      sessionId: canonical.path,
      name: 'Dive',
      directoryPath: canonical.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final controller = MapWorkspaceController(session, adapter);
    addTearDown(controller.dispose);
    await controller.initialize();
    final source = controller.active!.current;
    final target = (await adapter.loadMap(session, project.maps.last)).map;
    final publisher = LocalMapConnectionAdapter(adapter);
    final publishing = DivePairPublishingSession(
      controller: controller,
      port: publisher,
    );
    addTearDown(publishing.dispose);
    await publishing.selectMap('b');
    publishing.targetZoneId = 'point';
    await publishing.publish(controller.active!, source.gameplayZones.last);
    expect(publishing.message, contains('Les deux points sont liés'));
    expect(controller.active!.dirty, isFalse);
    expect(controller.active!.canUndo, isFalse);
    final linkedSource = controller.documents['a']!.current,
        linkedTarget = controller.documents['b']!.current;
    validateDiveZonePair(
      sourceMap: linkedSource,
      sourceZoneId: 'point',
      targetMap: linkedTarget,
      targetZoneId: 'point',
    );
    await expectLater(
      publisher.publishDivePair(
        session: session,
        source: source,
        expectedTarget: target,
        zoneId: 'point',
        targetZoneId: 'point',
        unlink: false,
      ),
      throwsA(isA<MapWorkspaceFailure>()),
    );
    final reopenedSource = (await adapter.loadMap(
      session,
      project.maps.first,
    )).map;
    final reopenedTarget = (await adapter.loadMap(
      session,
      project.maps.last,
    )).map;
    validateDiveZonePair(
      sourceMap: reopenedSource,
      sourceZoneId: 'point',
      targetMap: reopenedTarget,
      targetZoneId: 'point',
    );
    await publishing.publish(
      controller.documents['a']!,
      linkedSource.gameplayZones.last,
    );
    expect(publishing.message, contains('Les deux points sont déliés'));
    expect(controller.documents['a']!.current, source);
    expect(controller.documents['b']!.current, target);
  });
}

final class _DivePublisher implements MapDivePairPort {
  int writes = 0;
  @override
  Future<void> publishDivePair({
    required ProjectSession session,
    required MapData source,
    required MapData expectedTarget,
    required String zoneId,
    required String targetZoneId,
    required bool unlink,
  }) async {
    writes++;
  }
}
