import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_column.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/map_workspace_fixture.dart';

const herbs = ProjectEncounterTable(
  id: 'herbs',
  name: 'Hautes herbes du quai',
  encounterKind: EncounterKind.walk,
);

void main() {
  for (final kind in [GameplayZoneKind.encounter, GameplayZoneKind.hazard]) {
    testWidgets('the ${kind.name} zone inspector holds the charter', (
      tester,
    ) async {
      const size = Size(1024, 640);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadDesktopCaptureFonts);

      final project = workspaceProject.copyWith(encounterTables: [herbs]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'base',
          mapId: 'a',
        ),
      );
      final commands = GameplayZoneEditingCommands(document, project);
      final zone = commands.place(
        kind,
        const MapRect(
          pos: GridPos(x: 2, y: 3),
          size: GridSize(width: 5, height: 4),
        ),
      );
      if (kind == GameplayZoneKind.encounter) {
        commands.updateEncounter(zone.id, tableId: herbs.id);
      } else {
        commands.updateHazard(zone.id, damagePerStep: 2);
      }

      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.gameplayZone
        ..selectedZoneId = zone.id;
      addTearDown(view.dispose);
      final search = TextEditingController();
      addTearDown(search.dispose);
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MediaQuery(
            data: const MediaQueryData(size: size),
            child: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MapWorkspacePaletteColumn(
                      width: 240,
                      project: project,
                      document: document,
                      visuals: WorkspaceTestVisuals(),
                      view: view,
                      search: search,
                      storyAvailable: true,
                      onToolChanged: () {},
                      onRefresh: () {},
                      onResources: () {},
                    ),
                    const Spacer(),
                    MapSelectionInspector(
                      document: document,
                      project: project,
                      visuals: WorkspaceTestVisuals(),
                      view: view,
                      onChanged: () {},
                      onOpenElement: (_) {},
                      onEditElement: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone de jeu'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('zone-coverage-problem')),
        findsNothing,
        reason: 'a fully set zone raises no alarm',
      );
      expect(tester.takeException(), isNull, reason: 'no overflow');
      await captureM3Widget(tester, key, 'asmap001-zone-${kind.name}');
    });
  }
}
