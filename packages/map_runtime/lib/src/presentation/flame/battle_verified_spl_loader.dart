import 'dart:async';
import 'dart:typed_data';
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
  }) => createGrouped(
    [particleId],
    emitters: emitters,
    seed: seed,
    poolCapacity: poolCapacity,
    maxTicks: maxTicks,
    origin: origin,
    pixelsPerUnit: pixelsPerUnit,
    projection: projection,
    onComplete: onComplete,
    onFailure: onFailure,
  );

  Future<BattleVerifiedSplPreparation> createGrouped(
    List<String> particleIds, {
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
    final idsToLoad = List<String>.unmodifiable(particleIds);
    if (idsToLoad.isEmpty || idsToLoad.length > 32) {
      throw const FormatException('Invalid SPL particle group');
    }
    final definitions = _bundle.recipe.readVerifiedSplParticleDefinitions(
      _bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    final selected = <BattleSplParticleDefinition>[];
    for (final id in idsToLoad) {
      final definition = definitions[id];
      if (definition == null) {
        throw const FormatException('Unknown SPL particle');
      }
      selected.add(definition);
    }
    final combinedVersion = selected.first.schemaVersion;
    if (selected.any((item) => item.schemaVersion != combinedVersion)) {
      throw const FormatException('Mixed SPL versions are unsupported');
    }
    final definition = selected.length == 1
        ? selected.single
        : BattleSplParticleDefinition.fromJson({
            'schemaVersion': combinedVersion,
            'emitters': [
              for (final item in selected) ...item.toJson()['emitters'] as List,
            ],
          });
    return _prepareSplComponent(
      definition: definition,
      textureBytes: _bundle.media,
      emitters: emitters,
      seed: seed,
      poolCapacity: poolCapacity,
      maxTicks: maxTicks,
      origin: origin,
      pixelsPerUnit: pixelsPerUnit,
      projection: projection,
      onComplete: onComplete,
      onFailure: onFailure,
      checkActive: _checkActive,
    );
  }
}

final class BattleExperimentalSplPreparation {
  BattleExperimentalSplPreparation._({
    this.component,
    this.failure,
    this._reservation,
  });

  final BattleSplStaticComponent? component;
  final BattleSplAdmissionFailure? failure;
  RuntimeResourceReservation? _reservation;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      component?.dispose();
    } finally {
      _reservation?.release();
      _reservation = null;
    }
  }
}

final class BattleExperimentalSplLoader {
  BattleExperimentalSplLoader({required this.resourceBudget});

