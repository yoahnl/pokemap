import 'dart:ui';

import '../../infrastructure/runtime_tileset_image.dart';
import '../../presentation/flame/map_layers_component.dart';
import '../../shadow/runtime_static_placed_element_shadow_sources.dart';
import '../runtime_map_bundle.dart';

final class RuntimeAuthoringMapRenderer {
  RuntimeAuthoringMapRenderer({
    required RuntimeMapBundle bundle,
    required Map<String, RuntimeTilesetImage> images,
  })  : _background = MapLayersComponent(
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

  void update(double seconds) {
    _background.update(seconds);
    _foreground.update(seconds);
  }

  void paint(Canvas canvas, {Rect? viewport}) {
    _background.setVisibleLocalRect(viewport);
    _foreground.setVisibleLocalRect(viewport);
    _background.render(canvas);
    _foreground.render(canvas);
  }
}
