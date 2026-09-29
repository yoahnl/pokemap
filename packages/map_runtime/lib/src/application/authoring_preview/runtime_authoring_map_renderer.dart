import 'dart:ui';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';
import '../../border/border_runtime_asset_cache.dart';
import '../../presentation/flame/map_layers_component.dart';
import '../../presentation/flame/placed_element_occlusion_patch_component.dart';
import '../../presentation/flame/static_placed_element_occlusion_patch_resolution.dart';
import '../../shadow/runtime_static_placed_element_shadow_sources.dart';
import '../../shadow/runtime_projected_building_shadow_collection.dart';
import '../../shadow/shadow_runtime_instruction_collection.dart';
import '../runtime_map_bundle.dart';
import 'runtime_authoring_character_renderer.dart';

final class RuntimeAuthoringMapRenderer {
  RuntimeAuthoringMapRenderer({
    required RuntimeMapBundle bundle,
    required Map<String, RuntimeTilesetImage> images,
    BorderRuntimeAssetBundle? borderAssets,
    bool includeCharacters = false,
  })  : _bundle = bundle,
        _images = images,
        _includeCharacters = includeCharacters,
        _background = MapLayersComponent(
          bundle: bundle,
          separatePlacedElementOcclusion: includeCharacters,
          tileImagesByTilesetId: images,
          borderAssets: borderAssets,
          renderBorders: borderAssets != null,
        ),
        _foreground = MapLayersComponent(
          bundle: bundle,
          separatePlacedElementOcclusion: includeCharacters,
          tileImagesByTilesetId: images,
          renderPass: MapLayerRenderPass.foreground,
        ) {
    _shadows = _buildShadows(bundle.map.placedElements);
    _background.shadowCollectionProvider = () => _shadows;
    _refreshPatches(bundle.map.placedElements);
    _previousImages = Map.of(images);
  }

  final MapLayersComponent _background;
  final MapLayersComponent _foreground;
  final RuntimeMapBundle _bundle;
  final Map<String, RuntimeTilesetImage> _images;
  final bool _includeCharacters;
  final Map<String, RuntimeAuthoringCharacterRenderer> _characters = {};
  Map<String, RuntimeTilesetImage> _previousImages = {};
  MapPlacedElement? _preview;
  late ShadowRuntimeInstructionCollection _shadows;
  ShadowRuntimeInstructionCollection? _previewBaseShadows;
  final Map<String, PlacedElementOcclusionPatchComponent> _patches = {};
  final _maskValidity = <ElementCollisionPixelMask, bool>{};
  Rect? _viewport;

  ShadowRuntimeInstructionCollection _buildShadows(
          Iterable<MapPlacedElement> instances) =>
      ShadowRuntimeInstructionCollection(instructions: [
        ...buildRuntimeStaticPlacedElementShadowCollectionForBundle(
                bundle: _bundle, instances: instances)
            .instructions,
        ...buildRuntimeProjectedBuildingShadowCollection(
                manifest: _bundle.manifest,
                mapData: _bundle.map,
                instances: instances)
            .instructions,
      ]);

