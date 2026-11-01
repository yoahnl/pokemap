import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'battle_spl_camera_projection.dart';
import 'battle_spl_static_admission.dart';
import 'battle_spl_static_component.dart';

final class BattleVerifiedSplPreparation {
  const BattleVerifiedSplPreparation._({this.component, this.failure});

  final BattleSplStaticComponent? component;
  final BattleSplAdmissionFailure? failure;
}

final class BattleVerifiedSplLoader {
  BattleVerifiedSplLoader(this._bundle);

  final InspectedBattleRecipeBundle _bundle;
  bool _cancelled = false;
  bool _started = false;

  void cancel() => _cancelled = true;

  void _checkActive() {
    if (_cancelled) throw StateError('SPL loading cancelled');
  }

  Future<BattleVerifiedSplPreparation> create(
    String particleId, {
    required List<BattleSplStaticEmitter> emitters,
    required int seed,
    required int poolCapacity,
    required int maxTicks,
    required ui.Offset origin,
    required double pixelsPerUnit,
    BattleSplCameraProjection? projection,
    required void Function() onComplete,
    required void Function(BattleSplAdmissionFailure) onFailure,
  }) async {
    if (_started) throw StateError('SPL loader already used');
    _started = true;
    _checkActive();
    final definitions = _bundle.recipe.readVerifiedSplParticleDefinitions(
      _bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    final definition = definitions[particleId];
    if (definition == null) throw const FormatException('Unknown SPL particle');
    if (projection == null ||
        projection.bindings.length != emitters.length ||
        projection.capture() == null) {
      return const BattleVerifiedSplPreparation._(
        failure: BattleSplAdmissionFailure.projectionUnavailable,
      );
    }
    final ids = definition.textureIds.toList()..sort();
    final textureIndices = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    final admitted = BattleSplStaticAdmission.prepare(
      definition: definition,
      textureIndices: textureIndices,
      emitters: emitters,
      seed: seed,
      poolCapacity: poolCapacity,
      maxTicks: maxTicks,
    );
    if (admitted.failure != null) {
      return BattleVerifiedSplPreparation._(failure: admitted.failure);
    }
    final playback = admitted.playback!;
    final textures = <int, ui.Image>{};
    var handedOff = false;
    try {
      var totalPixels = 0;
      var totalBytes = 0;
      for (final id in ids) {
        final bytes = _bundle.media[id]!;
        totalBytes += bytes.length;
        final dimensions = decodeRasterImageDimensions(
          bytes,
          mediaType: 'image/png',
        );
        if (dimensions == null) {
          throw const FormatException('Invalid SPL texture');
        }
        final pixels = dimensions.width * dimensions.height;
        totalPixels += pixels;
        if (bytes.length > 8 * 1024 * 1024 ||
            totalBytes > 64 * 1024 * 1024 ||
            dimensions.width < 1 ||
            dimensions.height < 1 ||
            dimensions.width > 2048 ||
            dimensions.height > 2048 ||
            pixels > 4000000 ||
            totalPixels > 16000000) {
          return const BattleVerifiedSplPreparation._(
            failure: BattleSplAdmissionFailure.workLimit,
          );
        }
      }
      for (final id in ids) {
        _checkActive();
        ui.Codec codec;
        try {
          codec = await ui.instantiateImageCodec(_bundle.media[id]!);
        } on Exception {
          return const BattleVerifiedSplPreparation._(
            failure: BattleSplAdmissionFailure.textureUnavailable,
          );
        }
        try {
          _checkActive();
          ui.FrameInfo frame;
          try {
            frame = await codec.getNextFrame();
          } on Exception {
            return const BattleVerifiedSplPreparation._(
              failure: BattleSplAdmissionFailure.textureUnavailable,
            );
          }
          textures[textureIndices[id]!] = frame.image;
          _checkActive();
        } finally {
          codec.dispose();
        }
      }
      _checkActive();
      final anchors = projection.capture();
      if (anchors == null ||
          anchors.any((anchor) => projection.project(anchor) == null)) {
        return const BattleVerifiedSplPreparation._(
          failure: BattleSplAdmissionFailure.projectionUnavailable,
        );
      }
      final component = BattleSplStaticComponent(
        playback: playback,
        textures: textures,
        origin: origin,
        pixelsPerUnit: pixelsPerUnit,
        projection: projection,
        initialAnchors: anchors,
        onComplete: onComplete,
        onFailure: onFailure,
      );
      handedOff = true;
      return BattleVerifiedSplPreparation._(component: component);
    } finally {
      for (final image in textures.values) {
        image.dispose();
      }
      if (!handedOff) playback.cancel();
    }
  }
}
