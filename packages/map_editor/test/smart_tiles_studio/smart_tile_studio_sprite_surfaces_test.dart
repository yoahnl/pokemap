import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_sprite_preview.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Tiles Studio sprite surfaces', () {
    testWidgets('the atlas tab previews every registered atlas', (
      tester,
    ) async {
      final cache = _RecordingImageCache();
      addTearDown(cache.dispose);

      await _pumpPanel(tester, cache: cache);

      final previews = find.descendant(
        of: find.byKey(const Key('smart-tiles-workbench-column')),
        matching: find.byType(SmartTileSpritePreview),
      );
      expect(previews, findsNWidgets(2));

      // The seam must ask for the first cell of each atlas, not a placeholder.
      expect(
        cache.requests,
        containsAll(<_CropRequest>[
          const _CropRequest(
            path: '/projects/demo/assets/terrain.png',
            sourceRect: ui.Rect.fromLTWH(0, 0, 32, 32),
          ),
          const _CropRequest(
            path: '/projects/demo/assets/path.png',
            sourceRect: ui.Rect.fromLTWH(0, 0, 16, 16),
          ),
        ]),
      );
    });

    testWidgets('selecting an atlas opens its image in the atlas viewport', (
      tester,
    ) async {
      final cache = _RecordingImageCache();
      addTearDown(cache.dispose);
      final loader = _FakeAtlasImageLoader(width: 128, height: 128);

      await _pumpPanel(tester, cache: cache, imageLoader: loader);

      expect(
        find.byKey(const Key('smart-tiles-atlas-tab-viewport')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('smart-tiles-atlas-card-terrain')));
      await tester.pumpAndSettle();

      expect(loader.lastTilesetId, 'terrain-tileset');
      expect(
        find.byKey(const Key('smart-tiles-atlas-tab-viewport')),
        findsOneWidget,
      );
    });

    testWidgets('the inspector previews the selected preset', (tester) async {
      final cache = _RecordingImageCache();
      addTearDown(cache.dispose);

      await _pumpPanel(tester, cache: cache);

      expect(
        find.descendant(
          of: find.byKey(const Key('smart-tiles-inspector-column')),
          matching: find.byKey(const Key('smart-tiles-inspector-sprite')),
        ),
        findsOneWidget,
      );
      // The preset's representative sprite is its first candidate's frame:
      // column 3, row 0 of a 32px atlas.
      expect(
        cache.requests,
        contains(
          const _CropRequest(
            path: '/projects/demo/assets/terrain.png',
            sourceRect: ui.Rect.fromLTWH(96, 0, 32, 32),
          ),
        ),
      );
    });

    testWidgets('the rules tab previews each rule variant', (tester) async {
      final cache = _RecordingImageCache();
      addTearDown(cache.dispose);

      await _pumpPanel(tester, cache: cache);
      await tester.tap(find.byKey(const Key('smart-tiles-tab-rules')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('smart-tiles-rule-rule-a')),
          matching: find.byType(SmartTileSpritePreview),
        ),
        findsOneWidget,
      );
      expect(
        cache.requests,
        contains(
          const _CropRequest(
            path: '/projects/demo/assets/terrain.png',
            sourceRect: ui.Rect.fromLTWH(96, 0, 32, 32),
          ),
        ),
      );
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required EditorImageCache cache,
  SmartTileAtlasImageLoader imageLoader = const FileSmartTileAtlasImageLoader(),
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: SmartTilesStudioPanel(
          manifest: _manifest,
          projectRootPath: '/projects/demo',
          imageLoader: imageLoader,
          imageCache: cache,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _CropRequest {
  const _CropRequest({required this.path, required this.sourceRect});

  final String? path;
  final ui.Rect sourceRect;

  @override
  bool operator ==(Object other) =>
      other is _CropRequest &&
      other.path == path &&
      other.sourceRect == sourceRect;

  @override
  int get hashCode => Object.hash(path, sourceRect);

  @override
  String toString() => 'crop($path, $sourceRect)';
}

/// Records crop requests and never completes them, so the surfaces stay in
/// their loading state while the test asserts on what they asked for.
final class _RecordingImageCache extends EditorImageCache {
  _RecordingImageCache()
      : super(
          sessionKey: 'smart-tile-sprite-surfaces-test',
          retirementScheduler: (disposeImage) => disposeImage(),
        );

  final List<_CropRequest> requests = <_CropRequest>[];

  @override
  Future<EditorImageLoadResult> loadCrop(
    String? path, {
    required ui.Rect sourceRect,
    String variantKey = 'original',
    String sourceVariantKey = 'original',
    EditorImageBytesTransform? transformBytes,
  }) {
    requests.add(_CropRequest(path: path, sourceRect: sourceRect));
    return Completer<EditorImageLoadResult>().future;
  }
}

final class _FakeAtlasImageLoader implements SmartTileAtlasImageLoader {
  _FakeAtlasImageLoader({required this.width, required this.height});

  final int width;
  final int height;
  String? lastTilesetId;

  @override
  Future<SmartTileAtlasImageLoadResult> load({
    required String? projectRootPath,
    required ProjectTilesetEntry tileset,
  }) async {
    lastTilesetId = tileset.id;
    return SmartTileAtlasImageLoadResult(
      status: SmartTileAtlasImageLoadStatus.loaded,
      message: 'loaded',
      image: SmartTileAtlasImage(
        absolutePath: '$projectRootPath/${tileset.relativePath}',
        bytes: _onePixelPng,
        width: width,
        height: height,
        columnAlphaCoverage: List<double>.filled(width, 1),
        rowAlphaCoverage: List<double>.filled(height, 1),
      ),
    );
  }
}

final Uint8List _onePixelPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
  0x89, 0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
  0x42, 0x60, 0x82,
]);

final ProjectManifest _manifest = ProjectManifest(
  name: 'Smart Tiles sprite surfaces',
  version: ProjectVersion.v6,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'terrain-tileset',
      name: 'Terrain',
      relativePath: 'assets/terrain.png',
    ),
    ProjectTilesetEntry(
      id: 'path-tileset',
      name: 'Path',
      relativePath: 'assets/path.png',
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'terrain',
        name: 'Atlas terrain',
        tilesetId: 'terrain-tileset',
        columns: 8,
        rows: 8,
      ),
      ProjectSmartTileAtlas(
        id: 'path',
        name: 'Atlas chemin',
        tilesetId: 'path-tileset',
        cellWidth: 16,
        cellHeight: 16,
        columns: 4,
        rows: 4,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'ground',
      ),
    ],
    presets: <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'terrain-preset',
        name: 'Herbe courte',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: const <String>['grass'],
        status: SmartTilePresetStatus.published,
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'rule-a',
            centerMatch: const SmartTileSlotMatch.any(),
            signature: smartTileSignatureForMask(
              0,
              topology: SmartTileTopology.cardinal4,
            ),
            candidates: const <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'variant-a',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'terrain',
                        column: 3,
                        row: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
