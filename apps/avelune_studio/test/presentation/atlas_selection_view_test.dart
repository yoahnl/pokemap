import 'package:avelune_studio/presentation/features/resources/atlas_selection_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const source = ProjectRegularAtlasTilesetSource(
  assetId: 'atlas',
  pixelWidth: 64,
  pixelHeight: 100,
  tileWidth: 16,
  tileHeight: 24,
  marginX: 2,
  marginY: 3,
  spacingX: 2,
  spacingY: 4,
  pixelOffsetX: 7,
  pixelOffsetY: -9,
);

void main() {
  testWidgets(
    'first layout fits and centres source while selection updates retain user zoom',
    (tester) async {
      Widget host(TilesetSourceRect selected) => MaterialApp(
        home: Scaffold(
          body: AtlasSelectionView(
            source: source,
            selected: selected,
            image: const SizedBox.expand(),
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pumpWidget(host(const TilesetSourceRect(x: 0, y: 0)));
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 4);
      final viewport = tester.getRect(find.byType(InteractiveViewer));
      final centre = _at(tester, const Offset(32, 50));
      expect(centre.dx, closeTo(viewport.center.dx, .01));
      expect(centre.dy, closeTo(viewport.center.dy, .01));
      await tester.tap(find.byTooltip('Zoom arrière'));
      await tester.pumpAndSettle();
      final changed = viewer.transformationController!.value.clone();
      await tester.pumpWidget(host(const TilesetSourceRect(x: 1, y: 1)));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value, changed);
      await tester.tap(find.byTooltip('Ajuster la source'));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 4);
    },
  );

  testWidgets(
    'non-square source selection uses canonical crop and rejects margins and gaps',
    (tester) async {
      final selections = <TilesetSourceRect>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AtlasSelectionView(
              source: source,
              selected: const TilesetSourceRect(x: 0, y: 0),
              image: const SizedBox.expand(),
              onSelected: selections.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(_at(tester, const Offset(3, 4)));
      expect(selections.last, const TilesetSourceRect(x: 0, y: 0));
      await tester.tapAt(_at(tester, const Offset(21, 32)));
      expect(selections.last, const TilesetSourceRect(x: 1, y: 1));
      final resolved = const ProjectTilesetVisualResolver().resolve(
        source: source,
        selection: ProjectTilesetVisualSelection.regularAtlas(
          source: selections.last,
        ),
        cellWidth: 16,
        cellHeight: 24,
      );
      expect(resolved.frames.single.slices.single.sourceRect.x, 20);
      expect(resolved.frames.single.slices.single.sourceRect.y, 31);
      final count = selections.length;
      for (final point in [
        const Offset(1, 4),
        const Offset(3, 2),
        const Offset(18, 4),
        const Offset(3, 27),
        const Offset(55, 4),
        const Offset(3, 83),
      ]) {
        await tester.tapAt(_at(tester, point));
      }
      expect(selections, hasLength(count));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rectangle drag selects source cells across spacing, cancelled drag cannot leak',
    (tester) async {
      final selections = <TilesetSourceRect>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AtlasSelectionView(
              source: source,
              selected: const TilesetSourceRect(x: 0, y: 0),
              image: const SizedBox.expand(),
              onSelected: selections.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        _at(tester, const Offset(3, 4)),
      );
      await gesture.moveTo(_at(tester, const Offset(53, 82)));
      expect(
        selections.last,
        const TilesetSourceRect(x: 0, y: 0, width: 3, height: 3),
      );
      await gesture.cancel();
      final count = selections.length;
      final gapGesture = await tester.startGesture(
        _at(tester, const Offset(18, 4)),
      );
      await gapGesture.moveTo(_at(tester, const Offset(21, 32)));
      await gapGesture.up();
      expect(selections, hasLength(count));
    },
  );

  testWidgets('terrain source selection stays one cell during a drag', (
    tester,
  ) async {
    final selections = <TilesetSourceRect>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AtlasSelectionView(
            source: source,
            selected: const TilesetSourceRect(x: 0, y: 0),
            image: const SizedBox.expand(),
            onSelected: selections.add,
            singleCell: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(_at(tester, const Offset(3, 4)));
    await gesture.moveTo(_at(tester, const Offset(53, 82)));
    await gesture.up();
    expect(selections.last, const TilesetSourceRect(x: 2, y: 2));
  });
}

Offset _at(WidgetTester tester, Offset point) => tester
    .renderObject<RenderBox>(find.byKey(const ValueKey('atlas-selection')))
    .localToGlobal(point);
