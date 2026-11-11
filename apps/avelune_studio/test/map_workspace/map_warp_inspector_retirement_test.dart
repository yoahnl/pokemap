import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_connection_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late WarpEditingCommands commands;
  late MapWorkspaceViewState view;
  late VoidCallback rebuild;
  var changed = 0, linked = 0, unlinked = 0;

  setUp(() {
    final map = workspaceMap('a');
    document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
    );
    commands = WarpEditingCommands(document, workspaceProject);
    view = MapWorkspaceViewState()..paletteTab = 'Passages';
    changed = 0;
    linked = 0;
    unlinked = 0;
  });

  tearDown(() => view.dispose());

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = () => setState(() {});
              return SizedBox(
                width: 340,
                child: MapSelectionInspector(
                  document: document,
                  project: workspaceProject,
                  visuals: WorkspaceTestVisuals(),
                  view: view,
                  onChanged: () => changed++,
                  onOpenElement: (_) {},
                  onEditElement: (_) {},
                  onLinkMaps: (_, _, _) async => linked++,
                  onUnlinkMaps: (_) async => unlinked++,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final tool in [StudioMapTool.select, StudioMapTool.warp]) {
    for (final passive in [false, true]) {
      testWidgets(
        '${tool.name} selected ${passive ? 'sceneOnly' : 'active'} warp keeps a neutral inspector after rebuild',
        (tester) async {
          final warp = passive
              ? commands.placeArrival(const GridPos(x: 2, y: 3))
              : commands.place(
                  workspaceEntries.last,
                  const GridPos(x: 2, y: 3),
                );
          view.select(document, MapSelectionFamily.warp, warp.id);
          view.tool = tool;
          expect(view.paletteTab, 'Passages');
          expect(
            commands.selected(
              view.selectedFor(document.current.id, MapSelectionFamily.warp),
            ),
            warp,
          );
          final before = document.current;
          final undo = document.undoCount;
          final canRedo = document.canRedo;
          for (var frame = 0; frame < 2; frame++) {
            if (frame == 0) {
              await mount(tester);
            } else {
              rebuild();
              await tester.pumpAndSettle();
            }
            expect(
              find.byKey(const ValueKey('map-warp-inspector-retired')),
              findsOneWidget,
            );
            expect(find.byType(MapConnectionPanel), findsNothing);
            expect(
              commands.selected(
                view.selectedFor(document.current.id, MapSelectionFamily.warp),
              ),
              warp,
            );
            expect(document.current, same(before));
            expect(document.undoCount, undo);
            expect(document.canRedo, canRedo);
            expect(changed, 0);
            expect(linked, 0);
            expect(unlinked, 0);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }

    testWidgets('${tool.name} without selection still routes to connections', (
      tester,
    ) async {
      commands.place(workspaceEntries.last, const GridPos(x: 2, y: 3));
      view.tool = tool;
      final before = document.current;
      final undo = document.undoCount;
      expect(
        commands.selected(
          view.selectedFor(document.current.id, MapSelectionFamily.warp),
        ),
        isNull,
      );
      await mount(tester);
      expect(find.byType(MapConnectionPanel), findsOneWidget);
      expect(
        find.byKey(const ValueKey('map-warp-inspector-retired')),
        findsNothing,
      );
      rebuild();
      await tester.pumpAndSettle();
      expect(find.byType(MapConnectionPanel), findsOneWidget);
      expect(document.current, same(before));
      expect(document.undoCount, undo);
      expect(changed, 0);
      expect(linked, 0);
      expect(unlinked, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('connection tool keeps priority over a selected existing warp', (
    tester,
  ) async {
    final warp = commands.placeArrival(const GridPos(x: 2, y: 3));
    view.select(document, MapSelectionFamily.warp, warp.id);
    view.tool = StudioMapTool.connection;
    final before = document.current;
    final undo = document.undoCount;
    expect(
      commands.selected(
        view.selectedFor(document.current.id, MapSelectionFamily.warp),
      ),
      warp,
    );
    await mount(tester);
    expect(find.byType(MapConnectionPanel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-warp-inspector-retired')),
      findsNothing,
    );
    rebuild();
    await tester.pumpAndSettle();
    expect(find.byType(MapConnectionPanel), findsOneWidget);
    expect(
      commands.selected(
        view.selectedFor(document.current.id, MapSelectionFamily.warp),
      ),
      warp,
    );
    expect(document.current, same(before));
    expect(document.undoCount, undo);
    expect(changed, 0);
    expect(linked, 0);
    expect(unlinked, 0);
    expect(tester.takeException(), isNull);
  });
}
