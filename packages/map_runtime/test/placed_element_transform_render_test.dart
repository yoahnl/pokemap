import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'collision preparation evicts entries and never retains oversized normalization',
      () async {
    final original = _bundle(_instance);
    final elements = [
      for (var i = 0; i < 65; i++)
        original.manifest.elements.single.copyWith(
            id: 'p$i',
            collisionProfile:
                const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]))
    ];
    final component = MapLayersComponent(
        bundle: original.copyWith(
            manifest: original.manifest.copyWith(elements: elements),
            map: original.map.copyWith(placedElements: [
              for (final e in elements)
                _instance.copyWith(id: e.id, elementId: e.id)
            ])),
        tileImagesByTilesetId: const {},
        showCollisionOverlay: true);
    await _render(component.render);
    expect(component.debugCollisionPreparationCount, 65);
    expect(component.debugCollisionCacheEntries, 64);
    component.dispose();
    final oversized = original.manifest.elements.single.copyWith(
        collisionProfile: ElementCollisionProfile(
            collisionMask: ElementCollisionPixelMask(
                widthPx: 4,
                heightPx: 4,
                dataBase64: List.filled(800000, '_').join())));
    final fallback = MapLayersComponent(
        bundle: original.copyWith(
            manifest: original.manifest.copyWith(elements: [oversized])),
        tileImagesByTilesetId: const {},
        showCollisionOverlay: true);
    await _render(fallback.render);
    expect(fallback.debugCollisionCacheBytes, 0);
    expect(fallback.debugCollisionCacheEntries, 0);
    await _render(fallback.render);
    expect(fallback.debugCollisionPreparationCount, 2);
    fallback.dispose();
  });
  test('dense collision previews reuse two compact source preparations',
      () async {
    final original = _bundle(_instance);
    final mask = base64Encode(List<int>.filled(128 * 128 ~/ 8, 0x55));
    final element = original.manifest.elements.single.copyWith(
        collisionProfile: ElementCollisionProfile(
            collisionMask: ElementCollisionPixelMask(
                widthPx: 128, heightPx: 128, dataBase64: mask)));
    final other = element.copyWith(id: 'other');
    final component = MapLayersComponent(
        bundle: original.copyWith(
            manifest: original.manifest.copyWith(elements: [element, other]),
            map: original.map.copyWith(placedElements: [
              _instance,
              _instance.copyWith(
                  id: 'b', elementId: 'other', pos: const GridPos(x: 1, y: 0))
            ])),
        tileImagesByTilesetId: const {})
      ..showCollisionOverlay = true;
    for (var i = 0; i < 12; i++) {
      component.setPlacedElementPreview(_instance.copyWith(
          pixelSize: PixelSize(width: 2 + i, height: 3 + i),
          quarterTurns: i % 4,
          pixelOffset: PixelOffset(x: i % 4, y: 0)));
      await _render(component.render);
      expect(component.debugCollisionPreparationCount, 2);
      expect(component.debugCollisionCacheEntries, 2);
      expect(
          component.debugCollisionCacheBytes, lessThanOrEqualTo(1024 * 1024));
    }
    component.setPlacedElementPreview(null);
    await _render(component.render);
    expect(component.debugCollisionPreparationCount, 2);
    component.dispose();
    expect(component.debugCollisionCacheBytes, 0);
    expect(component.debugCollisionCacheEntries, 0);
  });
  test('missing primary atlas does not reserve an unmounted animation patch',
      () async {
    final image = await _image();
    addTearDown(image.dispose);
    final original = _bundle(_instance.copyWith(
        animation: const MapPlacedElementAnimation(
            enabled: true, mode: MapPlacedElementAnimationMode.loop)));
    final element = original.manifest.elements.single.copyWith(
        frames: const [
          TilesetVisualFrame(
              tilesetId: 'ts',
              source: TilesetSourceRect(x: 0, y: 0),
              durationMs: 100),
          TilesetVisualFrame(
              tilesetId: 'loaded',
              source: TilesetSourceRect(x: 0, y: 0),
              durationMs: 100),
        ],
        collisionProfile: ElementCollisionProfile(
            occlusionMask: ElementCollisionPixelMask(
                widthPx: 4,
                heightPx: 4,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: 4,
                    heightPx: 4,
                    solidPixels: List.filled(16, true)))));
    final bundle = original.copyWith(
        manifest: original.manifest.copyWith(elements: [element]));
    final images = {'loaded': image};
    final renderer = RuntimeAuthoringMapRenderer(
        bundle: bundle, images: images, includeCharacters: true);
    addTearDown(renderer.dispose);
    renderer.update(.11);
    expect(_alpha(await _render(renderer.paint), 0, 0), 255);
    images['ts'] = image;
    expect(_alpha(await _render(renderer.paint), 0, 0), 255);
    images.remove('ts');
    expect(_alpha(await _render(renderer.paint), 0, 0), 255);
  });
  test(
      'deferred occlusion preserves translucent visual order and overlapping owners',
      () async {
    final red = await _image();
    final green = await _image(color: 0xff00ff00);
    final blue = await _image(color: 0xff0000ff);
    addTearDown(red.dispose);
    addTearDown(green.dispose);
    addTearDown(blue.dispose);
    final original = _bundle(_instance);
    final mask = ElementCollisionProfile(
        occlusionMask: ElementCollisionPixelMask(
            widthPx: 4,
            heightPx: 4,
            dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                widthPx: 4, heightPx: 4, solidPixels: List.filled(16, true))));
    for (final secondOwner in [false, true]) {
      for (final blueOpacity in [1.0, .5]) {
        final elements = [
          original.manifest.elements.single
              .copyWith(id: 'green', tilesetId: 'green'),
          original.manifest.elements.single.copyWith(collisionProfile: mask),
          original.manifest.elements.single.copyWith(
              id: 'blue',
              tilesetId: 'blue',
              collisionProfile: secondOwner ? mask : null),
        ];
        final bundle = original.copyWith(
            manifest: original.manifest.copyWith(elements: elements),
            map: original.map.copyWith(placedElements: [
              _instance.copyWith(
                  id: 'green', elementId: 'green', visualOrder: 0),
              _instance.copyWith(opacity: .5, visualOrder: 1),
              _instance.copyWith(
                  id: 'blue',
                  elementId: 'blue',
                  opacity: blueOpacity,
                  visualOrder: 2,
                  pixelOffset: const PixelOffset(x: 1, y: 1)),
            ]));
        final images = {'ts': red, 'green': green, 'blue': blue};
        final renderer = RuntimeAuthoringMapRenderer(
            bundle: bundle, images: images, includeCharacters: true);
        final reference = RuntimeAuthoringMapRenderer(
            bundle: bundle.copyWith(
                manifest: bundle.manifest.copyWith(
                    elements: elements
                        .map((e) => e.copyWith(collisionProfile: null))
                        .toList())),
            images: images);
        expect(await _render(renderer.paint), await _render(reference.paint),
            reason: 'secondOwner=$secondOwner blueOpacity=$blueOpacity');
        renderer.dispose();
        reference.dispose();
      }
    }
  });
  test('occlusion honors hidden and translucent layers without painting twice',
      () async {
    final image = await _image();
    addTearDown(image.dispose);
    final original = _bundle(_instance);
    final element = original.manifest.elements.single.copyWith(
        collisionProfile: ElementCollisionProfile(
            occlusionMask: ElementCollisionPixelMask(
                widthPx: 4,
                heightPx: 4,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: 4,
                    heightPx: 4,
                    solidPixels: List.filled(16, true)))));
    for (final visible in [false, true]) {
      final bundle = original.copyWith(
          manifest: original.manifest.copyWith(elements: [element]),
          map: original.map.copyWith(layers: [
            original.map.layers.single.copyWith(isVisible: visible, opacity: .5)
          ]));
      final renderer = RuntimeAuthoringMapRenderer(
          bundle: bundle, images: {'ts': image}, includeCharacters: true);
      final pixels = await _render(renderer.paint);
      expect(_alpha(pixels, 0, 0), visible ? 128 : 0);
      renderer.dispose();
    }
  });
  test(
      'animated split owner keeps later decor in front after atlas offset changes',
      () async {
    final red = await _image(height: 8);
    final blue = await _image(color: 0xff0000ff);
    addTearDown(red.dispose);
    addTearDown(blue.dispose);
    final owner = _instance.copyWith(
        animation: const MapPlacedElementAnimation(
            enabled: true, mode: MapPlacedElementAnimationMode.loop));
    final original = _bundle(owner);
    final element = original.manifest.elements.single.copyWith(
        frames: const [
          TilesetVisualFrame(
              tilesetId: 'ts',
              source: TilesetSourceRect(x: 0, y: 0, height: 2),
              durationMs: 100),
          TilesetVisualFrame(
              tilesetId: 'shifted',
              source: TilesetSourceRect(x: 0, y: 0, height: 2),
              durationMs: 100),
        ],
        collisionProfile:
            const ElementCollisionProfile(cells: [GridPos(x: 0, y: 1)]));
    final bundle = original.copyWith(
        manifest: original.manifest.copyWith(elements: [
          element,
          original.manifest.elements.single
              .copyWith(id: 'blue', tilesetId: 'blue')
        ], tilesets: [
          ...original.manifest.tilesets,
          const ProjectTilesetEntry(
              id: 'shifted',
              name: 'Shifted',
              relativePath: 'shifted.png',
              source: ProjectRegularAtlasTilesetSource(
                  assetId: 'shifted',
                  pixelWidth: 4,
                  pixelHeight: 8,
                  tileWidth: 4,
                  tileHeight: 4,
                  pixelOffsetX: 5)),
        ]),
        map: original.map.copyWith(placedElements: [
          owner,
          _instance.copyWith(
              id: 'blue',
              elementId: 'blue',
              visualOrder: 1,
              pos: const GridPos(x: 1, y: 0),
              pixelOffset: const PixelOffset(x: 1, y: 0))
        ]));
    final renderer = RuntimeAuthoringMapRenderer(
        bundle: bundle, images: {'ts': red, 'shifted': red, 'blue': blue});
    addTearDown(renderer.dispose);
    var pixels = await _render(renderer.paint);
    expect(pixels[6 * 4 + 2], 255);
    renderer.update(.11);
    pixels = await _render(renderer.paint);
    expect(pixels[6 * 4 + 2], 255);
    expect(pixels[6 * 4], 0);
  });
  test('animated atlas offsets remain constant and participate in culling',
      () async {
    final image = await _image();
    addTearDown(image.dispose);
    final instance = _instance.copyWith(
        pixelOffset: const PixelOffset(x: 1, y: 1),
        pixelSize: const PixelSize(width: 3, height: 2),
        quarterTurns: 1,
        animation: const MapPlacedElementAnimation(
            enabled: true, mode: MapPlacedElementAnimationMode.loop));
    final original = _bundle(instance);
    final element = original.manifest.elements.single.copyWith(frames: const [
      TilesetVisualFrame(
          tilesetId: 'ts',
          source: TilesetSourceRect(x: 0, y: 0),
          durationMs: 100),
      TilesetVisualFrame(
          tilesetId: 'shifted',
          source: TilesetSourceRect(x: 0, y: 0),
          durationMs: 100),
    ]);
    final bundle = original.copyWith(
        manifest: original.manifest.copyWith(elements: [
      element
    ], tilesets: [
      ...original.manifest.tilesets,
      const ProjectTilesetEntry(
          id: 'shifted',
          name: 'Shifted',
          relativePath: 'shifted.png',
          source: ProjectRegularAtlasTilesetSource(
              assetId: 'shifted',
              pixelWidth: 4,
              pixelHeight: 4,
              tileWidth: 4,
              tileHeight: 4,
              pixelOffsetX: 5)),
    ]));
    final component = MapLayersComponent(
        bundle: bundle, tileImagesByTilesetId: {'ts': image, 'shifted': image})
      ..setVisibleLocalRect(const ui.Rect.fromLTWH(6, 1, 3, 2));
    addTearDown(component.dispose);
    var pixels = await _render(component.render);
    expect(_alpha(pixels, 6, 1), 0);
    component.update(.11);
    pixels = await _render(component.render);
    expect(_alpha(pixels, 6, 1), 255);
    expect(_alpha(pixels, 8, 2), 255);
    expect(_alpha(pixels, 9, 2), 0);
  });
  test('preview occlusion changes actor depth and cancellation restores it',
      () async {
    final propImage = await _image();
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 16, 32),
        ui.Paint()..color = const ui.Color(0xff00ff00));
    final picture = recorder.endRecording();
    final actorImage = await picture.toImage(16, 32);
    picture.dispose();
    final actor = RuntimeTilesetImage.borrowed(actorImage);
    addTearDown(propImage.dispose);
    addTearDown(actorImage.dispose);
    final instance =
        _instance.copyWith(pixelSize: const PixelSize(width: 4, height: 6));
    final original = _bundle(instance);
    final element = original.manifest.elements.single.copyWith(
        collisionProfile: ElementCollisionProfile(
            occlusionMask: ElementCollisionPixelMask(
                widthPx: 4,
                heightPx: 4,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: 4,
                    heightPx: 4,
                    solidPixels: List.filled(16, true)))));
    final bundle = original.copyWith(
        manifest: original.manifest.copyWith(elements: [
          element
        ], characters: const [
          ProjectCharacterEntry(
              id: 'npc',
              name: 'Npc',
              tilesetId: 'npc',
              frameWidth: 2,
              frameHeight: 2,
              animations: [
                CharacterAnimation(
                    state: CharacterAnimationState.idle,
                    direction: EntityFacing.south,
                    frames: [
                      CharacterAnimationFrame(
                          source: TilesetSourceRect(x: 0, y: 0))
                    ])
              ])
        ]),
        map: original.map.copyWith(layers: [
          original.map.layers.single.copyWith(opacity: .5)
        ], entities: const [
          MapEntity(
              id: 'npc',
              name: 'Npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 0, y: 1),
              size: GridSize(width: 1, height: 1),
              npc: MapEntityNpcData(characterId: 'npc'))
        ]));
    final renderer = RuntimeAuthoringMapRenderer(
        bundle: bundle,
        images: {'ts': propImage, 'npc': actor},
        includeCharacters: true);
    addTearDown(renderer.dispose);
    var pixels = await _render(renderer.paint);
    expect(pixels[(4 * 16) * 4 + 1], 255);
    renderer.setPlacedElementPreview(
        instance.copyWith(pos: const GridPos(x: 0, y: 1)));
    pixels = await _render(renderer.paint);
    final referenceRenderer = RuntimeAuthoringMapRenderer(
        bundle: bundle.copyWith(
            manifest: bundle.manifest
                .copyWith(elements: [element.copyWith(collisionProfile: null)]),
            map: bundle.map.copyWith(layers: [
              bundle.map.layers.single.copyWith(name: 'Foreground')
            ], placedElements: [
              instance.copyWith(pos: const GridPos(x: 0, y: 1))
            ])),
        images: {'ts': propImage, 'npc': actor},
        includeCharacters: true);
    final reference = await _render(referenceRenderer.paint);
    referenceRenderer.dispose();
    expect(pixels.sublist((4 * 16) * 4, (4 * 16) * 4 + 4),
        reference.sublist((4 * 16) * 4, (4 * 16) * 4 + 4));
    renderer.clearPlacedElementPreview();
    pixels = await _render(renderer.paint);
    expect(pixels[(4 * 16) * 4 + 1], 255);
  });
  test('shadow metrics and occlusion patch follow pixel geometry', () {
    final instance = _instance.copyWith(
        pixelOffset: const PixelOffset(x: 3, y: 1),
        pixelSize: const PixelSize(width: 7, height: 5));
    final original = _bundle(instance);
    final element = original.manifest.elements.single.copyWith(
        collisionProfile: ElementCollisionProfile(
            occlusionMask: ElementCollisionPixelMask(
                widthPx: 4,
                heightPx: 4,
                dataBase64: ElementCollisionMaskCodec.encodePackedBits(
                    widthPx: 4,
                    heightPx: 4,
                    solidPixels: List.filled(16, true)))));
    final bundle = RuntimeMapBundle(
        manifest: original.manifest.copyWith(elements: [element]),
        map: original.map,
        projectRootDirectory: '.',
        tilesetAbsolutePathsById: const {});
    final shadow = buildRuntimeStaticPlacedElementShadowSources(bundle: bundle)
        .single
        .metrics;
    expect([
      shadow.worldLeft,
      shadow.worldTop,
      shadow.visualWidth,
      shadow.visualHeight
    ], [
      3,
      1,
      7,
      5
    ]);
    final patch = resolveStaticPlacedElementOcclusionPatchInstructions(
            bundle: bundle, originCellX: 0, originCellY: 0)
        .single;
    expect([
      patch.worldLeft,
      patch.worldTop,
      patch.visualWidth,
      patch.visualHeight
    ], [
      3,
      1,
      7,
      5
    ]);
    expect([patch.destinationWidthPx, patch.destinationHeightPx], [7, 5]);
  });
  test('custom geometry paints and culls its translated visual bounds',
      () async {
    final image = await _image();
    addTearDown(image.dispose);
    final instance = _instance.copyWith(
        pixelOffset: const PixelOffset(x: 3, y: 1),
        pixelSize: const PixelSize(width: 3, height: 2));
    final component = MapLayersComponent(
        bundle: _bundle(instance), tileImagesByTilesetId: {'ts': image})
      ..setVisibleLocalRect(const ui.Rect.fromLTWH(5, 1, 1, 1));
    final rendered = await _render(component.render);
    expect(_alpha(rendered, 5, 1), 255);
    expect(_alpha(rendered, 2, 1), 0);
    expect(_alpha(rendered, 6, 1), 0);
    expect(_alpha(rendered, 5, 3), 0);
  });
  test('preview hides original and cancel restores original with unchanged map',
      () async {
    final image = await _image();
    addTearDown(image.dispose);
    final bundle = _bundle(_instance);
    final renderer =
        RuntimeAuthoringMapRenderer(bundle: bundle, images: {'ts': image});
    addTearDown(renderer.dispose);
    renderer.setPlacedElementPreview(_instance.copyWith(
        pos: const GridPos(x: 1, y: 0),
        pixelOffset: const PixelOffset(x: 1, y: 0),
        pixelSize: const PixelSize(width: 2, height: 2)));
    var rendered = await _render(renderer.paint);
    expect(_alpha(rendered, 0, 0), 0);
    expect(_alpha(rendered, 5, 0), 255);
    expect(bundle.map.placedElements.single, _instance);
    renderer.clearPlacedElementPreview();
    rendered = await _render(renderer.paint);
    expect(_alpha(rendered, 0, 0), 255);
    expect(_alpha(rendered, 5, 0), 0);
  });
  test('translation reuses local plans and dispose releases their budget',
      () async {
    final image = await _image();
    addTearDown(image.dispose);
    final instance =
        _instance.copyWith(pixelSize: const PixelSize(width: 3, height: 2));
    final component = MapLayersComponent(
        bundle: _bundle(instance), tileImagesByTilesetId: {'ts': image});
    await _render(component.render);
    final recorded = component.debugPlacedElementPlanPreparationCount;
    expect(recorded, 1);
    component.setPlacedElementPreview(
        instance.copyWith(pos: const GridPos(x: 1, y: 0)));
    await _render(component.render);
    expect(component.debugPlacedElementPlanPreparationCount, recorded);
    expect(component.debugPlacedElementPlanBytes, greaterThan(0));
    component.dispose();
    expect(component.debugPlacedElementPlanBytes, 0);
  });
}

