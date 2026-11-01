import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'battle_live_attachment.dart';
import 'battle_particle_synthetic_component.dart';

final class BattleVerifiedParticleLoader {
  BattleVerifiedParticleLoader(this._bundle);

  final InspectedBattleRecipeBundle _bundle;
  bool _cancelled = false;
  bool _started = false;

  void cancel() {
    _cancelled = true;
  }

  void _checkActive() {
    if (_cancelled) throw StateError('Particle loading cancelled');
  }

  Future<BattleParticleSyntheticComponent> create(
    String particleId, {
    required List<ui.Offset> centers,
    List<BattleLivePointResolver>? centerResolvers,
    void Function()? onComplete,
    void Function()? onInvalidated,
  }) async {
    if (_started) throw StateError('Particle loader already used');
    _started = true;
    _checkActive();
    final definitions = _bundle.recipe.readVerifiedParticleDefinitions(
      _bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    final definition = definitions[particleId];
    if (definition == null) throw const FormatException('Unknown particle');
    final ids = definition.emitters.map((e) => e.textureId).toSet();
    final textures = <String, ui.Image>{};
    try {
      for (final id in ids) {
        _checkActive();
        final codec = await ui.instantiateImageCodec(_bundle.media[id]!);
        try {
          _checkActive();
          final frame = await codec.getNextFrame();
          textures[id] = frame.image;
          _checkActive();
        } finally {
          codec.dispose();
        }
      }
      final maxDimension = textures.values.fold<int>(
        1,
        (value, image) =>
            [value, image.width, image.height].reduce((a, b) => a > b ? a : b),
      );
      final totalPixels = textures.values.fold<int>(
        0,
        (value, image) => value + image.width * image.height,
      );
      return BattleParticleSyntheticComponent(
        definition: definition,
        textures: textures,
        centers: centers,
        centerResolvers: centerResolvers,
        maxTextures: ids.length,
        maxDimension: maxDimension,
        maxTotalPixels: totalPixels,
        onComplete: onComplete,
        onInvalidated: onInvalidated,
      );
    } finally {
      for (final image in textures.values) {
        image.dispose();
      }
    }
  }
}
