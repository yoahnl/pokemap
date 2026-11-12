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

class _RecordingConnections implements MapConnectionPort {
  _RecordingConnections(this.maps);

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

void main() {
  late WorkspaceMemoryPort maps;
  late _RecordingConnections connections;
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
  }) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = ControlledProjectSessionPort();
    maps = WorkspaceMemoryPort();
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
    connections = _RecordingConnections(maps);
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

  testWidgets('the game space lists the neighbours and passages of the map', (
    tester,
  ) async {
    await openGameplay(tester);

    expect(find.byKey(const ValueKey('map-library')), findsNothing);
    final neighbour = find.byKey(
      const ValueKey('map-gameplay-connection-east'),
    );
    expect(
      find.descendant(of: neighbour, matching: find.text('Jardin')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: neighbour,
        matching: find.text('Bord est · décalage 1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-gameplay-warp-door')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-search')),
      'introuvable',
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('map-gameplay-warp-door')), findsNothing);
    expect(find.text('Aucun passage sur cette carte.'), findsOneWidget);
  });

  testWidgets('the game space speaks the chosen language', (tester) async {
    await openGameplay(tester, locale: const Locale('en'));

    expect(find.text('Neighbour maps'), findsOneWidget);
    expect(find.text('east edge · offset 1'), findsOneWidget);
    expect(find.text('Cell 4, 5'), findsOneWidget);
    expect(find.text('Cartes voisines'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-door')));
    await settle(tester);
    expect(find.text('Screen transition'), findsOneWidget);
    expect(find.text('Delete this passage'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-duration')),
      '9000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-apply')));
    await settle(tester);
    expect(
      find.text('The duration must be between 1 and 5000 ms.'),
      findsOneWidget,
    );
  });

  testWidgets('a selected passage edits its arrival, transition and removal', (
    tester,
  ) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-door')));
    await settle(tester);

    expect(
      find.byKey(const ValueKey('map-gameplay-warp-form')),
      findsOneWidget,
    );
    expect(button(tester, 'map-gameplay-warp-apply').onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-x')),
      '7',
    );
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-duration')),
      '600',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-apply')));
    await settle(tester);
    expect(active().warps.single.targetPos, const GridPos(x: 7, y: 3));
    expect(active().warps.single.transition.durationSeconds, .6);
    expect(find.text('Non enregistré'), findsOneWidget);

    await choose(tester, 'map-gameplay-warp-transition', 'Instantanée');
    expect(active().warps.single.transition.type, MapWarpTransitionType.none);

    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-warp-duration')),
      '9000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-apply')));
    await settle(tester);
    expect(find.textContaining('entre 1 et 5000 ms'), findsOneWidget);
    expect(active().warps.single.transition.durationSeconds, .6);

    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-delete')));
    await settle(tester);
    expect(active().warps, isEmpty);
    expect(find.byKey(const ValueKey('map-gameplay-warp-form')), findsNothing);
  });

  testWidgets('placing a passage arms the map tool until one is placed', (
    tester,
  ) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-add')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-warp')));
    await settle(tester);

    expect(
      find.byKey(const ValueKey('map-gameplay-warp-placement')),
      findsOneWidget,
    );
    await choose(tester, 'map-gameplay-warp-placement-target', 'Jardin');
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Passage',
    );

    await tester.tap(find.byKey(const ValueKey('map-canvas')));
    await settle(tester);

    expect(active().warps, hasLength(2));
    final placed = active().warps.last;
    expect(placed.targetMapId, 'b');
    expect(
      find.byKey(const ValueKey('map-gameplay-warp-form')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Sélection',
    );

    await tester.tap(find.byKey(const ValueKey('map-space-construction')));
    await settle(tester);
    expect(find.byKey(const ValueKey('map-library')), findsOneWidget);
  });

  testWidgets('neighbour links go through the connection port', (tester) async {
    await openGameplay(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-east')),
    );
    await settle(tester);

    expect(button(tester, 'map-gameplay-connection-apply').onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('map-gameplay-connection-offset')),
      '3',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-apply')),
    );
    await settle(tester);
    expect(connections.calls, ['link east b 3']);
    expect(active().connections.single.offset, 3);

    await tester.tap(find.byKey(const ValueKey('map-gameplay-add')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-add-connection')));
    await settle(tester);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('map-gameplay-connection-edge-east')),
          )
          .onSelected,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-apply')),
    );
    await settle(tester);
    expect(connections.calls.last, 'link north b 0');

    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-remove')),
    );
    await settle(tester);
    expect(connections.calls.last, 'unlink north');
    expect(active().connections.map((entry) => entry.direction), [
      MapConnectionDirection.east,
    ]);
  });

  testWidgets('an unsaved map cannot change its links', (tester) async {
    await openGameplay(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-door')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('map-gameplay-warp-delete')));
    await settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-gameplay-connection-east')),
    );
    await settle(tester);

    expect(find.textContaining('Enregistrez la carte'), findsOneWidget);
    expect(button(tester, 'map-gameplay-connection-remove').onPressed, isNull);
    expect(connections.calls, isEmpty);
  });
}
