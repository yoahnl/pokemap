import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/map_tool_menu.dart';

void main() {
  testWidgets('the real map workspace links and unlinks both borders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final maps = WorkspaceMemoryPort();
    final controller = MapWorkspaceController(workspaceSession, maps);
    addTearDown(controller.dispose);
    final links = _MemoryConnections(maps);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: controller,
          mapConnectionPort: links,
          loadVisuals: (_, _) async => WorkspaceTestVisuals(),
          runtimeBuilder: (_, _, _) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await chooseMapExtraTool(tester, 'Passages');
    expect(find.text('Liaisons entre cartes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('connection-create')));
    await tester.pumpAndSettle();
    expect(links.writes, 1);
    expect(controller.active!.current.connections.single.targetMapId, 'b');
    expect(maps.saved['b']!.connections.single.targetMapId, 'a');
    expect(controller.active!.dirty, isFalse);
    await chooseMapExtraTool(tester, 'Peindre les collisions');
    expect(find.text('Liaisons entre cartes'), findsNothing);
    await chooseMapExtraTool(tester, 'Passages');
    await tester.tap(find.byKey(const ValueKey('connection-remove')));
    await tester.pumpAndSettle();
    expect(links.writes, 2);
    expect(controller.active!.current.connections, isEmpty);
    expect(maps.saved['b']!.connections, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a draft blocks the link without losing its changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final maps = WorkspaceMemoryPort();
    final controller = MapWorkspaceController(workspaceSession, maps);
    addTearDown(controller.dispose);
    final links = _MemoryConnections(maps);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: controller,
          mapConnectionPort: links,
          loadVisuals: (_, _) async => WorkspaceTestVisuals(),
          runtimeBuilder: (_, _, _) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.active!.commit(
      controller.active!.current.copyWith(name: 'Brouillon'),
    );
    await chooseMapExtraTool(tester, 'Passages');
    await tester.tap(find.byKey(const ValueKey('connection-create')));
    await tester.pumpAndSettle();
    expect(links.writes, 0);
    expect(controller.active!.current.name, 'Brouillon');
    expect(controller.active!.dirty, isTrue);
    expect(find.textContaining('Enregistrez les brouillons'), findsOneWidget);
  });

  testWidgets('collapsed map library leaves the selection button accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: controller,
          loadVisuals: (_, _) async => WorkspaceTestVisuals(),
          runtimeBuilder: (_, _, _) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Masquer les cartes'));
    await tester.pumpAndSettle();
    final arrow = tester.getRect(find.byTooltip('Afficher les cartes'));
    final select = tester.getRect(find.byKey(const ValueKey('Sélectionner')));
    expect(arrow.right, lessThan(select.left));
    expect(tester.takeException(), isNull);
  });
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
