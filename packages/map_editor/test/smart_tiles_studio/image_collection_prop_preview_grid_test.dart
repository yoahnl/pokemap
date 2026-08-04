import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/image_collection_prop_preview_grid.dart';

void main() {
  testWidgets('shows selectable visual cards without requiring tile IDs',
      (tester) async {
    int? selectedTileId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 400,
            child: ImageCollectionPropPreviewGrid(
              source: _collection,
              cellWidth: 16,
              cellHeight: 16,
              imagesByAssetId: const {},
              selectedTileId: null,
              elapsedMs: 0,
              onSelected: (tileId) => selectedTileId = tileId,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Arbre ancien'), findsOneWidget);
    expect(find.text('Élément 2'), findsOneWidget);
    expect(find.textContaining('Animé · 2 images'), findsOneWidget);
    expect(find.byKey(const Key('image-collection-prop-preview-10')),
        findsOneWidget);
    expect(find.text('ID 10'), findsNothing);

    await tester.tap(find.byKey(const Key('image-collection-prop-card-10')));
    await tester.pump();

    expect(selectedTileId, 10);
  });

  testWidgets('paints the exact shared source rectangle with pixel filtering',
      (tester) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 16, 16),
      Paint()..color = const Color(0xFF18A060),
    );
    final image = await recorder.endRecording().toImage(16, 16);
    addTearDown(image.dispose);
    final visual = const ProjectTilesetVisualResolver().resolve(
      source: const ProjectRegularAtlasTilesetSource(
        assetId: 'preview',
        pixelWidth: 16,
        pixelHeight: 16,
        tileWidth: 16,
        tileHeight: 16,
      ),
      selection: const ProjectTilesetVisualSelection.regularAtlas(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
      cellWidth: 16,
      cellHeight: 16,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: const Key('visual-boundary'),
            child: ProjectTilesetVisualPreview(
              visual: visual,
              imagesByAssetId: <String, ui.Image>{'preview': image},
              elapsedMs: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CustomPaint), findsWidgets);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('visual-boundary')),
    );
    final centerPixel = await tester.runAsync(() async {
      final rendered = await boundary.toImage();
      try {
        final bytes = await rendered.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final center =
            ((rendered.height ~/ 2) * rendered.width + rendered.width ~/ 2) * 4;
        return <int>[
          bytes!.getUint8(center),
          bytes.getUint8(center + 1),
          bytes.getUint8(center + 2),
          bytes.getUint8(center + 3),
        ];
      } finally {
        rendered.dispose();
      }
    });
    expect(
      centerPixel,
      const <int>[24, 160, 96, 255],
    );
  });
}

const _collection = ProjectImageCollectionTilesetSource(
  pages: <ProjectImageCollectionPage>[
    ProjectImageCollectionPage(
      id: 'page',
      assetId: 'page-asset',
      pixelWidth: 40,
      pixelHeight: 16,
    ),
  ],
  tileDefinitions: <ProjectImageCollectionTileDefinition>[
    ProjectImageCollectionTileDefinition(
      tileId: 10,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 0,
        y: 0,
        width: 16,
        height: 16,
      ),
      properties: <ProjectTilesetProperty>[
        ProjectTilesetProperty(
          name: 'displayName',
          type: ProjectTilesetPropertyType.string,
          value: 'Arbre ancien',
        ),
      ],
      animation: <ProjectImageCollectionAnimationFrame>[
        ProjectImageCollectionAnimationFrame(tileId: 10, durationMs: 120),
        ProjectImageCollectionAnimationFrame(tileId: 11, durationMs: 120),
      ],
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 11,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 16,
        y: 0,
        width: 16,
        height: 16,
      ),
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 42,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 32,
        y: 0,
        width: 8,
        height: 8,
      ),
    ),
  ],
);
