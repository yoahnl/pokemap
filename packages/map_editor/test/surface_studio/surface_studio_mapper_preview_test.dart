import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  test('tile source rect uses 1-based UI columns and 0-based atlas pixels', () {
    final rect = surfaceStudioTileSourceRect(
      uiColumn: 4,
      frameIndex: 1,
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    expect(rect, const ui.Rect.fromLTWH(24, 8, 8, 8));
  });

  test('tile source rect points to the expected fixture colors', () {
    final atlas = img.decodePng(_atlasBytes())!;

    final column4Frame0 = surfaceStudioTileSourceRect(
      uiColumn: 4,
      frameIndex: 0,
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );
    final column5Frame1 = surfaceStudioTileSourceRect(
      uiColumn: 5,
      frameIndex: 1,
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    final green = atlas.getPixel(
      column4Frame0.left.toInt() + 1,
      column4Frame0.top.toInt() + 1,
    );
    final darkBlue = atlas.getPixel(
      column5Frame1.left.toInt() + 1,
      column5Frame1.top.toInt() + 1,
    );

    expect(green.r, 20);
    expect(green.g, 220);
    expect(green.b, 60);
    expect(darkBlue.r, 8);
    expect(darkBlue.g, 42);
    expect(darkBlue.b, 96);
  });

  testWidgets(
      'selection alone is not mapping, quick center assignment activates preview',
      (tester) async {
    final temp = Directory.systemTemp.createTempSync('surface_mapper_preview_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
    );
    await tester.pumpAndSettle();

    expect(find.text('Colonnes sélectionnées : 4–5'), findsOneWidget);
    expect(find.text('Plein(center) : non assigné'), findsOneWidget);
    expect(find.textContaining('Assignez au moins le rôle'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    await tester.tap(
      find.byKey(const Key('surfaceStudio.atlas.useSelectionAsCenter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plein(center) : colonnes 4–5'), findsOneWidget);
    expect(find.textContaining('Assignez au moins le rôle'), findsNothing);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsOneWidget);
    expect(find.textContaining('Preview partielle'), findsOneWidget);
    expect(
      find.textContaining('Source rect actuelle : x=24 y=0 w=8 h=8'),
      findsOneWidget,
    );

    final centerSlot =
        find.byKey(const Key('surfaceStudio.schema.role.center'));
    expect(find.descendant(of: centerSlot, matching: find.text('4')),
        findsOneWidget);
    expect(find.descendant(of: centerSlot, matching: find.text('5')),
        findsOneWidget);
  });

  testWidgets('preview frame controls change the rendered frame state',
      (tester) async {
    final temp = Directory.systemTemp.createTempSync('surface_frame_preview_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('surfaceStudio.atlas.useSelectionAsCenter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Frame 1 / 2'), findsOneWidget);
    expect(
      find.textContaining('Source rect actuelle : x=24 y=0 w=8 h=8'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
    await tester.pumpAndSettle();
    expect(find.text('Frame 2 / 2'), findsOneWidget);
    expect(
      find.textContaining('Source rect actuelle : x=32 y=8 w=8 h=8'),
      findsOneWidget,
    );
  });
}

SurfaceStudioReadModel _readModel() {
  const atlasId = 'water-atlas';
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: atlasId,
          name: 'Water Atlas',
          tilesetId: 'water_tiles',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
          ),
        ),
      ],
      animations: const <ProjectSurfaceAnimation>[],
      presets: const <ProjectSurfacePreset>[],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  const columns = 5;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      final color = switch (column) {
        3 => frame == 0 ? img.ColorRgb8(20, 220, 60) : img.ColorRgb8(6, 90, 24),
        4 =>
          frame == 0 ? img.ColorRgb8(30, 120, 240) : img.ColorRgb8(8, 42, 96),
        _ => img.ColorRgb8(140 + column * 10, 20, 60 + frame * 30),
      };
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: color,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
