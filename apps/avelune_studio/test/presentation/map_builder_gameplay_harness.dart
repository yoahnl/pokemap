import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

late WorkspaceMemoryPort maps;
late RecordingConnections connections;
late ProviderContainer container;

Future<void> settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

MapData active() =>
    container.read(mapWorkspaceControllerProvider(exampleA)).active!.current;

Future<void> openGameplay(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
  ProjectManifest project = workspaceProject,
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final sessions = ControlledProjectSessionPort();
  maps = WorkspaceMemoryPort(manifest: project);
  maps.saved['a'] = workspaceMap('a').copyWith(
    warps: const [
      MapWarp(
        id: 'door',
        pos: GridPos(x: 4, y: 5),
        targetMapId: 'b',
        targetPos: GridPos(x: 2, y: 3),
      ),
    ],
    connections: const [
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'b',
        offset: 1,
      ),
    ],
  );
  connections = RecordingConnections(maps);
  container = ProviderContainer(
    overrides: [
      projectSessionPortProvider.overrideWithValue(sessions),
      projectDirectoryPickerProvider.overrideWithValue(
        () async => exampleA.directoryPath,
      ),
      mapWorkspacePortProvider(exampleA).overrideWithValue(maps),
      mapConnectionPortProvider(exampleA).overrideWithValue(connections),
      workspaceVisualsLoaderProvider.overrideWithValue(
        (session, manifest) async => WorkspaceTestVisuals(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: studioTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StudioRoot(),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('studio-home-import')));
  await tester.pump();
  sessions.pending.single.complete(exampleA);
  await settle(tester);
  await tester.tap(find.byKey(const ValueKey('map-space-gameplay')));
  await settle(tester);
}

Future<void> choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.byKey(ValueKey(field)));
  await settle(tester);
  await tester.tap(find.text(option).last);
  await settle(tester);
}

StudioButton button(WidgetTester tester, String key) =>
    tester.widget(find.byKey(ValueKey(key)));

class RecordingConnections implements MapConnectionPort {
  RecordingConnections(this.maps);

  final WorkspaceMemoryPort maps;
  final calls = <String>[];

  @override
  Future<List<MapWorkspaceDocument>> link({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    MapData? expectedTarget,
  }) async {
    calls.add('link ${direction.name} $targetMapId $offset');
    maps.saved[source.id] = source.copyWith(
      connections: [
        for (final entry in source.connections)
          if (entry.direction != direction) entry,
        MapConnection(
          direction: direction,
          targetMapId: targetMapId,
          offset: offset,
        ),
      ],
    );
    return _saved(source.id);
  }

  @override
  Future<List<MapWorkspaceDocument>> unlink({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    MapData? expectedTarget,
  }) async {
    calls.add('unlink ${direction.name}');
    maps.saved[source.id] = source.copyWith(
      connections: [
        for (final entry in source.connections)
          if (entry.direction != direction) entry,
      ],
    );
    return _saved(source.id);
  }

  List<MapWorkspaceDocument> _saved(String id) => [
    MapWorkspaceDocument(
      map: maps.saved[id]!,
      revision: 'linked-${calls.length}',
      mapId: id,
    ),
  ];
}