  void _refreshPatches(Iterable<MapPlacedElement> instances) {
    if (!_includeCharacters) return;
    final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: _bundle,
        originCellX: 0,
        originCellY: 0,
        instances: instances,
        maskValidityCache: _maskValidity);
    for (final instruction in instructions) {
      if (!_background
          .usesPlacedElementOcclusionPatch(instruction.placedElementId)) {
        continue;
      }
      final image = _images[instruction.tilesetId];
      if (image == null) continue;
      final existing = _patches[instruction.placedElementId];
      if (existing != null && identical(existing.tilesetImage, image)) {
        existing.setInstruction(instruction);
      } else {
        existing?.onRemove();
        _patches[instruction.placedElementId] =
            PlacedElementOcclusionPatchComponent(
                instruction: instruction,
                tilesetImage: image,
                overlayReplacesPatch: true,
                visibleWorldRectProvider: () => _viewport ?? Rect.largest,
                visualWorldRectProvider: () =>
                    _background.displayedPlacedElementRect(
                        _preview?.id == instruction.placedElementId
                            ? _preview!
                            : _instancesById[instruction.placedElementId]!),
                frameProvider: () {
                  final instance = _preview?.id == instruction.placedElementId
                      ? _preview!
                      : _instancesById[instruction.placedElementId]!;
                  final frame =
                      _background.displayedPlacedElementFrame(instance);
                  if (frame == null) return null;
                  final tilesetId = frame.tilesetId.trim().isEmpty
                      ? instruction.tilesetId
                      : frame.tilesetId.trim();
                  final image = _images[tilesetId];
                  if (image == null) return null;
                  final settings = _bundle.manifest.settings;
                  return (
                    image: image,
                    sourceRect: Rect.fromLTWH(
                        (frame.source.x * settings.tileWidth).toDouble(),
                        (frame.source.y * settings.tileHeight).toDouble(),
                        (frame.source.width * settings.tileWidth).toDouble(),
                        (frame.source.height * settings.tileHeight).toDouble())
                  );
                },
                overlayPainter:
                    _background.placedElementOcclusionOverlayPainter(
                        instruction.placedElementId));
      }
      final path = _patches[instruction.placedElementId]!.localOcclusionPath;
      _background.setPlacedElementOcclusionPath(
          instruction.placedElementId, path);
      _foreground.setPlacedElementOcclusionPath(
          instruction.placedElementId, path);
    }
  }

  late final _definitions = {
    for (final character in _bundle.manifest.characters)
      character.id: character,
  };
  late final _instancesById = {
    for (final instance in _bundle.map.placedElements) instance.id: instance
  };
  late final _entities = _bundle.map.entities
      .where((entity) => entity.kind == MapEntityKind.npc)
      .toList()
    ..sort(
        (a, b) => (a.pos.y + a.size.height).compareTo(b.pos.y + b.size.height));

  void _refreshImages() {
    if (!_includeCharacters) return;
    if (_images.length != _previousImages.length ||
        _images.entries.any(
            (entry) => !identical(entry.value, _previousImages[entry.key]))) {
      _characters.clear();
      for (final patch in _patches.values) {
        _background.setPlacedElementOcclusionPath(
            patch.instruction.placedElementId, null);
        _foreground.setPlacedElementOcclusionPath(
            patch.instruction.placedElementId, null);
        patch.onRemove();
      }
      _patches.clear();
      _refreshPatches(_bundle.map.placedElements
          .map((e) => _preview?.id == e.id ? _preview! : e));
      _previousImages = Map.of(_images);
    }
  }

  void _paintCharacters(Canvas canvas) {
    if (!_includeCharacters) return;
    for (final patch in _patches.values) {
      patch.update(0);
    }
    final patches = _patches.values.toList()
      ..sort((a, b) =>
          (a.position.y + a.height).compareTo(b.position.y + b.height));
    var patchIndex = 0;
    void paintPatch(PlacedElementOcclusionPatchComponent patch) {
      canvas.save();
      canvas.translate(patch.position.x, patch.position.y);
      patch.render(canvas);
      canvas.restore();
    }

    for (final entity in _entities) {
      final depth = (entity.pos.y + entity.size.height) * _bundle.cellHeight;
      while (patchIndex < patches.length &&
          patches[patchIndex].position.y + patches[patchIndex].height < depth) {
        paintPatch(patches[patchIndex++]);
      }
      final character = _definitions[entity.npc?.characterId];
      if (character == null) continue;
      final renderer = _characters.putIfAbsent(
          entity.id,
          () => RuntimeAuthoringCharacterRenderer(
                character: character,
                settings: _bundle.manifest.settings,
                images: _images,
                facing: entity.npc?.facing ?? EntityFacing.south,
              ));
      renderer.paintInstance(canvas, entity);
    }
    while (patchIndex < patches.length) {
      paintPatch(patches[patchIndex++]);
    }
  }

  void update(double seconds) {
    _background.update(seconds);
    _foreground.update(seconds);
  }

  void paint(Canvas canvas, {Rect? viewport}) {
    _viewport = viewport;
    _refreshImages();
    _background.setVisibleLocalRect(viewport);
    _foreground.setVisibleLocalRect(viewport);
    _background.render(canvas);
    _paintCharacters(canvas);
    _foreground.render(canvas);
  }

  void setPlacedElementPreview(MapPlacedElement instance) {
    _background.setPlacedElementPreview(instance);
    _foreground.setPlacedElementPreview(instance);
    if (_preview?.id != instance.id) {
      if (_preview != null) {
        _refreshPatches(
            _bundle.map.placedElements.where((e) => e.id == _preview!.id));
      }
      _previewBaseShadows = _buildShadows(
          _bundle.map.placedElements.where((e) => e.id != instance.id));
    }
    _preview = instance;
    _shadows = ShadowRuntimeInstructionCollection(instructions: [
      ..._previewBaseShadows!.instructions,
      ..._buildShadows([instance]).instructions
    ]);
    _refreshPatches([instance]);
  }

  void clearPlacedElementPreview() {
    _background.setPlacedElementPreview(null);
    _foreground.setPlacedElementPreview(null);
    if (_preview != null) {
      _refreshPatches(
          _bundle.map.placedElements.where((e) => e.id == _preview!.id));
    }
    _preview = null;
    _previewBaseShadows = null;
    _shadows = _buildShadows(_bundle.map.placedElements);
  }

  void setCollisionOverlay({required bool visible, required Color color}) {
    _background.showCollisionOverlay = visible;
    _background.collisionOverlayColor = color;
  }

  void dispose() {
    _background.dispose();
    _foreground.dispose();
    _characters.clear();
    for (final patch in _patches.values) {
      patch.onRemove();
    }
    _patches.clear();
    _maskValidity.clear();
  }
}
