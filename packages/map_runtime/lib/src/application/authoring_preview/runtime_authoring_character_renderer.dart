import 'dart:ui';
import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import '../../presentation/flame/overworld_actor_component.dart';

final class RuntimeAuthoringCharacterRenderer {
  RuntimeAuthoringCharacterRenderer({
    required ProjectCharacterEntry character,
    required ProjectSettings settings,
    required Map<String, RuntimeTilesetImage> images,
    EntityFacing facing = EntityFacing.south,
    CharacterAnimationState animationState = CharacterAnimationState.idle,
    int elapsedMs = 0,
    CharacterCustomAnimationClip? customAnimation,
  }) : _actor = OverworldActorComponent(
          character: character,
          tileImages: images,
          tileWidth: settings.tileWidth,
          tileHeight: settings.tileHeight,
          cellWidth: (settings.tileWidth * settings.displayScale).toDouble(),
          cellHeight: (settings.tileHeight * settings.displayScale).toDouble(),
          facing: facing,
          animState: animationState,
        ) {
    if (customAnimation != null) {
      if (_actor.canPlayCustomAnimation(customAnimation)) {
        _actor.playCustomAnimation(customAnimation);
      } else {
        _customVisualUnavailable = true;
      }
    }
    if (elapsedMs > 0) _actor.update(elapsedMs / 1000);
  }

  final OverworldActorComponent _actor;
  bool _customVisualUnavailable = false;

  bool get hasVisual {
    if (_customVisualUnavailable) return false;
    final source = _actor.debugAnimationSource;
    return source != null &&
        (_actor.tileImages[source.imageId]
                ?.containsSourceRect(source.sourceRect) ??
            false);
  }

  void paintInstance(Canvas canvas, MapEntity entity) {
    if (!hasVisual) return;
    _actor.configureGridPlacement(
      pos: entity.pos,
      footprint: entity.size,
      mapOrigin: Vector2.zero(),
    );
    canvas.save();
    canvas.translate(_actor.position.x, _actor.position.y);
    _actor.render(canvas);
    canvas.restore();
  }

  void paintThumbnail(Canvas canvas, Rect destination) {
    if (!hasVisual) return;
    final scale =
        destination.width / _actor.size.x < destination.height / _actor.size.y
            ? destination.width / _actor.size.x
            : destination.height / _actor.size.y;
    canvas.save();
    canvas.translate(destination.center.dx - _actor.size.x * scale / 2,
        destination.center.dy - _actor.size.y * scale / 2);
    canvas.scale(scale);
    _actor.render(canvas);
    canvas.restore();
  }
}
