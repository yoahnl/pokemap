import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_marker_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';

const _entity = MapEntity(
  id: 'healing',
  name: 'Boules',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 2, y: 2),
  blocksMovement: false,
  properties: {'source': 'preserved'},
);
ProjectManifest _project() => workspaceProject.copyWith(
  tilesets: [
    for (var sheet = 1; sheet <= 2; sheet++)
      ProjectTilesetEntry(
        id: 'sheet-$sheet',
        name: 'Sheet',
        relativePath: 'sheet-$sheet.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'sheet-$sheet',
          pixelWidth: 256,
          pixelHeight: 192,
          tileWidth: 64,
          tileHeight: 48,
        ),
      ),
  ],
  elements: [
    for (var n = 1; n <= 6; n++)
      ProjectElementEntry(
        id: 'balls-$n',
        name: 'Boules $n',
        tilesetId: 'sheet-${n <= 3 ? 1 : 2}',
        categoryId: 'props',
        frames: [
          for (var x = 0; x < 4; x++)
            TilesetVisualFrame(
              source: TilesetSourceRect(x: x, y: (n - 1) % 3 + 1),
              durationMs: 125,
            ),
        ],
      ),
  ],
);
void main() {
  testWidgets(
    'Studio guides six native healing variants and preserves undo redo reopen',
    (tester) async {
      final original = workspaceMap('a').copyWith(entities: [_entity]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: original, revision: 'base', mapId: 'a'),
      );
      final h = MapSelectionHarness(document, _project());
      addTearDown(h.dispose);
      await h.pump(tester);
      await h.use(tester, StudioMapTool.select);
      await h.tapCell(tester, 2, 2);
      expect(
        find.byKey(const ValueKey('healing-display-variant-0')),
        findsOneWidget,
      );
      for (var n = 1; n <= 6; n++) {
        final picker = find.byKey(ValueKey('healing-display-variant-${n - 1}'));
        await tester.ensureVisible(picker);
        await tester.tap(picker);
        await tester.pumpAndSettle();
        if (n == 2) {
          await tester.tap(find.text('Boules 1').last);
          await tester.pumpAndSettle();
          expect(document.current, original);
          expect(
            tester
                .widget<StudioButton>(
                  find.byKey(const ValueKey('healing-display-apply')),
                )
                .onPressed,
            isNull,
          );
          await tester.tap(picker);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Boules $n').last);
        await tester.pumpAndSettle();
      }
      final apply = find.byKey(const ValueKey('healing-display-apply'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      final expected = MapEntityHealingDisplayData(
        variantElementIds: [for (var n = 1; n <= 6; n++) 'balls-$n'],
      );
      expect(document.current.entities.single.healingDisplay, expected);
      expect(
        document.current.entities.single.copyWith(healingDisplay: null),
        _entity,
      );
      final saved = MapData.fromJson(document.current.toJson());
      expect(saved.entities.single.healingDisplay, expected);
      document.restore(redo: false);
      h.redraw();
      await tester.pumpAndSettle();
      expect(document.current, original);
      document.restore(redo: true);
      h.redraw();
      await tester.pumpAndSettle();
      expect(document.current.entities.single.healingDisplay, expected);
      final clear = find.byKey(const ValueKey('healing-display-clear'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(document.current, original);
      expect(tester.takeException(), isNull);
    },
  );
  for (final mode in ['blocking', 'wide', 'collision', 'visual', 'spatial']) {
    testWidgets('Studio refuses healing display on $mode target', (
      tester,
    ) async {
      var entity = _entity;
      var map = workspaceMap('a');
      if (mode == 'blocking') {
        entity = entity.copyWith(blocksMovement: true);
      }
      if (mode == 'wide') {
        entity = entity.copyWith(size: const GridSize(width: 2, height: 1));
      }
      if (mode == 'collision') {
        entity = entity.copyWith(properties: {'collision.width': '1'});
      }
      if (mode == 'visual') {
        entity = entity.copyWith(
          editorVisual: const MapEntityEditorVisual(elementId: 'balls-1'),
        );
      }
      if (mode == 'spatial') {
        map = map.copyWith(
          version: ProjectVersion.v9,
          spatialScene: MapSpatialScene(
            width: map.size.width,
            depth: map.size.height,
          ),
        );
      }
      map = map.copyWith(entities: [entity]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'base', mapId: 'a'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: MapMarkerInspector(
              document: document,
              project: _project(),
              entity: entity,
              onChanged: () {},
              onDeleted: () {},
            ),
          ),
        ),
      );
      expect(find.byType(StudioSelect), findsNothing);
      expect(document.current, map);
      expect(tester.takeException(), isNull);
    });
  }
}
