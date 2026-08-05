import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const resolver = ProjectTilesetVisualResolver();

  group('ProjectTilesetVisualResolver', () {
    test('resolves spaced regular atlases without drawing their gutters', () {
      const source = ProjectRegularAtlasTilesetSource(
        assetId: 'atlas-main',
        pixelWidth: 68,
        pixelHeight: 68,
        tileWidth: 32,
        tileHeight: 32,
        marginX: 1,
        marginY: 1,
        spacingX: 2,
        spacingY: 2,
        pixelOffsetX: -3,
        pixelOffsetY: 5,
      );

      final visual = resolver.resolve(
        source: source,
        selection: const ProjectTilesetVisualSelection.regularAtlas(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
        ),
        cellWidth: 16,
        cellHeight: 16,
      );

      expect(visual.isAnimated, isFalse);
      expect(visual.frames.single.slices, hasLength(4));
      expect(
        visual.frames.single.slices.map((slice) => slice.sourceRect),
        const <ProjectTilesetPixelRect>[
          ProjectTilesetPixelRect(x: 1, y: 1, width: 32, height: 32),
          ProjectTilesetPixelRect(x: 35, y: 1, width: 32, height: 32),
          ProjectTilesetPixelRect(x: 1, y: 35, width: 32, height: 32),
          ProjectTilesetPixelRect(x: 35, y: 35, width: 32, height: 32),
        ],
      );
      expect(
        visual.frames.single.slices.map((slice) => slice.destinationRect),
        const <ProjectTilesetPixelRect>[
          ProjectTilesetPixelRect(x: -3, y: 5, width: 16, height: 16),
          ProjectTilesetPixelRect(x: 13, y: 5, width: 16, height: 16),
          ProjectTilesetPixelRect(x: -3, y: 21, width: 16, height: 16),
          ProjectTilesetPixelRect(x: 13, y: 21, width: 16, height: 16),
        ],
      );
      expect(
        visual.animationBounds,
        const ProjectTilesetPixelRect(x: -3, y: 5, width: 32, height: 32),
      );
    });

    test('resolves variable collection frames with bottom-left anchoring', () {
      final visual = resolver.resolve(
        source: _collection,
        selection: const ProjectTilesetVisualSelection.imageCollection(
          tileId: 10,
        ),
        cellWidth: 16,
        cellHeight: 16,
      );

      expect(visual.isAnimated, isTrue);
      expect(visual.totalDurationMs, 400);
      expect(visual.frames.map((frame) => frame.tileId), const <int>[11, 42]);
      expect(
        visual.frames[0].slices.single,
        const ProjectTilesetVisualSlice(
          assetId: 'props-page',
          sourceRect:
              ProjectTilesetPixelRect(x: 1, y: 2, width: 16, height: 24),
          destinationRect:
              ProjectTilesetPixelRect(x: 2, y: -9, width: 16, height: 24),
        ),
      );
      expect(
        visual.frames[1].slices.single.destinationRect,
        const ProjectTilesetPixelRect(x: -3, y: 4, width: 32, height: 16),
      );
      expect(
        visual.animationBounds,
        const ProjectTilesetPixelRect(x: -3, y: -9, width: 32, height: 29),
      );
      expect(visual.frameAt(0).tileId, 11);
      expect(visual.frameAt(99).tileId, 11);
      expect(visual.frameAt(100).tileId, 42);
      expect(visual.frameAt(399).tileId, 42);
      expect(visual.frameAt(400).tileId, 11);
      expect(visual.frameAt(-1).tileId, 42);
    });

    test('resolves regular atlas tile animation timelines', () {
      const source = ProjectRegularAtlasTilesetSource(
        assetId: 'animated-atlas',
        pixelWidth: 64,
        pixelHeight: 32,
        tileWidth: 16,
        tileHeight: 16,
        tileAnimations: <ProjectRegularAtlasTileAnimation>[
          ProjectRegularAtlasTileAnimation(
            tileId: 1,
            frames: <ProjectImageCollectionAnimationFrame>[
              ProjectImageCollectionAnimationFrame(
                tileId: 1,
                durationMs: 100,
              ),
              ProjectImageCollectionAnimationFrame(
                tileId: 6,
                durationMs: 300,
              ),
            ],
          ),
        ],
      );

      final visual = resolver.resolve(
        source: source,
        selection: const ProjectTilesetVisualSelection.regularAtlas(
          source: TilesetSourceRect(x: 1, y: 0),
        ),
        cellWidth: 16,
        cellHeight: 16,
      );

      expect(visual.isAnimated, isTrue);
      expect(visual.totalDurationMs, 400);
      expect(visual.frameAt(0).tileId, 1);
      expect(visual.frameAt(100).tileId, 6);
      expect(
        visual.frameAt(100).slices.single.sourceRect,
        const ProjectTilesetPixelRect(x: 32, y: 16, width: 16, height: 16),
      );
    });

    test('uses the same resolved bounds for exact and conservative culling',
        () {
      final visual = resolver.resolve(
        source: _collection,
        selection: const ProjectTilesetVisualSelection.imageCollection(
          tileId: 10,
        ),
        cellWidth: 16,
        cellHeight: 16,
      );

      expect(
        visual.cullingRectAt(50, originX: 100, originY: 50),
        const ProjectTilesetPixelRect(x: 102, y: 41, width: 16, height: 24),
      );
      expect(
        visual.cullingRectAt(
          50,
          originX: 100,
          originY: 50,
          conservativeAnimationBounds: true,
        ),
        const ProjectTilesetPixelRect(x: 97, y: 41, width: 32, height: 29),
      );
      expect(
        visual.isVisibleAt(
          50,
          originX: 100,
          originY: 50,
          viewport: const ProjectTilesetPixelRect(
            x: 96,
            y: 40,
            width: 2,
            height: 2,
          ),
          conservativeAnimationBounds: true,
        ),
        isTrue,
      );
      expect(
        visual.isVisibleAt(
          50,
          originX: 100,
          originY: 50,
          viewport: const ProjectTilesetPixelRect(
            x: 0,
            y: 0,
            width: 16,
            height: 16,
          ),
        ),
        isFalse,
      );
    });

    test('fails closed for mismatched selections and broken references', () {
      expect(
        () => resolver.resolve(
          source: const ProjectRegularAtlasTilesetSource(
            assetId: 'broken-atlas',
            pixelWidth: 32,
            pixelHeight: 68,
            tileWidth: 32,
            tileHeight: 32,
            marginX: 1,
            marginY: 1,
            spacingX: 2,
            spacingY: 2,
          ),
          selection: const ProjectTilesetVisualSelection.regularAtlas(
            source: TilesetSourceRect(x: 0, y: 0),
          ),
          cellWidth: 16,
          cellHeight: 16,
        ),
        throwsA(_resolutionError('tileset.visual.atlas_invalid')),
      );
      expect(
        () => resolver.resolve(
          source: _collection,
          selection: const ProjectTilesetVisualSelection.regularAtlas(
            source: TilesetSourceRect(x: 0, y: 0),
          ),
          cellWidth: 16,
          cellHeight: 16,
        ),
        throwsA(_resolutionError('tileset.visual.selection_mismatch')),
      );
      expect(
        () => resolver.resolve(
          source: ProjectImageCollectionTilesetSource(
            pages: _collection.pages,
            tileDefinitions: const <ProjectImageCollectionTileDefinition>[
              ProjectImageCollectionTileDefinition(
                tileId: 3,
                pageId: 'missing-page',
                sourceRect: ProjectTilesetPixelRect(
                  x: 0,
                  y: 0,
                  width: 8,
                  height: 8,
                ),
              ),
            ],
          ),
          selection: const ProjectTilesetVisualSelection.imageCollection(
            tileId: 3,
          ),
          cellWidth: 16,
          cellHeight: 16,
        ),
        throwsA(_resolutionError('tileset.visual.page_missing')),
      );
    });

    test('freezes single-pass frame and slice iterables exactly once', () {
      final frame = ProjectTilesetVisualFrameResolution(
        tileId: 1,
        durationMs: 0,
        slices: _singlePassSlices(),
      );
      final visual = ProjectTilesetVisualResolution(
        frames: _singlePassFrames(frame),
      );

      expect(frame.slices, hasLength(1));
      expect(
        visual.animationBounds,
        const ProjectTilesetPixelRect(x: 0, y: 0, width: 8, height: 8),
      );
    });
  });
}

