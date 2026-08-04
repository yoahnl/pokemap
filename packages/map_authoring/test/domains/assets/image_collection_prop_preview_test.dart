import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('builds sorted no-code prop labels on the shared visual resolver', () {
    final items = buildImageCollectionPropPreviewItems(
      source: _collection,
      cellWidth: 16,
      cellHeight: 16,
    );

    expect(items.map((item) => item.tileId), const <int>[10, 42]);
    expect(items.map((item) => item.displayName),
        const <String>['Grand arbre', 'Élément 2']);
    expect(items.first.isAnimated, isTrue);
    expect(items.first.frameCount, 2);
    expect(items.first.visual.totalDurationMs, 300);
    expect(
      items.first.visual.animationBounds,
      const ProjectTilesetPixelRect(x: 0, y: -8, width: 24, height: 24),
    );
    expect(items.last.isAnimated, isFalse);
    expect(items.last.pixelSizeLabel, '8 × 8 px');
  });
}

const _collection = ProjectImageCollectionTilesetSource(
  pages: <ProjectImageCollectionPage>[
    ProjectImageCollectionPage(
      id: 'page',
      assetId: 'page-asset',
      pixelWidth: 64,
      pixelHeight: 64,
    ),
  ],
  tileDefinitions: <ProjectImageCollectionTileDefinition>[
    ProjectImageCollectionTileDefinition(
      tileId: 42,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 0,
        y: 0,
        width: 8,
        height: 8,
      ),
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 10,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 8,
        y: 0,
        width: 16,
        height: 16,
      ),
      properties: <ProjectTilesetProperty>[
        ProjectTilesetProperty(
          name: 'name',
          type: ProjectTilesetPropertyType.string,
          value: 'Grand arbre',
        ),
      ],
      animation: <ProjectImageCollectionAnimationFrame>[
        ProjectImageCollectionAnimationFrame(tileId: 10, durationMs: 100),
        ProjectImageCollectionAnimationFrame(tileId: 11, durationMs: 200),
      ],
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 11,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 24,
        y: 0,
        width: 24,
        height: 24,
      ),
    ),
  ],
);
