import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_library_thumbnail.dart';
import 'package:avelune_studio/presentation/features/events/event_map_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'thumbnail forgets A while B waits and after null or missing map',
    (tester) async {
      final workspace = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await workspace.initialize();
      addTearDown(workspace.dispose);
      final loader = _DelayedLoader(workspace);
      final visuals = _MapIdentityVisuals();
      Widget page(String? id) => MaterialApp(
        home: Scaffold(
          body: CinematicLibraryThumbnail(
            key: const ValueKey('same-thumbnail'),
            mapId: id,
            loader: loader,
            visuals: visuals,
          ),
        ),
      );
      Finder map(String id) => find.byKey(ValueKey('rendered-map-$id'));
      await tester.pumpWidget(page('a'));
      await tester.pumpAndSettle();
      expect(map('a'), findsOneWidget);
      final state = tester.state(find.byType(CinematicLibraryThumbnail));
      await tester.pumpWidget(page('b'));
      await tester.pump();
      expect(tester.state(find.byType(CinematicLibraryThumbnail)), same(state));
      expect(map('a'), findsNothing);
      expect(map('b'), findsNothing);
      loader.pending.complete(workspaceMap('b'));
      await tester.pumpAndSettle();
      expect(map('b'), findsOneWidget);
      await tester.pumpWidget(page(null));
      await tester.pumpAndSettle();
      expect(map('b'), findsNothing);
      expect(find.byTooltip('Aucune carte choisie'), findsOneWidget);
      await tester.pumpWidget(page('b'));
      await tester.pumpAndSettle();
      expect(map('b'), findsOneWidget);
      await tester.pumpWidget(page('missing'));
      await tester.pumpAndSettle();
      expect(map('b'), findsNothing);
      expect(find.byTooltip('Carte indisponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _DelayedLoader extends EventMapLoader {
  _DelayedLoader(super.workspace);
  final pending = Completer<MapData>();
  @override
  Future<MapData> load(String id) async {
    if (id == 'b') return pending.future;
    if (id == 'missing') throw StateError('Carte absente');
    return workspaceMap(id);
  }
}

class _MapIdentityVisuals extends WorkspaceTestVisuals {
  @override
  Widget canvas(MapData map) =>
      SizedBox.expand(key: ValueKey('rendered-map-${map.id}'));
}
