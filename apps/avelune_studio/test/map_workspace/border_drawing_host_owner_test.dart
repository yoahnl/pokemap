import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_disk_owner_fixture.dart';

void main() {
  testWidgets(
    'canonical border preparation and canvas drawing preserve cardinal sprites and disk persistence',
    (tester) async {
      final fixture = await MapDiskOwnerFixture.withBorder(
        tester,
        nativeOrientations: true,
      );
      final undoBefore = fixture.document.undoCount;
      await fixture.runFamily('Bordures');
      await fixture.chooseBorder('muret');
      await fixture.tapCell(10, 8);
      await fixture.tapCell(13, 8);
      await fixture.tapCell(13, 11);
      await fixture.key(LogicalKeyboardKey.enter);
      await fixture.pump(frames: 6);
      final feature = fixture.document.current.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single;
      final placements = feature.materialization!.placements;
      expect(placements.first.primitiveId, 'lineCap-east');
      expect(placements.last.primitiveId, 'lineCap-north');
      expect(
        placements
            .singleWhere((p) => p.primitiveId.startsWith('lineCorner'))
            .primitiveId,
        'lineCorner-east',
      );
      expect(
        placements.map((p) => p.transform),
        everyElement(BorderSpriteTransform(quarterTurns: 0, flipX: false)),
      );
      expect(fixture.document.undoCount, undoBefore + 1);
      MapBorderEditingCommands(
        fixture.document,
        fixture.maps.project!,
      ).setForeground(
        layerId: fixture.document.current.layers
            .whereType<BorderLayer>()
            .single
            .id,
        renderInForeground: true,
      );
      fixture.maps.notify();
      await fixture.pump(frames: 4);
      expect(
        fixture.document.current.layers
            .whereType<BorderLayer>()
            .single
            .renderInForeground,
        isTrue,
      );
      expect(fixture.document.undoCount, undoBefore + 2);
      fixture.document.restore(redo: false);
      expect(
        fixture.document.current.layers
            .whereType<BorderLayer>()
            .single
            .renderInForeground,
        isFalse,
      );
      fixture.document.restore(redo: true);
      expect(
        fixture.document.current.layers
            .whereType<BorderLayer>()
            .single
            .renderInForeground,
        isTrue,
      );
      await fixture.save();
      final reopened = await fixture.reopen(fixture.document.current.id);
      expect(
        reopened.layers.whereType<BorderLayer>().single.content.features.single,
        feature,
      );
      expect(
        reopened.layers.whereType<BorderLayer>().single.renderInForeground,
        isTrue,
      );
    },
  );

  testWidgets(
    'an empty border catalogue refuses canvas tracing without changing the document',
    (tester) async {
      final fixture = await MapDiskOwnerFixture.open(tester);
      await fixture.runFamily('Bordures');

      final before = fixture.document.current;
      final history = fixture.document.undoCount;
      expect(
        MapBorderEditingCommands.publishedLines(fixture.maps.project!),
        isEmpty,
      );
      await fixture.tapCell(10, 8);
      final view = fixture.view;
      expect(view.borderDraft, isNull);
      expect(
        fixture.document.error,
        contains('Choisissez une bordure publiée'),
      );
      expect(fixture.document.current, same(before));
      expect(fixture.document.undoCount, history);
      expect(fixture.document.dirty, isFalse);
    },
  );

  testWidgets(
    'canonical border preparation and canvas preview finish in one undoable save',
    (tester) async {
      final fixture = await MapDiskOwnerFixture.withBorder(tester);
      final initial = fixture.document.current;
      final undoBefore = fixture.document.undoCount;

      await fixture.runFamily('Bordures');
      await fixture.chooseBorder('muret');
      await fixture.tapCell(10, 8);
      final pointer = TestPointer(42, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(fixture.cellAt(13, 8)));
      await fixture.pump(frames: 3);
      final previewView = fixture.view;
      expect(
        previewView.borderDraft?.previewCells,
        contains(const GridPos(x: 13, y: 8)),
      );
      expect(fixture.document.current, initial);
      await fixture.tapCell(13, 8);
      expect(fixture.document.current, initial);
      final view = fixture.view;
      expect(
        view.borderDraft?.anchors.length,
        2,
        reason: '${view.borderDraft?.anchors} · ${fixture.document.error}',
      );
      expect(view.borderDraft!.canFinish, isTrue);

      await fixture.tapCell(13, 11);
      await fixture.key(LogicalKeyboardKey.enter);
      await fixture.pump(frames: 6);

      final layer = fixture.document.current.layers
          .whereType<BorderLayer>()
          .single;
      final feature = layer.content.features.single;
      final stroke = (feature.geometry as BorderStrokeGeometry).strokes.single;
      expect(stroke.points, contains(const GridPos(x: 13, y: 8)));
      expect(stroke.points, contains(const GridPos(x: 13, y: 11)));
      expect(feature.materialization, isNotNull);
      expect(fixture.document.undoCount, undoBefore + 1);

      await fixture.save();
      final reopened = await fixture.reopen(initial.id);
      final saved = reopened.layers.whereType<BorderLayer>().single;
      expect(saved.content.features.single, feature);
    },
  );

  testWidgets(
    'Escape preserves the same draft then canonical reselection discards it without writes',
    (tester) async {
      final fixture = await MapDiskOwnerFixture.withBorder(tester);
      final initial = fixture.document.current;
      final undoBefore = fixture.document.undoCount;
      await fixture.runFamily('Bordures');
      await fixture.chooseBorder('muret');
      await fixture.tapCell(10, 8);
      await fixture.tapCell(13, 8);
      final view = fixture.view;
      final draft = view.borderDraft;
      expect(draft, isNotNull);
      expect(draft!.anchors, hasLength(2));
      await fixture.key(LogicalKeyboardKey.escape);
      await fixture.pump(frames: 3);

      expect(view.tool.name, 'select');
      expect(view.borderDraft, same(draft));
      expect(fixture.document.current, same(initial));
      expect(fixture.document.undoCount, undoBefore);
      expect(fixture.document.dirty, isFalse);
      await fixture.chooseBorder('muret');
      expect(view.borderDraft, isNull);
      expect(view.tool.name, 'border');
      expect(fixture.document.current, same(initial));
      expect(fixture.document.undoCount, undoBefore);
      expect(fixture.document.dirty, isFalse);
    },
  );

  testWidgets('switching tools keeps the unfinished border draft', (
    tester,
  ) async {
    final fixture = await MapDiskOwnerFixture.withBorder(tester);
    await fixture.runFamily('Bordures');
    await fixture.chooseBorder('muret');
    await fixture.tapCell(10, 8);
    await fixture.tapCell(13, 8);
    final view = fixture.view;
    final draft = view.borderDraft;
    await fixture.runFamily('Sélection');
    expect(view.tool.name, 'select');
    expect(view.borderDraft?.anchors, draft?.anchors);
    await fixture.runFamily('Bordures');
    expect(view.tool.name, 'border');
    expect(view.borderDraft?.anchors, draft?.anchors);
    expect(fixture.document.dirty, isFalse);
  });

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
      await fixture.runFamily('Bordures');
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
    await fixture.runFamily('Bordures');
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
