import 'dart:ui';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';
import '../../presentation/flame/map_layers_component.dart';
import '../../shadow/runtime_static_placed_element_shadow_sources.dart';
import '../runtime_map_bundle.dart';
import 'runtime_authoring_character_renderer.dart';

final class RuntimeAuthoringMapRenderer {
  RuntimeAuthoringMapRenderer({
    required RuntimeMapBundle bundle,
    required Map<String, RuntimeTilesetImage> images,
    bool includeCharacters = false,
  })  : _bundle = bundle,
        _images = images,
        _includeCharacters = includeCharacters,
        _background = MapLayersComponent(
          bundle: bundle,
          tileImagesByTilesetId: images,
          shadowCollectionProvider: () =>
              buildRuntimeStaticPlacedElementShadowCollectionForBundle(
            bundle: bundle,
          ),
        ),
        _foreground = MapLayersComponent(
          bundle: bundle,
          tileImagesByTilesetId: images,
          renderPass: MapLayerRenderPass.foreground,
        );

  final MapLayersComponent _background;
  final MapLayersComponent _foreground;
  final RuntimeMapBundle _bundle;
  final Map<String, RuntimeTilesetImage> _images;
  final bool _includeCharacters;
  final Map<String, RuntimeAuthoringCharacterRenderer> _characters = {};
  Map<String, RuntimeTilesetImage> _previousImages = {};
  late final _definitions = {
    for (final character in _bundle.manifest.characters)
      character.id: character,
  };
  late final _entities = _bundle.map.entities
      .where((entity) => entity.kind == MapEntityKind.npc)
      .toList()
    ..sort(
        (a, b) => (a.pos.y + a.size.height).compareTo(b.pos.y + b.size.height));

  void _paintCharacters(Canvas canvas) {
    if (!_includeCharacters) return;
    if (_images.length != _previousImages.length ||
        _images.entries.any(
            (entry) => !identical(entry.value, _previousImages[entry.key]))) {
      _characters.clear();
      _previousImages = Map.of(_images);
    }
    for (final entity in _entities) {
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
  }

  void update(double seconds) {
    _background.update(seconds);
    _foreground.update(seconds);
  }

  void paint(Canvas canvas, {Rect? viewport}) {
    _background.setVisibleLocalRect(viewport);
    _foreground.setVisibleLocalRect(viewport);
    _background.render(canvas);
    _paintCharacters(canvas);
    _foreground.render(canvas);
  }
}