Iterable<ProjectTilesetVisualSlice> _singlePassSlices() sync* {
  yield const ProjectTilesetVisualSlice(
    assetId: 'page',
    sourceRect: ProjectTilesetPixelRect(x: 0, y: 0, width: 8, height: 8),
    destinationRect: ProjectTilesetPixelRect(x: 0, y: 0, width: 8, height: 8),
  );
}

Iterable<ProjectTilesetVisualFrameResolution> _singlePassFrames(
  ProjectTilesetVisualFrameResolution frame,
) sync* {
  yield frame;
}

Matcher _resolutionError(String code) =>
    isA<ProjectTilesetVisualResolutionException>()
        .having((error) => error.code, 'code', code);

final _collection = ProjectImageCollectionTilesetSource(
  pages: const <ProjectImageCollectionPage>[
    ProjectImageCollectionPage(
      id: 'page-a',
      assetId: 'props-page',
      pixelWidth: 64,
      pixelHeight: 64,
    ),
  ],
  tileDefinitions: const <ProjectImageCollectionTileDefinition>[
    ProjectImageCollectionTileDefinition(
      tileId: 10,
      pageId: 'page-a',
      sourceRect: ProjectTilesetPixelRect(
        x: 48,
        y: 48,
        width: 8,
        height: 8,
      ),
      animation: <ProjectImageCollectionAnimationFrame>[
        ProjectImageCollectionAnimationFrame(tileId: 11, durationMs: 100),
        ProjectImageCollectionAnimationFrame(tileId: 42, durationMs: 300),
      ],
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 11,
      pageId: 'page-a',
      sourceRect: ProjectTilesetPixelRect(
        x: 1,
        y: 2,
        width: 16,
        height: 24,
      ),
      offsetX: 2,
      offsetY: -1,
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 42,
      pageId: 'page-a',
      sourceRect: ProjectTilesetPixelRect(
        x: 20,
        y: 4,
        width: 32,
        height: 16,
      ),
      offsetX: -3,
      offsetY: 4,
    ),
  ],
);
