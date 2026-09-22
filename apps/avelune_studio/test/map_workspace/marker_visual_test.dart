import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
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

void main() {
  for (final kind in [MapEntityKind.spawn, MapEntityKind.sign]) {
    testWidgets('the ${kind.name} inspector holds the charter', (tester) async {
      const size = Size(1024, 640);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadDesktopCaptureFonts);

      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'base',
          mapId: 'a',
        ),
      );
      final commands = MapEntityEditingCommands(document, workspaceProject);
      final entity = commands.place(kind, const GridPos(x: 3, y: 4));
      if (kind == MapEntityKind.sign) {
        commands.updateSign(
          entity.id,
          title: 'Quai numéro 3',
          plainText: 'Le train de 17h42 part d’ici.',
        );
      }

      final view = MapWorkspaceViewState()
        ..tool = kind == MapEntityKind.spawn
            ? StudioMapTool.spawn
            : StudioMapTool.sign;
      view.select(document, MapSelectionFamily.marker, entity.id);
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
                      project: workspaceProject,
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
                      project: workspaceProject,
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

      expect(
        find.text(
          kind == MapEntityKind.spawn ? 'Point d’apparition' : 'Panneau',
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull, reason: 'no overflow');
      await captureM3Widget(tester, key, 'asmap001-${kind.name}');
    });
  }
}
