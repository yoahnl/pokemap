import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_asset_map_capture_service.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_map_renderer.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';
import 'package:map_runtime/src/border/border_runtime_preparation.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

import '../../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'captures authored NPC facing and sprite bounds without overlays',
    () async {
      final image = await runtimeTilesetImage(const [
        Color(0xFFFF0000),
        Color(0xFF0000FF),
      ]);
      addTearDown(image.dispose);
      final result = await _captureNpcMap(
        _npcBundle(facing: EntityFacing.east),
        {'character-animation:npc-media': image},
      );
      final bitmap = img.decodePng(result.bytes)!;

      expect(result.overlayCounts, isEmpty);
      expect(_pixel(bitmap, 16, 0), [0, 0, 255, 255]);
      expect(_pixel(bitmap, 79, 63), [0, 0, 255, 255]);
      expect(bitmap.getPixel(15, 16).a.toInt(), 0);
      expect(bitmap.getPixel(80, 16).a.toInt(), 0);
      expect(bitmap.getPixel(48, 64).a.toInt(), 0);
    },
  );

  for (final npcY in [0, 1, 2]) {
    test(
      'captures NPC depth against an occluding decor at row $npcY',
      () async {
        final npcImage = await runtimeTilesetImage(const [Color(0xFF0000FF)]);
        final decorImage = await _solidImage(
          const Color(0xFFFF0000),
          height: 64,
        );
        addTearDown(npcImage.dispose);
        addTearDown(decorImage.dispose);
        final base = _npcBundle(npcY: npcY);
        final bundle = base.copyWith(
          manifest: base.manifest.copyWith(
            elements: [
              ProjectElementEntry(
                id: 'occluder',
                name: 'Occluder',
                tilesetId: 'entity',
                categoryId: 'decor',
                frames: const [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
                  ),
                ],
                collisionProfile: ElementCollisionProfile(
                  occlusionMask: ElementCollisionPixelMask(
                    widthPx: 32,
                    heightPx: 64,
                    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                      widthPx: 32,
                      heightPx: 64,
                      solidPixels: List.filled(32 * 64, true),
                    ),
                  ),
                ),
              ),
            ],
          ),
          map: base.map.copyWith(
            placedElements: const [
              MapPlacedElement(
                id: 'occluder-instance',
                layerId: 'decor',
                elementId: 'occluder',
                pos: GridPos(x: 1, y: 0),
              ),
            ],
          ),
        );
        final result = await _captureNpcMap(bundle, {
          'character-animation:npc-media': npcImage,
          'entity': decorImage,
        });
        final bitmap = img.decodePng(result.bytes)!;
        final images = {
          'character-animation:npc-media': npcImage,
          'entity': decorImage,
        };
        final studio = RuntimeAuthoringMapRenderer(
          bundle: bundle,
          images: images,
          includeCharacters: true,
        )..update(0);
        addTearDown(studio.dispose);
        final studioPixels = await _renderPixels(studio.paint);
        final game = PlayableMapGame(
          bundle: bundle.copyWith(
            tilesetAbsolutePathsById: const {'entity': '/tmp/l17-decor.png'},
            characterAnimationAbsolutePathsByAssetId: const {
              'npc-media': '/tmp/l17-npc.png',
            },
          ),
          projectFilePath: '/tmp/l17-pixel-evidence/project.json',
          runtimeTilesetImageLoader:
              (paths, {transparentColorByTilesetId = const {}}) async => {
                for (final id in paths.keys)
                  if (images[id] != null) id: images[id]!,
              },
        );
        addTearDown(game.onRemove);
        game.onGameResize(Vector2(96, 96));
        await game.onLoad();
        game.update(0);
        game.update(0);
        game.camera.viewfinder
          ..position = Vector2(48, 48)
          ..zoom = 1;
        final actors = game.world.children
            .whereType<OverworldActorComponent>()
            .toList();
        final patches = game.world.children
            .whereType<PlacedElementOcclusionPatchComponent>()
            .toList();
        expect(actors, hasLength(1));
        expect(patches, hasLength(1));
        expect(
          actors.single.priority.compareTo(patches.single.priority),
          npcY.compareTo(1),
        );
        final playerPixels = await _renderPixels((canvas) {
          for (final child in game.world.children) {
            child.renderTree(canvas);
          }
        });
        final sampleY = npcY == 2 ? 48 : 16;
        final expected = npcY == 2 ? [0, 0, 255, 255] : [255, 0, 0, 255];
        await _saveEvidence('row-$npcY-capture', bitmap);
        await _saveEvidence('row-$npcY-studio', studioPixels);
        await _saveEvidence('row-$npcY-player-world', playerPixels);

        expect(_pixel(playerPixels, 48, sampleY), expected);
        expect(
          _pixel(studioPixels, 48, sampleY),
          _pixel(playerPixels, 48, sampleY),
        );
        expect(_pixel(bitmap, 48, sampleY), _pixel(playerPixels, 48, sampleY));
      },
    );
  }

  test(
    'preserves NPC pixels when cropping, scaling and selecting layers',
    () async {
      final npcImage = await runtimeTilesetImage(const [Color(0xFF0000FF)]);
      final decorImage = await runtimeTilesetImage(const [Color(0xFFFF0000)]);
      addTearDown(npcImage.dispose);
      addTearDown(decorImage.dispose);
      final base = _npcBundle();
      final bundle = base.copyWith(
        manifest: base.manifest.copyWith(
          tilesets: const [
            ProjectTilesetEntry(
              id: 'entity',
              name: 'Entity',
              relativePath: 'entity.png',
              source: ProjectRegularAtlasTilesetSource(
                assetId: 'entity',
                pixelWidth: 32,
                pixelHeight: 32,
                tileWidth: 32,
                tileHeight: 32,
              ),
            ),
          ],
        ),
        map: base.map.copyWith(
          layers: const [
            TileLayer(
              id: 'decor',
              name: 'Decor',
              cells: [0, 0, 0, 0, 0, 0, 0, 0, 0],
            ),
            TileLayer(
              id: 'hidden',
              name: 'Hidden',
              isVisible: false,
              cells: [1, 1, 1, 1, 1, 1, 1, 1, 1],
              palette: [
                TileLayerPaletteEntry(tilesetId: 'entity', localTileId: 0),
              ],
            ),
          ],
        ),
      );
      final result = await const RuntimeAuthoringAssetMapCaptureService()
          .capture(
            bundle: bundle,
            tileImagesByTilesetId: {
              'character-animation:npc-media': npcImage,
              'entity': decorImage,
            },
            region: const MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 2, height: 2),
            ),
            layerIds: const ['hidden'],
            overlays: const [],
            cellPixelSize: 8,
          );
      final bitmap = img.decodePng(result.bytes)!;

      expect(result.width, 16);
      expect(result.height, 16);
      expect(_pixel(bitmap, 4, 4), [0, 0, 255, 255]);
      expect(_pixel(bitmap, 11, 15), [0, 0, 255, 255]);
      expect(_pixel(bitmap, 13, 4), [255, 0, 0, 255]);
      final upper = await const RuntimeAuthoringAssetMapCaptureService().capture(
        bundle: bundle,
        tileImagesByTilesetId: {
          'character-animation:npc-media': npcImage,
          'entity': decorImage,
        },
        region: const MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 2, height: 1),
        ),
        layerIds: const [],
        overlays: const [],
        cellPixelSize: 8,
      );
      final upperPixels = img.decodePng(upper.bytes)!;
      expect(upper.width, 16);
      expect(upper.height, 8);
      expect(_pixel(upperPixels, 4, 4), [0, 0, 255, 255]);
      expect(upperPixels.getPixel(13, 4).a.toInt(), 0);
      await _saveEvidence('crop-selected-layer', bitmap);
      await _saveEvidence('crop-sprite-outside-footprint', upperPixels);
      expect(npcImage.debugDisposed, isFalse);
      expect(decorImage.debugDisposed, isFalse);
    },
  );

  test('paints entity overlay after the authored NPC sprite', () async {
    final image = await runtimeTilesetImage(const [Color(0xFF0000FF)]);
    addTearDown(image.dispose);
    final result = await _captureNpcMap(
      _npcBundle(),
      {'character-animation:npc-media': image},
      overlays: const [MapRenderOverlay.entities],
    );
    final bitmap = img.decodePng(result.bytes)!;

    expect(result.overlayCounts, {MapRenderOverlay.entities: 1});
    expect(_pixel(bitmap, 48, 16), [0, 0, 255, 255]);
    expect(_pixel(bitmap, 48, 48), [42, 188, 216, 255]);
  });

  for (final unavailable in [
    'unknown-character',
    'missing-image',
    'invalid-atlas',
  ]) {
    test('skips NPC visual for $unavailable without a placeholder', () async {
      final image = await runtimeTilesetImage(const [Color(0xFF0000FF)]);
      addTearDown(image.dispose);
      final base = _npcBundle();
      final bundle = unavailable == 'unknown-character'
          ? base.copyWith(manifest: base.manifest.copyWith(characters: []))
          : unavailable == 'invalid-atlas'
          ? base.copyWith(
              manifest: base.manifest.copyWith(
                characters: [
                  _captureCharacter.copyWith(
                    animations: const [
                      CharacterAnimation(
                        state: CharacterAnimationState.idle,
                        direction: EntityFacing.south,
                        sourceAssetId: 'npc-media',
                        frames: [
                          CharacterAnimationFrame(
                            source: TilesetSourceRect(
                              x: 32,
                              y: 0,
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          : base;
      final result = await _captureNpcMap(bundle, {
        if (unavailable != 'missing-image')
          'character-animation:npc-media': image,
      });
      final bitmap = img.decodePng(result.bytes)!;

      expect(bitmap.every((pixel) => pixel.a == 0), isTrue);
    });
  }

  test('rejects invalid capture bounds and non-positive scale', () async {
    final bundle = _npcBundle();
    for (final region in const [
      MapRect(pos: GridPos(x: -1, y: 0), size: GridSize(width: 1, height: 1)),
      MapRect(pos: GridPos(x: 2, y: 2), size: GridSize(width: 2, height: 1)),
      MapRect(pos: GridPos(x: 0, y: 0), size: GridSize(width: 0, height: 1)),
    ]) {
      await expectLater(
        const RuntimeAuthoringAssetMapCaptureService().capture(
          bundle: bundle,
          tileImagesByTilesetId: const {},
          region: region,
          layerIds: const [],
          overlays: const [],
          cellPixelSize: 32,
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      const RuntimeAuthoringAssetMapCaptureService().capture(
        bundle: bundle,
        tileImagesByTilesetId: const {},
        region: const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        layerIds: const [],
        overlays: const [],
        cellPixelSize: 0,
      ),
      throwsArgumentError,
    );
  });

  test('captures real placed-element pixels from the runtime renderer',
      () async {
    final result = await const RuntimeAuthoringAssetMapCaptureService().capture(
      bundle: surfaceTestBundle(
        map: const MapData(
          id: 'asset-capture',
          name: 'Asset capture',
          size: GridSize(width: 2, height: 1),
          layers: [
            MapLayer.tile(
              id: 'decor',
              name: 'Decor',
              cells: [0, 0],
            ),
          ],
          placedElements: [
            MapPlacedElement(
              id: 'tree-1',
              layerId: 'decor',
              elementId: 'tree',
              pos: GridPos(x: 0, y: 0),
            ),
          ],
        ),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'entity',
            categoryId: 'nature',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      ),
      tileImagesByTilesetId: {
        'entity': await runtimeTilesetImage(const [Color(0xFF29B34A)]),
      },
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 2, height: 1),
      ),
      layerIds: const [],
      overlays: const [],
      cellPixelSize: 32,
    );

    final bitmap = img.decodePng(result.bytes);

    expect(bitmap, isNotNull);
    expect(result.width, 64);
    expect(result.height, 32);
    final center = bitmap!.getPixel(16, 16);
    expect(
      [center.r.toInt(), center.g.toInt(), center.b.toInt(), center.a.toInt()],
      [41, 179, 74, 255],
    );
    expect(bitmap.getPixel(48, 16).a.toInt(), 0);
  });

  test('preserves canonical collision, zone, warp and entity overlays',
      () async {
    const map = MapData(
      id: 'overlay-capture',
      name: 'Overlay capture',
      size: GridSize(width: 3, height: 2),
      layers: [
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: [true, false, false, false, false, false],
        ),
      ],
      entities: [
        MapEntity(
          id: 'npc',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
        ),
      ],
      warps: [
        MapWarp(
          id: 'door',
          pos: GridPos(x: 2, y: 0),
          targetMapId: 'overlay-capture',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
      gameplayZones: [
        MapGameplayZone(
          id: 'zone',
          kind: GameplayZoneKind.custom,
          area: MapRect(
            pos: GridPos(x: 1, y: 0),
            size: GridSize(width: 1, height: 1),
          ),
          special: SpecialZonePayload(),
        ),
      ],
    );
    final result = await const RuntimeAuthoringAssetMapCaptureService().capture(
      bundle: surfaceTestBundle(map: map),
      tileImagesByTilesetId: const {},
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 3, height: 2),
      ),
      layerIds: const [],
      overlays: MapRenderOverlay.values,
      cellPixelSize: 4,
    );

    expect(result.overlayCounts, {
      MapRenderOverlay.collision: 1,
      MapRenderOverlay.zones: 1,
      MapRenderOverlay.warps: 1,
      MapRenderOverlay.entities: 1,
    });
  });

  test('loads prepared Border assets before capturing visible layers',
      () async {
    final root =
        await Directory.systemTemp.createTemp('pokemap-border-capture-');
    addTearDown(() => root.delete(recursive: true));
    const digest =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const snapshotId = 'border-snapshot-sha256:$digest';
    const relativePath = 'assets/borders/snapshots/$digest/frame_0000.png';
    final file = File('${root.path}/$relativePath');
    await file.parent.create(recursive: true);
    final frame = img.Image(width: 32, height: 32);
    img.fill(frame, color: img.ColorRgba8(255, 255, 0, 255));
    await file.writeAsBytes(img.encodePng(frame));

    final bundle = RuntimeMapBundle(
      manifest: ProjectManifest(
        name: 'Border capture',
        maps: const [],
        tilesets: const [],
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          displayScale: 1,
        ),
      ),
      map: MapData(
        id: 'border-capture',
        name: 'Border capture',
        size: const GridSize(width: 1, height: 1),
        layers: [_borderLayer(snapshotId)],
      ),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      borderRuntimePreparation: BorderRuntimePreparation(
        assetCollection: BorderRuntimeAssetCollection(
          snapshots: [
            BorderRuntimeSnapshotRequest(
              snapshotId: snapshotId,
              frames: [
                BorderRuntimeFrameRequest(
                  snapshotId: snapshotId,
                  frameIndex: 0,
                  relativeAssetPath: relativePath,
                  sourceRectPx: BorderPixelRect(
                    x: 0,
                    y: 0,
                    width: 32,
                    height: 32,
                  ),
                  durationMs: 100,
                  transparentColorArgb: null,
                ),
              ],
            ),
          ],
        ),
        snapshotIntegrity: const {},
        featureFreshness: const [],
      ),
    );

    final result = await const RuntimeAuthoringAssetMapCaptureService().capture(
      bundle: bundle,
      tileImagesByTilesetId: const {},
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 1, height: 1),
      ),
      layerIds: const [],
      overlays: const [],
      cellPixelSize: 32,
    );

    final bitmap = img.decodePng(result.bytes)!;
    final center = bitmap.getPixel(16, 16);
    expect(
      [center.r.toInt(), center.g.toInt(), center.b.toInt(), center.a.toInt()],
      [255, 255, 0, 255],
    );
  });
}

const _captureCharacter = ProjectCharacterEntry(
  id: 'capture-npc',
  name: 'Capture NPC',
  tilesetId: 'npc-atlas',
  frameWidth: 2,
  frameHeight: 2,
  animations: [
    CharacterAnimation(
      state: CharacterAnimationState.idle,
      direction: EntityFacing.south,
      sourceAssetId: 'npc-media',
      frames: [
        CharacterAnimationFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
        ),
      ],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.idle,
      direction: EntityFacing.east,
      sourceAssetId: 'npc-media',
      frames: [
        CharacterAnimationFrame(
          source: TilesetSourceRect(x: 32, y: 0, width: 32, height: 32),
        ),
      ],
    ),
  ],
);

RuntimeMapBundle _npcBundle({
  int npcY = 1,
  EntityFacing facing = EntityFacing.south,
}) {
  final bundle = surfaceTestBundle(
    map: MapData(
      id: 'npc-capture',
      name: 'NPC capture',
      size: const GridSize(width: 3, height: 3),
      layers: const [
        TileLayer(
          id: 'decor',
          name: 'Decor',
          cells: [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ],
      entities: [
        MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: npcY),
          npc: MapEntityNpcData(characterId: 'capture-npc', facing: facing),
        ),
      ],
    ),
  );
  return bundle.copyWith(
    manifest: bundle.manifest.copyWith(characters: [_captureCharacter]),
  );
}

Future<RuntimeAuthoringAssetMapCaptureResult> _captureNpcMap(
  RuntimeMapBundle bundle,
  Map<String, RuntimeTilesetImage> images, {
  List<MapRenderOverlay> overlays = const [],
}) => const RuntimeAuthoringAssetMapCaptureService().capture(
  bundle: bundle,
  tileImagesByTilesetId: images,
  region: const MapRect(
    pos: GridPos(x: 0, y: 0),
    size: GridSize(width: 3, height: 3),
  ),
  layerIds: const [],
  overlays: overlays,
  cellPixelSize: 32,
);

List<int> _pixel(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt()];
}

Future<RuntimeTilesetImage> _solidImage(
  Color color, {
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, 32, height.toDouble()),
    Paint()..color = color,
  );
  final picture = recorder.endRecording();
  try {
    return RuntimeTilesetImage(
      images: [await picture.toImage(32, height)],
      chunks: [RuntimeTilesetChunk(top: 0, height: height, width: 32)],
      width: 32,
      height: height,
    );
  } finally {
    picture.dispose();
  }
}

Future<img.Image> _renderPixels(void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(96, 96);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return img.decodePng(
        data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      )!;
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

Future<void> _saveEvidence(String name, img.Image image) async {
  final root = Platform.environment['POKEMAP_L17_EVIDENCE_DIR'];
  if (root == null || root.isEmpty) return;
  final directory = await Directory(root).create(recursive: true);
  await File('${directory.path}/$name.png').writeAsBytes(img.encodePng(image));
}

BorderLayer _borderLayer(String snapshotId) {
  const receiptHash =
      'sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
  return BorderLayer(
    id: 'border',
    name: 'Border',
    content: BorderLayerContent(
      features: [
        BorderFeature(
          id: 'border-feature',
          name: 'Border feature',
          blueprintId: 'border-blueprint',
          seed: BorderSignedInt64.zero,
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const [true],
          ),
          overrides: const [],
          keepOutRegions: const [],
          materialization: BorderMaterialization(
            receipt: BorderResolutionReceipt(
              resolverVersion: 1,
              blueprintRevision: 1,
              components: BorderInputFingerprints(
                blueprint: receiptHash,
                geometryAndSeed: receiptHash,
                parameters: receiptHash,
                overrides: receiptHash,
                keepOutRegions: receiptHash,
                mapContext: receiptHash,
                visualSnapshots: receiptHash,
              ),
              inputFingerprint: receiptHash,
              outputFingerprint: receiptHash,
            ),
            ground: [
              BorderResolvedGroundCell(
                x: 0,
                y: 0,
                visualSnapshotId: snapshotId,
                resolvedRole: BorderGroundVariantRole.isolated,
              ),
            ],
            placements: const [],
          ),
        ),
      ],
    ),
  );
}
