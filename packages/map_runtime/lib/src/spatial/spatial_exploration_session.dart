import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:path/path.dart' as p;

import '../application/character_animation_source_resolver.dart';
import '../application/runtime_map_bundle.dart';

final class SpatialExplorationSession {
  SpatialExplorationSession._(
      this.bundle, this.character, this.movement, this._images, this._textures);
  final RuntimeMapBundle bundle;
  final ProjectCharacterEntry character;
  final SpatialMovementController movement;
  final Map<String, ui.Image> _images;
  final Map<String, SpatialActorTexture> _textures;
  final _resolver = CharacterAnimationSourceResolver();
  bool _disposed = false;
  static Future<SpatialExplorationSession> load(RuntimeMapBundle bundle) async {
    final scene = bundle.map.spatialScene;
    if (scene == null ||
        bundle.manifest.settings.dimension != ProjectDimension.threeD) {
      throw StateError('Une carte 3D est requise.');
    }
    final id = bundle.manifest.settings.defaultPlayerCharacterId;
    final character =
        bundle.manifest.characters.where((v) => v.id == id).firstOrNull;
    if (character == null || character.animations.isEmpty) {
      throw StateError(
          'Choisissez un héros animé dans les réglages du projet.');
    }
    for (final direction in [
      EntityFacing.north,
      EntityFacing.south,
      EntityFacing.east,
      EntityFacing.west
    ]) {
      if (!character.animations.any((v) =>
          v.direction == direction &&
          v.state == CharacterAnimationState.walk &&
          v.frames.isNotEmpty)) {
        throw StateError('Animation de marche absente : ${direction.name}');
      }
    }
    final movement = SpatialMovementController(
        scene: scene, models: bundle.manifest.models3d);
    final images = <String, ui.Image>{},
        textures = <String, SpatialActorTexture>{};
    try {
      final paths = bundle.runtimeImageAbsolutePathsById;
      final ids = {
        for (final animation in character.animations)
          if (animation.sourceAssetId case final asset?
              when asset.trim().isNotEmpty)
            characterAnimationRuntimeImageId(asset)
          else
            character.tilesetId
      };
      for (final imageId in ids) {
        final path = paths[imageId];
        if (path == null) {
          throw StateError('Image du héros introuvable : $imageId');
        }
        final codec =
            await ui.instantiateImageCodec(await File(path).readAsBytes());
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        images[imageId] = image;
        textures[imageId] = await SpatialActorTexture.fromImage(image);
      }
      final session = SpatialExplorationSession._(
          bundle, character, movement, images, textures);
      for (final animation in character.animations) {
        if (animation.frames.isEmpty) {
          throw StateError('Animation du héros vide.');
        }
        for (final frame in animation.frames) {
          final resolved = session._resolve(animation, frame);
          final image = images[resolved.imageId]!;
          final rect = resolved.sourceRect;
          if (frame.durationMs <= 0 ||
              rect.left < 0 ||
              rect.top < 0 ||
              rect.width <= 0 ||
              rect.height <= 0 ||
              rect.right > image.width ||
              rect.bottom > image.height) {
            throw StateError('Frame du héros invalide.');
          }
        }
      }
      session.frame(0);
      return session;
    } on Object {
      for (final image in images.values) {
        image.dispose();
      }
      rethrow;
    }
  }

  ResolvedCharacterAnimationFrameSource _resolve(
          CharacterAnimation animation, CharacterAnimationFrame frame) =>
      _resolver.resolveFrame(
          character: character,
          animation: animation,
          frame: frame,
          tileWidth: bundle.manifest.settings.tileWidth,
          tileHeight: bundle.manifest.settings.tileHeight,
          availableImageIds: _images.keys.toSet()) ??
      (throw StateError('Source d’animation du héros indisponible.'));
  SpatialActorVisual frame(double dt) {
    if (!_disposed) movement.update(dt);
    final state = movement.moving
        ? (movement.running
            ? CharacterAnimationState.run
            : CharacterAnimationState.walk)
        : CharacterAnimationState.idle;
    final animation = character.animations
            .where((v) => v.state == state && v.direction == movement.facing)
            .firstOrNull ??
        character.animations
            .where((v) =>
                v.state == CharacterAnimationState.walk &&
                v.direction == movement.facing)
            .firstOrNull;
    if (animation == null) {
      throw StateError(
          'Animation directionnelle du héros absente : ${movement.facing.name}');
    }
    final total =
        animation.frames.fold<int>(0, (sum, frame) => sum + frame.durationMs);
    var remaining = (movement.animationSeconds * 1000).floor();
    remaining =
        animation.loop ? remaining % total : remaining.clamp(0, total - 1);
    var selected = animation.frames.last;
    for (final frame in animation.frames) {
      if (remaining < frame.durationMs) {
        selected = frame;
        break;
      }
      remaining -= frame.durationMs;
    }
    final resolved = _resolve(animation, selected);
    return SpatialActorVisual(
        x: movement.x,
        y: movement.y,
        z: movement.z,
        texture: _textures[resolved.imageId]!,
        frame: resolved.sourceRect);
  }

  Future<List<int>> modelBytes(String id) async {
    final model = bundle.manifest.models3d.where((v) => v.id == id).firstOrNull;
    if (model == null) throw StateError('Modèle absent : $id');
    return File(p.join(bundle.projectRootDirectory, model.relativePath))
        .readAsBytes();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    movement.setPaused(true);
    for (final image in _images.values) {
      image.dispose();
    }
  }
}
