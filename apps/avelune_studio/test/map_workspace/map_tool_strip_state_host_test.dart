import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_column.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart';
import '../support/map_tool_menu.dart';

void main() {
  for (final label in ['Terrains', 'Passages']) {
    testWidgets('$label tool reveals its hidden asset picker', (tester) async {
      await MapHostFixture.open(tester, size: const Size(1536, 960));
      await tester.tap(find.byTooltip('Palette'));
      await pumpIo(tester);
      final button = find.widgetWithText(StudioButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await pumpIo(tester);
      expect(find.byType(MapWorkspacePaletteColumn), findsOneWidget);
      expect(
        tester
            .widget<MapWorkspacePaletteColumn>(
              find.byType(MapWorkspacePaletteColumn),
            )
            .view
            .paletteTab,
        label,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('character placement reveals the hidden character picker', (
    tester,
  ) async {
    await MapHostFixture.open(tester, size: const Size(1536, 960));
    await tester.tap(find.byTooltip('Palette'));
    await pumpIo(tester);
    await chooseMapExtraTool(tester, 'Placer un personnage');
    expect(find.byType(MapWorkspacePaletteColumn), findsOneWidget);
    expect(
      tester
          .widget<MapWorkspacePaletteColumn>(
            find.byType(MapWorkspacePaletteColumn),
          )
          .view
          .paletteTab,
      'Personnages',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('visible palette remains inline when selecting the decor tool', (
    tester,
  ) async {
    await MapHostFixture.open(tester);
    await tester.tap(find.widgetWithText(StudioButton, 'Décors'));
    await pumpIo(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const ValueKey('decor-arbre')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decor tool reveals a hidden palette and adds a chosen asset', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(
      tester,
      size: const Size(1536, 960),
    );
    await tester.tap(find.byTooltip('Palette'));
    await pumpIo(tester);
    expect(find.byType(MapWorkspacePaletteColumn), findsNothing);
    await tester.tap(find.widgetWithText(StudioButton, 'Décors'));
    await pumpIo(tester);
    expect(find.byType(MapWorkspacePaletteColumn), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('decor-arbre')));
    await pumpIo(tester);
    expect(find.byType(MapWorkspacePaletteColumn), findsNothing);
    final canvas = tester.widget<MapWorkspaceCanvas>(
      find.byType(MapWorkspaceCanvas),
    );
    expect(canvas.view.tool, StudioMapTool.place);
    final count = fixture.document.current.placedElements.length;
    await fixture.tapCell(4, 4);
    await pumpIo(tester);
    expect(fixture.document.current.placedElements.length, count + 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chosen eraser replaces the misleading selection highlight', (
    tester,
  ) async {
    await MapHostFixture.open(tester);
    await chooseMapExtraTool(tester, 'Gomme de tuiles');

    final canvas = tester.widget<MapWorkspaceCanvas>(
      find.byType(MapWorkspaceCanvas),
    );
    expect(canvas.view.tool, StudioMapTool.erase);
    expect(
      tester
          .widget<StudioButton>(find.byKey(const ValueKey('Sélectionner')))
          .secondary,
      isTrue,
    );
    expect(find.byKey(const ValueKey('active-extra-tool')), findsOneWidget);
    expect(find.text('Gomme de tuiles'), findsOneWidget);
  });
}
