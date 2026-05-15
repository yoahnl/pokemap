import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

void main() {
  group('static placed element occlusion patch resolution', () {
    test('resolves static placed element occlusion patch instruction', () {
      final mask = _mask(widthPx: 32, heightPx: 16, solidPixels: {0, 17});
      final bundle = _bundle(
        placedElements: [
          _placedElement(
            pos: const GridPos(x: 5, y: 7),
            opacity: 0.75,
          ),
        ],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'frame_tileset',
                source: TilesetSourceRect(x: 3, y: 4, width: 2, height: 1),
              ),
            ],
            occlusionMask: mask,
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(instruction.mapId, 'map_1');
      expect(instruction.placedElementId, 'placed_1');
      expect(instruction.elementId, 'house');
      expect(instruction.layerId, 'decor');
      expect(instruction.tilesetId, 'frame_tileset');
      expect(instruction.sourceLeftPx, 48);
      expect(instruction.sourceTopPx, 64);
      expect(instruction.sourceWidthPx, 32);
      expect(instruction.sourceHeightPx, 16);
      expect(instruction.worldLeft, 80);
      expect(instruction.worldTop, 112);
      expect(instruction.visualWidth, 32);
      expect(instruction.visualHeight, 16);
      expect(instruction.depthSortY, 128);
      expect(instruction.flamePriority, 1128);
      expect(instruction.opacity, 0.75);
      expect(instruction.occlusionMask, same(mask));
    });

    test('applies connected map origin to world coordinates', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(pos: const GridPos(x: 2, y: 4)),
        ],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instruction = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 10,
        originCellY: -3,
      ).single;

      expect(instruction.worldLeft, 192);
      expect(instruction.worldTop, 16);
      expect(instruction.depthSortY, 32);
      expect(instruction.flamePriority, 1032);
    });

    test('skips elements without occlusionMask', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [_projectElement()],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips empty occlusionMask', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            occlusionMask: _mask(solidPixels: const {}),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips placed elements with unknown elementId', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(elementId: 'missing_element'),
        ],
        elements: [
          _projectElement(occlusionMask: _mask()),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips animated placed elements in V0', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(
            animation: const MapPlacedElementAnimation(
              enabled: true,
              mode: MapPlacedElementAnimationMode.loop,
            ),
          ),
        ],
        elements: [
          _projectElement(occlusionMask: _mask()),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips multi-frame elements in V0', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('resolves occlusion even when applyCollision is false', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(applyCollision: false),
        ],
        elements: [
          _projectElement(occlusionMask: _mask()),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, hasLength(1));
    });

    test('uses frame tilesetId override before element tilesetId', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            tilesetId: 'element_tileset',
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'override_tileset',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instruction = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ).single;

      expect(instruction.tilesetId, 'override_tileset');
    });

    test('falls back to element tilesetId when frame tilesetId is empty', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            tilesetId: 'element_tileset',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instruction = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ).single;

      expect(instruction.tilesetId, 'element_tileset');
    });

    test('skips occlusionMask with dimensions not matching visual source size',
        () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
              ),
            ],
            occlusionMask: _mask(widthPx: 16, heightPx: 16),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips invalid occlusionMask payloads', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            occlusionMask: const ElementCollisionPixelMask(
              widthPx: 16,
              heightPx: 16,
              dataBase64: 'not-valid-base64',
            ),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });
  });
}

RuntimeMapBundle _bundle({
  required List<MapPlacedElement> placedElements,
  required List<ProjectElementEntry> elements,
  ProjectSettings settings = const ProjectSettings(
    tileWidth: 16,
    tileHeight: 16,
    displayScale: 1,
  ),
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Occlusion Patch Test Project',
      surfaceCatalog: ProjectSurfaceCatalog(),
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'element_tileset',
          name: 'Element Tileset',
          relativePath: 'tilesets/elements.png',
        ),
        ProjectTilesetEntry(
          id: 'frame_tileset',
          name: 'Frame Tileset',
          relativePath: 'tilesets/frame.png',
        ),
        ProjectTilesetEntry(
          id: 'override_tileset',
          name: 'Override Tileset',
          relativePath: 'tilesets/override.png',
        ),
      ],
      settings: settings,
      elements: elements,
    ),
    map: MapData(
      id: 'map_1',
      name: 'Map 1',
      size: const GridSize(width: 20, height: 20),
      layers: const [],
      placedElements: placedElements,
    ),
    projectRootDirectory: '/tmp/occlusion_patch_test',
    tilesetAbsolutePathsById: const {},
  );
}

MapPlacedElement _placedElement({
  String id = 'placed_1',
  String layerId = 'decor',
  String elementId = 'house',
  GridPos pos = const GridPos(x: 0, y: 0),
  bool applyCollision = true,
  double opacity = 1,
  MapPlacedElementAnimation? animation,
}) {
  return MapPlacedElement(
    id: id,
    layerId: layerId,
    elementId: elementId,
    pos: pos,
    applyCollision: applyCollision,
    opacity: opacity,
    animation: animation,
  );
}

ProjectElementEntry _projectElement({
  String id = 'house',
  String tilesetId = 'element_tileset',
  List<TilesetVisualFrame> frames = const [
    TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
  ],
  ElementCollisionPixelMask? occlusionMask,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: tilesetId,
    categoryId: 'buildings',
    frames: frames,
    collisionProfile: occlusionMask == null
        ? null
        : ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            occlusionMask: occlusionMask,
          ),
  );
}

ElementCollisionPixelMask _mask({
  int widthPx = 16,
  int heightPx = 16,
  Set<int> solidPixels = const {0},
}) {
  final bits = List<bool>.filled(widthPx * heightPx, false);
  for (final index in solidPixels) {
    if (index >= 0 && index < bits.length) {
      bits[index] = true;
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: bits,
    ),
  );
}