  final RuntimeResourceBudget resourceBudget;
  final Completer<void> _cancelledSignal = Completer<void>();
  BattleExperimentalSplPreparation? _prepared;
  bool _cancelled = false;
  bool _started = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancelledSignal.complete();
    _prepared?.dispose();
    _prepared = null;
  }

  Future<BattleExperimentalSplPreparation> create({
    required BattleSplParticleDefinition definition,
    required List<int> sourceEmitterIndices,
    required Map<String, Uint8List> textureBytes,
    required Map<String, String> textureSha256,
    required List<BattleSplStaticEmitter> emitters,
    required int seed,
    required int poolCapacity,
    required int maxTicks,
    required ui.Offset origin,
    required double pixelsPerUnit,
    required BattleSplCameraProjection? projection,
    required void Function() onComplete,
    required void Function(BattleSplAdmissionFailure) onFailure,
    bool Function()? isCurrent,
  }) async {
    if (_started) throw StateError('SPL loader already used');
    _started = true;
    bool current() {
      if (_cancelled) return false;
      try {
        return isCurrent?.call() ?? true;
      } on Object catch (_) {
        return false;
      }
    }

    void checkActive() {
      if (!current()) throw StateError('SPL loading cancelled');
    }

    checkActive();
    final indices = List<int>.unmodifiable(sourceEmitterIndices);
    final bytesById = Map<String, Uint8List>.unmodifiable(textureBytes);
    final hashesById = Map<String, String>.unmodifiable(textureSha256);
    final ids = definition.textureIds;
    if (!{2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}.contains(definition.schemaVersion) ||
        indices.length != definition.emitters.length ||
        indices.toSet().length != indices.length ||
        indices.any((index) => index < 0 || index > 31) ||
        emitters.isEmpty ||
        emitters.length > 32 ||
        bytesById.length != ids.length ||
        !bytesById.keys.toSet().containsAll(ids) ||
        hashesById.length != ids.length ||
        !hashesById.keys.toSet().containsAll(ids)) {
      throw const FormatException('Invalid experimental SPL resources');
    }
    final bySource = {for (var i = 0; i < indices.length; i++) indices[i]: i};
    final schedule = <BattleSplStaticEmitter>[];
    for (final emitter in emitters) {
      final index = bySource[emitter.emitterIndex];
      if (index == null) {
        throw const FormatException('Unknown SPL source emitter');
      }
      schedule.add(
        BattleSplStaticEmitter(
          emitterIndex: index,
          startTick: emitter.startTick,
          position: emitter.position,
          velocity: emitter.velocity,
        ),
      );
    }
    var encodedBytes = 0;
    var totalPixels = 0;
    var largestPixels = 0;
    for (final id in ids) {
      final bytes = bytesById[id]!;
      encodedBytes += bytes.length;
      if (bytes.length > 8 * 1024 * 1024 ||
          bytes.length > resourceBudget.profile.maximumEncodedBytes ||
          encodedBytes > 64 * 1024 * 1024) {
        throw const FormatException(
          'Experimental SPL texture exceeds byte limit',
        );
      }
      final dimensions = decodeRasterImageDimensions(
        bytes,
        mediaType: 'image/png',
      );
      if (dimensions == null ||
          dimensions.width < 1 ||
          dimensions.height < 1 ||
          dimensions.width > 2048 ||
          dimensions.height > 2048) {
        throw const FormatException('Invalid experimental SPL texture');
      }
      final pixels = dimensions.width * dimensions.height;
      totalPixels += pixels;
      if (pixels > 4000000 || totalPixels > 16000000) {
        throw const FormatException(
          'Experimental SPL texture exceeds pixel limit',
        );
      }
      if (pixels > largestPixels) largestPixels = pixels;
    }
    final pending = resourceBudget.acquire(
      residentBytes: encodedBytes * 2 + totalPixels * 8,
      transientBytes: encodedBytes * 2 + largestPixels * 16,
      isCurrent: current,
    );
    unawaited(
      pending.then<void>((reservation) {
        if (!current()) reservation.release();
      }, onError: (Object _, StackTrace _) {}),
    );
    final reservation = await Future.any<RuntimeResourceReservation>([
      pending,
      _cancelledSignal.future.then<RuntimeResourceReservation>(
        (_) => throw StateError('SPL loading cancelled'),
      ),
    ]);
    BattleSplStaticComponent? component;
    var handedOff = false;
    try {
      checkActive();
      reservation.ensureCurrent();
      final snapshots = <String, Uint8List>{};
      for (final id in ids) {
        final snapshot = Uint8List.fromList(bytesById[id]!);
        final resource = BattleMoveAnimationResource.fromJson({
          'id': id,
          'role': 'texture',
          'mediaType': 'image/png',
          'sizeBytes': snapshot.length,
          'sha256': hashesById[id],
        });
        if (!resource.matches(snapshot)) {
          throw const FormatException('Experimental SPL texture hash mismatch');
        }
        snapshots[id] = snapshot;
      }
      final result = await _prepareSplComponent(
        definition: definition,
        textureBytes: snapshots,
        emitters: schedule,
        seed: seed,
        poolCapacity: poolCapacity,
        maxTicks: maxTicks,
        origin: origin,
        pixelsPerUnit: pixelsPerUnit,
        projection: projection,
        allowScreenSpace: true,
        onComplete: () {
          try {
            onComplete();
          } finally {
            _prepared?.dispose();
            _prepared = null;
          }
        },
        onFailure: (failure) {
          try {
            onFailure(failure);
          } finally {
            _prepared?.dispose();
            _prepared = null;
          }
        },
        checkActive: checkActive,
      );
      component = result.component;
      checkActive();
      if (component == null) {
        return BattleExperimentalSplPreparation._(failure: result.failure);
      }
      reservation.commit();
      final prepared = BattleExperimentalSplPreparation._(
        component: component,
        reservation: reservation,
      );
      _prepared = prepared;
      handedOff = true;
      return prepared;
    } finally {
      if (!handedOff) {
        component?.dispose();
        reservation.release();
      }
    }
  }
}

Future<BattleVerifiedSplPreparation> _prepareSplComponent({
  required BattleSplParticleDefinition definition,
  required Map<String, Uint8List> textureBytes,
  required List<BattleSplStaticEmitter> emitters,
  required int seed,
  required int poolCapacity,
  required int maxTicks,
  required ui.Offset origin,
  required double pixelsPerUnit,
  required BattleSplCameraProjection? projection,
  bool allowScreenSpace = false,
  required void Function() onComplete,
  required void Function(BattleSplAdmissionFailure) onFailure,
  required void Function() checkActive,
}) async {
  if ((projection == null && !allowScreenSpace) ||
      (projection != null &&
          (projection.bindings.length != emitters.length ||
              projection.capture() == null))) {
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
      final bytes = textureBytes[id];
      if (bytes == null) throw const FormatException('Missing SPL texture');
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
      checkActive();
      ui.Codec codec;
      try {
        codec = await ui.instantiateImageCodec(textureBytes[id]!);
      } on Exception {
        return const BattleVerifiedSplPreparation._(
          failure: BattleSplAdmissionFailure.textureUnavailable,
        );
      }
      try {
        checkActive();
        ui.FrameInfo frame;
        try {
          frame = await codec.getNextFrame();
        } on Exception {
          return const BattleVerifiedSplPreparation._(
            failure: BattleSplAdmissionFailure.textureUnavailable,
          );
        }
        textures[textureIndices[id]!] = frame.image;
        checkActive();
      } finally {
        codec.dispose();
      }
    }
    checkActive();
    final anchors = projection?.capture();
    if (projection != null &&
        (anchors == null ||
            anchors.any((anchor) => projection.project(anchor) == null))) {
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
