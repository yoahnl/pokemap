import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('CharacterAnimationSourceResolver', () {
    const character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'hero_legacy',
      frameWidth: 2,
      frameHeight: 3,
    );
    test(
      'extended canvases preserve pixel density and bottom anchoring',
      () {
        const frame = CharacterAnimationFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 56),
        );
        final resolver = CharacterAnimationSourceResolver();
        final animation = CharacterAnimation(
          state: CharacterAnimationState.surfIdle,
          direction: EntityFacing.south,
          sourceAssetId: 'surf',
          presentationReferenceHeightPx: 32,
          frames: [frame],
        );
        final resolved = resolver.resolveFrame(
          character: character,
          animation: animation,
          frame: frame,
          tileWidth: 16,
          tileHeight: 16,
          availableImageIds: {characterAnimationRuntimeImageId('surf')},
        )!;
        expect(
          resolved.presentationRect(width: 32, height: 32),
          const Rect.fromLTWH(0, -24, 32, 56),
        );
        final spatial = resolved.presentationRect(width: 1.92, height: 1.92);
        expect(spatial.width, closeTo(1.92, 1e-9));
        expect(spatial.height, closeTo(3.36, 1e-9));
        expect(1.92 - spatial.bottom, closeTo(0, 1e-9));
      },
    );

    test('legacy non-square sources preserve their stretched presentation', () {
      const source = ResolvedCharacterAnimationFrameSource(
        imageId: 'old',
        sourceRect: Rect.fromLTWH(0, 0, 21, 29),
        usesLegacyGrid: false,
      );
      expect(
        source.presentationRect(width: 32, height: 48),
        const Rect.fromLTWH(0, 0, 32, 48),
      );
    });

    test('custom animation sources retain their explicit canvas reference', () {
      const frame = CharacterAnimationFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 64, height: 56),
      );
      final source = CharacterAnimationSourceResolver().resolveCustomFrame(
        character: character,
        clip: const CharacterCustomAnimationClip(
          definitionId: 'ride',
          sourceAssetId: 'surf',
          presentationReferenceHeightPx: 32,
          frames: [frame],
        ),
        frame: frame,
        availableImageIds: {characterAnimationRuntimeImageId('surf')},
      )!;
      expect(
        source.presentationRect(width: 32, height: 32),
        const Rect.fromLTWH(-16, -24, 64, 56),
      );
    });

    test('keeps legacy grid coordinates unchanged', () {
      const animation = CharacterAnimation(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.south,
      );
      const frame = CharacterAnimationFrame(
        source: TilesetSourceRect(x: 2, y: 1, width: 1, height: 1),
      );

      final resolved = CharacterAnimationSourceResolver().resolveFrame(
        character: character,
        animation: animation,
        frame: frame,
        tileWidth: 16,
        tileHeight: 16,
        availableImageIds: const <String>{'hero_legacy'},
      );

      expect(resolved, isNotNull);
      expect(resolved!.imageId, 'hero_legacy');
      expect(resolved.usesLegacyGrid, isTrue);
      expect(resolved.sourceRect.left, 64);
      expect(resolved.sourceRect.top, 48);
      expect(resolved.sourceRect.width, 32);
      expect(resolved.sourceRect.height, 48);
    });

    test('uses dedicated source pixel coordinates without scaling', () {
      const animation = CharacterAnimation(
        state: CharacterAnimationState.walk,
        direction: EntityFacing.east,
        sourceAssetId: 'hero_walk',
      );
      const frame = CharacterAnimationFrame(
        source: TilesetSourceRect(x: 37, y: 19, width: 21, height: 29),
      );

      final resolved = CharacterAnimationSourceResolver().resolveFrame(
        character: character,
        animation: animation,
        frame: frame,
        tileWidth: 16,
        tileHeight: 16,
        availableImageIds: <String>{
          characterAnimationRuntimeImageId('hero_walk'),
        },
      );

      expect(resolved, isNotNull);
      expect(
        resolved!.imageId,
        characterAnimationRuntimeImageId('hero_walk'),
      );
      expect(resolved.usesLegacyGrid, isFalse);
      expect(resolved.sourceRect.left, 37);
      expect(resolved.sourceRect.top, 19);
      expect(resolved.sourceRect.width, 21);
      expect(resolved.sourceRect.height, 29);
    });

    test('missing dedicated source emits one diagnostic and stays unresolved',
        () {
      final diagnostics = <CharacterAnimationSourceDiagnostic>[];
      final resolver = CharacterAnimationSourceResolver(
        onDiagnostic: diagnostics.add,
      );
      const animation = CharacterAnimation(
        state: CharacterAnimationState.run,
        direction: EntityFacing.north,
        sourceAssetId: 'hero_run',
      );
      const frame = CharacterAnimationFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 24, height: 32),
      );

      for (var index = 0; index < 2; index++) {
        expect(
          resolver.resolveFrame(
            character: character,
            animation: animation,
            frame: frame,
            tileWidth: 16,
            tileHeight: 16,
            availableImageIds: const <String>{'hero_legacy'},
          ),
          isNull,
        );
      }

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.code,
        CharacterAnimationSourceDiagnosticCode.dedicatedSourceUnavailable,
      );
      expect(diagnostics.single.sourceAssetId, 'hero_run');
    });
  });

  test('dedicated animation assets are preloaded from the portable store', () {
    final root = Directory.systemTemp.createTempSync('character_source_test_');
    addTearDown(() => root.deleteSync(recursive: true));
    final artifact = ContentArtifactRef.fromBytes(
      const <int>[1, 2, 3],
      mediaType: 'image/png',
    );
    final relativeBlob = assetBlobStorageKey(artifact);
    final blob = File('${root.path}/$relativeBlob')
      ..createSync(recursive: true);
    blob.writeAsBytesSync(const <int>[1, 2, 3]);
    final catalog = AssetCatalog(
      records: <AssetRecord>[
        AssetRecord(
          id: 'hero_walk',
          logicalPath: 'characters/hero_walk.png',
          artifact: artifact,
        ),
      ],
    );
    const manifest = ProjectManifest(
      name: 'Character source preload',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      characters: <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'hero',
          name: 'Hero',
          tilesetId: 'hero_legacy',
          animations: <CharacterAnimation>[
            CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: EntityFacing.south,
              sourceAssetId: 'hero_walk',
            ),
          ],
        ),
      ],
    );

    final plan = buildCharacterAnimationSourcePreloadPlan(
      manifest: manifest,
      projectRootDirectory: root.path,
      assetCatalog: catalog,
    );

    expect(plan.absolutePathsByAssetId, <String, String>{
      'hero_walk': blob.path,
    });
    expect(plan.diagnostics, isEmpty);
  });

  test('runtime bundle keeps dedicated animation paths separate', () async {
    final root = await Directory.systemTemp.createTemp('character_bundle_');
    addTearDown(() => root.delete(recursive: true));
    final artifact = ContentArtifactRef.fromBytes(
      const <int>[7, 8, 9],
      mediaType: 'image/png',
    );
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(const <int>[7, 8, 9]);
    final catalog = AssetCatalog(
      records: <AssetRecord>[
        AssetRecord(
          id: 'hero_walk',
          logicalPath: 'characters/hero_walk.png',
          artifact: artifact,
        ),
      ],
    );
    final catalogFile = File('${root.path}/$assetCatalogStorageKey');
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
    final mapFile = File('${root.path}/maps/start.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(
      jsonEncode(
        const MapData(
          id: 'start',
          name: 'Start',
          size: GridSize(width: 2, height: 2),
        ).toJson(),
      ),
    );
    const manifest = ProjectManifest(
      name: 'Character source bundle',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'start',
          name: 'Start',
          relativePath: 'maps/start.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
      characters: <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'hero',
          name: 'Hero',
          tilesetId: 'hero_legacy',
          animations: <CharacterAnimation>[
            CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: EntityFacing.south,
              sourceAssetId: 'hero_walk',
            ),
          ],
        ),
      ],
    );

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '${root.path}/project.json',
      mapId: 'start',
      preloadedManifest: manifest,
      additionalCharacterIds: const {'hero'},
    );

    expect(bundle.tilesetAbsolutePathsById, isEmpty);
    expect(bundle.characterAnimationAbsolutePathsByAssetId, <String, String>{
      'hero_walk': blob.path,
    });
    expect(bundle.runtimeImageAbsolutePathsById, <String, String>{
      characterAnimationRuntimeImageId('hero_walk'): blob.path,
    });
  });

  test('runtime image namespace prevents tileset and source id collisions', () {
    final bundle = RuntimeMapBundle(
      manifest: const ProjectManifest(
        name: 'Collision',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
      map: const MapData(
        id: 'start',
        name: 'Start',
        size: GridSize(width: 1, height: 1),
      ),
      projectRootDirectory: '/project',
      tilesetAbsolutePathsById: const <String, String>{
        'shared': '/project/tileset.png',
      },
      characterAnimationAbsolutePathsByAssetId: const <String, String>{
        'shared': '/project/animation.png',
      },
    );

    expect(bundle.runtimeImageAbsolutePathsById, <String, String>{
      'shared': '/project/tileset.png',
      characterAnimationRuntimeImageId('shared'): '/project/animation.png',
    });
  });
}
