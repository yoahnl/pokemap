import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('connection actions link and unlink both saved map borders', () async {
    final maps = WorkspaceMemoryPort();
    final controller = MapWorkspaceController(workspaceSession, maps);
    addTearDown(controller.dispose);
    await controller.initialize();
    final links = _MemoryConnections(maps);
    final actions = MapWorkspaceConnectionActions(
      controller: controller,
      port: links,
      isActive: () => true,
      changed: () {},
    );
    await actions.link(MapConnectionDirection.east, 'b', 0);
    expect(actions.error, isNull);
    expect(links.writes, 1);
    expect(controller.active!.current.connections.single.targetMapId, 'b');
    expect(maps.saved['b']!.connections.single.targetMapId, 'a');
    expect(controller.active!.dirty, isFalse);
    await actions.unlink(MapConnectionDirection.east);
    expect(actions.error, isNull);
    expect(links.writes, 2);
    expect(controller.active!.current.connections, isEmpty);
    expect(maps.saved['b']!.connections, isEmpty);
  });

  test(
    'a dirty map blocks connection publication without losing its draft',
    () async {
      final maps = WorkspaceMemoryPort();
      final controller = MapWorkspaceController(workspaceSession, maps);
      addTearDown(controller.dispose);
      await controller.initialize();
      final links = _MemoryConnections(maps);
      final actions = MapWorkspaceConnectionActions(
        controller: controller,
        port: links,
        isActive: () => true,
        changed: () {},
      );
      controller.active!.commit(
        controller.active!.current.copyWith(name: 'Brouillon'),
      );
      final before = controller.active!.current;
      await actions.link(MapConnectionDirection.east, 'b', 0);
      expect(links.writes, 0);
      expect(controller.active!.current, same(before));
      expect(controller.active!.dirty, isTrue);
      expect(actions.error, contains('Enregistrez les brouillons'));
    },
  );
}

final class _MemoryConnections implements MapConnectionPort {
  _MemoryConnections(this.maps);

  final WorkspaceMemoryPort maps;
  int writes = 0;

  @override
  Future<void> link({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    MapData? expectedTarget,
  }) async {
    writes++;
    final target = maps.saved[targetMapId] ?? workspaceMap(targetMapId);
    maps.saved[source.id] = upsertMapConnectionOnMap(
      source,
      connection: MapConnection(
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
      ),
    );
    maps.saved[targetMapId] = upsertMapConnectionOnMap(
      target,
      connection: MapConnection(
        direction: direction.opposite,
        targetMapId: source.id,
        offset: -offset,
      ),
    );
  }

  @override
  Future<void> unlink({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    MapData? expectedTarget,
  }) async {
    writes++;
    final targetId = source.connections
        .firstWhere((entry) => entry.direction == direction)
        .targetMapId;
    maps.saved[source.id] = removeMapConnectionFromMap(
      source,
      direction: direction,
    );
    maps.saved[targetId] = removeMapConnectionFromMap(
      maps.saved[targetId]!,
      direction: direction.opposite,
    );
  }
}
