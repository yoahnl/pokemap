import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../characters/character_editing_test.dart' show guide;
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/map_context_harness.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('the context menu holds the charter on a crowded cell', (
    tester,
  ) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final h = MapContextHarness.of(
      workspaceProject.copyWith(characters: [guide]),
    );
    addTearDown(h.dispose);
    CharacterEditingCommands(
      h.document,
      h.project,
    ).place(guide, const GridPos(x: 4, y: 4));
    GameplayZoneEditingCommands(h.document, h.project).place(
      GameplayZoneKind.encounter,
      const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 5, height: 5),
      ),
    );
    MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    h.document.selectedId = null;

    final key = GlobalKey();
    await h.pump(
      tester,
      wrap: (child) => RepaintBoundary(key: key, child: child),
    );
    await h.rightClick(tester, 4, 4);

    expect(tester.takeException(), isNull);
    await captureM3Widget(tester, key, 'asmap002-menu-contextuel');
  });

  testWidgets('the menu stays inside the window near a corner', (tester) async {
    await tester.runAsync(loadDesktopCaptureFonts);
    final h = MapContextHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final key = GlobalKey();
    await h.pump(
      tester,
      wrap: (child) => RepaintBoundary(key: key, child: child),
    );

    await h.rightClick(tester, 19, 15);

    final menu = tester.getRect(find.byKey(const ValueKey('map-context-menu')));
    expect(menu.right, lessThanOrEqualTo(1280));
    expect(menu.bottom, lessThanOrEqualTo(800));
    expect(menu.left, greaterThanOrEqualTo(0));
    expect(tester.takeException(), isNull);
    await captureM3Widget(tester, key, 'asmap002-menu-bord');
  });
}
