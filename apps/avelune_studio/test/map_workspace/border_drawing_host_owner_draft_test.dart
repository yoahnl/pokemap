import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:flutter/services.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_disk_owner_fixture.dart';

void main() {
  test('border draft rejects a crossing and leaves its anchors unchanged', () {
    final draft =
        MapBorderDrawingDraft.start(
              mapId: 'map',
              mapSize: const GridSize(width: 12, height: 12),
              blueprintId: 'muret',
              origin: const GridPos(x: 2, y: 2),
            )
            .addAngle(const GridPos(x: 7, y: 2))
            .addAngle(const GridPos(x: 7, y: 7))
            .addAngle(const GridPos(x: 4, y: 7));
    expect(
      () => draft.addAngle(const GridPos(x: 4, y: 1)),
      throwsA(isA<ValidationException>()),
    );
    expect(draft.anchors.length, 4);
  });

  test('clicking the origin closes and previews the final segment', () {
    final draft =
        MapBorderDrawingDraft.start(
              mapId: 'map',
              mapSize: const GridSize(width: 12, height: 12),
              blueprintId: 'muret',
              origin: const GridPos(x: 2, y: 2),
            )
            .addAngle(const GridPos(x: 5, y: 2))
            .addAngle(const GridPos(x: 5, y: 5))
            .addAngle(const GridPos(x: 2, y: 5))
            .addAngle(const GridPos(x: 2, y: 2));
    expect(draft.closed, isTrue);
    expect(draft.canFinish, isTrue);
    expect(draft.previewCells, contains(const GridPos(x: 2, y: 4)));
  });

  test('grid-edge draft reaches the outer border of the map', () {
    final draft = MapBorderDrawingDraft.start(
      mapId: 'map',
      mapSize: const GridSize(width: 12, height: 12),
      blueprintId: 'stone',
      alignment: BorderStrokeAlignment.gridEdges,
      origin: const GridPos(x: 12, y: 2),
    ).addAngle(const GridPos(x: 12, y: 8));
    expect(draft.canFinish, isTrue);
    expect(draft.previewCells, contains(const GridPos(x: 12, y: 5)));
  });

  testWidgets(
    'horizontal facades draw without rotation and refuse vertical edits',
    (tester) async {
      final fixture = await MapDiskOwnerFixture.withBorder(
        tester,
        template: BorderBlueprintTemplate.horizontalFacade,
      );
      await fixture.selectTool(StudioMapTool.border);
      await fixture.chooseBorder('muret');
      await fixture.tapCell(10, 8);
      await fixture.tapCell(13, 8);
      await fixture.key(LogicalKeyboardKey.enter);
      await fixture.pump(frames: 4);
      final current = fixture.document.current;
      final placements = current.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .materialization!
          .placements;
      expect(placements, hasLength(4));
      for (final placement in placements) {
        expect(placement.transform.quarterTurns, 0);
        expect(placement.transform.flipX, isFalse);
      }
      await fixture.tapCell(10, 10);
      await fixture.tapCell(10, 13);
      await fixture.key(LogicalKeyboardKey.enter);
      await fixture.pump(frames: 4);
      expect(fixture.document.current, current);
      expect(
        fixture.document.error,
        contains('Une façade doit suivre un tracé horizontal ouvert'),
      );
    },
  );

  testWidgets('a published stone chain uses grid edges through the host', (
    tester,
  ) async {
    final fixture = await MapDiskOwnerFixture.withBorder(
      tester,
      template: BorderBlueprintTemplate.stoneChainLine,
    );
    await fixture.selectTool(StudioMapTool.border);
    await fixture.chooseBorder('muret');
    await fixture.tapCell(10, 8);
    await fixture.tapCell(13, 8);
    final draft = fixture.view.borderDraft;
    expect(draft?.alignment, BorderStrokeAlignment.gridEdges);
    expect(draft?.canFinish, isTrue);
    await fixture.key(LogicalKeyboardKey.enter);
    await fixture.pump(frames: 4);
    final feature = fixture.document.current.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(
      (feature.geometry as BorderStrokeGeometry).alignment,
      BorderStrokeAlignment.gridEdges,
    );
    expect(feature.materialization, isNotNull);
  });
}