const _instance = MapPlacedElement(
    id: 'a',
    layerId: 'decor',
    elementId: 'prop',
    pos: GridPos(x: 0, y: 0),
    properties: {
      pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
    });
RuntimeMapBundle _bundle(MapPlacedElement instance) => RuntimeMapBundle(
    manifest: const ProjectManifest(
        name: 'Test',
        maps: [],
        settings: ProjectSettings(tileWidth: 4, tileHeight: 4, displayScale: 1),
        tilesets: [
          ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png')
        ],
        elements: [
          ProjectElementEntry(
              id: 'prop',
              name: 'prop',
              tilesetId: 'ts',
              categoryId: 'cat',
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
              ])
        ]),
    map: MapData(
        id: 'map',
        name: 'map',
        size: const GridSize(width: 4, height: 4),
        layers: const [MapLayer.tile(id: 'decor', name: 'Decor', cells: [])],
        placedElements: [instance]),
    projectRootDirectory: '.',
    tilesetAbsolutePathsById: const {});
Future<RuntimeTilesetImage> _image(
    {int width = 4, int height = 4, int color = 0xffff0000}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..color = ui.Color(color));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return RuntimeTilesetImage(
      images: [image],
      chunks: [RuntimeTilesetChunk(top: 0, width: width, height: height)],
      width: width,
      height: height);
}

Future<List<int>> _render(void Function(ui.Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 16);
  picture.dispose();
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
      .buffer
      .asUint8List()
      .toList();
  image.dispose();
  return data;
}

int _alpha(List<int> pixels, int x, int y) => pixels[(y * 16 + x) * 4 + 3];
