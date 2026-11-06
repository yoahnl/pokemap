import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'battle_gen5_emitter_motion.dart';
import 'battle_gen5_source_emitter.dart';
import 'battle_offline_move_recipe_loader.dart';
import 'battle_overlay_component.dart';
import 'battle_perspective_camera.dart';
import 'battle_spl_camera_projection.dart';
import 'battle_spl_static_admission.dart';
import 'battle_spl_static_component.dart';
import 'battle_verified_spl_loader.dart';

final class BattleGen5SourceParticleSet {
  BattleGen5SourceParticleSet._(this.program, this.variant, this._overlay);

  final Map<String, dynamic> program;
  final String variant;
  final BattleOverlayComponent _overlay;
  final _loaders = <BattleExperimentalSplLoader>[];
  final _prepared =
      <
        ({Map<String, dynamic> args, BattleExperimentalSplPreparation result,
          BattleSplCameraProjection? screenAnchor})
      >[];
  final _active = <BattleSplStaticComponent>{};
  final _indices = <int, Set<int>>{};
  final backgrounds = <int, ui.Image>{};
  final backgroundAnimations =
      <int, ({int background, List<ui.Image> frames, List<int> durations})>{};
  final _backgroundImages = <String, ui.Image>{};
  RuntimeResourceReservation? _backgroundReservation;
  BattleSplAdmissionFailure? _failure;
  var _next = 0;
  var _disposed = false;

  static Future<BattleGen5SourceParticleSet> prepare({
    required InspectedBattleRecipeBundle bundle,
    required BattleOverlayComponent overlay,
    required RuntimeResourceBudget budget,
    required BattleSideId attackerSide,
    BattleOfflineVerifiedMedia? verifiedMedia,
    bool Function()? isCurrent,
  }) async {
    final recipe = bundle.recipe.toJson();
    final source = recipe['program'] as Map<String, dynamic>;
    if (source['kind'] != 'gen5SourceProgram') {
      throw const FormatException('Expected a Gen 5 source program');
    }
    final program = (source['sourceProgram'] as Map).cast<String, dynamic>();
    final result = BattleGen5SourceParticleSet._(
      program,
      recipe['variant'] as String,
      overlay,
    );
    final definitions = bundle.recipe.readVerifiedSplParticleDefinitions(
      bundle.media,
      availableCapabilities: BattleMoveAnimationRecipe.recognizedCapabilities,
    );
    final bindings = <int, ({String resource, List<int> indices})>{};
    for (final value in source['particleBindings'] as List) {
      final binding = value as Map;
      final id = binding['particle'] as int;
      final indices = (binding['sourceEmitterIndices'] as List).cast<int>();
      bindings[id] = (
        resource: binding['resourceId'] as String,
        indices: indices,
      );
      result._indices[id] = indices.toSet();
    }
    final commands = <({String op, Map<String, dynamic> args})>[];
    final instructions = program['instructions'] as List;
    for (
      var index = program['entryIndex'] as int;
      index < instructions.length;
      index++
    ) {
      final instruction = instructions[index] as Map;
      final op = instruction['op'] as String;
      if (op == 'end') break;
      if (op.startsWith('start') && op.endsWith('Emitter')) {
        if (!{'startEmitter', 'startMovingEmitter', 'startOrthoEmitter',
          'startMovingOrthoEmitter', 'startFieldEmitter',
          'startMovingFieldEmitter'}.contains(op)) {
          throw const FormatException('Unsupported source emitter motion');
        }
        commands.add((
          op: op,
          args: (instruction['args'] as Map).cast<String, dynamic>(),
        ));
      }
    }
    final isSurf = program['variant'] == 'Surf';
    final usesMotion = isSurf || commands.any(
      (command) => command.op == 'startMovingEmitter' ||
          command.op == 'startMovingOrthoEmitter',
    );
    final centeredBeamOrigins = <(Object?, int)>{};
    if (overlay.size.y > overlay.size.x) {
      for (final command in commands) {
        final args = command.args;
        if (command.op == 'startOrthoEmitter' ||
            command.op == 'startMovingOrthoEmitter' ||
            command.op == 'startFieldEmitter' ||
            command.op == 'startMovingFieldEmitter' ||
            args['from'] == args['to'] || args['from'] == 8 ||
            args['to'] == 8 || args['offsetY'] is! int) {
          continue;
        }
        final binding = bindings[args['particle']];
        final definition = binding == null ? null : definitions[binding.resource];
        final index = binding?.indices.indexOf(args['emitter'] as int) ?? -1;
        if (definition == null || index < 0) continue;
        final emitter = (definition.toJson()['emitters'] as List)[index] as Map;
        final appearance = emitter['appearance'] as Map;
        final emission = emitter['emission'] as Map;
        if (appearance['draw'] == 'directionalBillboard' &&
            appearance['directionStretch'] is int &&
            emission['axisVelocity'] is int && emission['axisVelocity'] != 0) {
          centeredBeamOrigins.add((args['from'], args['offsetY'] as int));
          centeredBeamOrigins.add((args['to'], args['offsetY'] as int));
        }
      }
    }
    try {
      final backgroundBindings = source['backgroundBindings'] as List? ?? const [];
      final animationBindings = source['backgroundAnimationBindings'] as List? ?? const [];
      if (animationBindings.isNotEmpty) {
        final ids = <String>{
          for (final value in backgroundBindings) (value as Map)['resourceId'] as String,
          for (final value in animationBindings)
            for (final id in (value as Map)['frames'] as List) id as String,
        };
        var encodedBytes = 0;
        var largestEncoded = 0;
        for (final id in ids) {
          final bytes = bundle.media[id]!;
          final dimensions = decodeRasterImageDimensions(bytes, mediaType: 'image/png');
          if (dimensions == null || dimensions.width != 512 || dimensions.height != 512 ||
              bytes.length > budget.profile.maximumEncodedBytes) {
            throw const FormatException('Invalid source background image');
          }
          encodedBytes += bytes.length;
          largestEncoded = math.max(largestEncoded, bytes.length);
        }
        bool current() => !result._disposed && (isCurrent?.call() ?? true);
        if (verifiedMedia != null) {
          if (!identical(verifiedMedia.bundle, bundle)) {
            throw StateError('Source background media does not match bundle');
          }
          result._backgroundReservation = await verifiedMedia.acquireTextureDecode(
            isCurrent: current,
          );
        } else {
          result._backgroundReservation = await budget.acquire(
            residentBytes: encodedBytes * 2 + ids.length * 512 * 512 * 8,
            transientBytes: largestEncoded * 2 + 512 * 512 * 16,
            isCurrent: current,
          );
        }
      }
      Future<ui.Image> loadBackground(String id) async {
        final existing = result._backgroundImages[id];
        if (existing != null) return existing;
        if (isCurrent != null && !isCurrent()) {
          throw StateError('Source background preparation cancelled');
        }
        final codec = await ui.instantiateImageCodec(bundle.media[id]!);
        try {
          final image = (await codec.getNextFrame()).image;
          if (isCurrent != null && !isCurrent()) {
            image.dispose();
            throw StateError('Source background preparation cancelled');
          }
          result._backgroundImages[id] = image;
          return image;
        } finally {
          codec.dispose();
        }
      }
      for (final value in backgroundBindings) {
        if (isCurrent != null && !isCurrent()) {
          throw StateError('Source background preparation cancelled');
        }
        final binding = value as Map;
        result.backgrounds[binding['background'] as int] =
            await loadBackground(binding['resourceId'] as String);
      }
      for (final value in animationBindings) {
        final binding = value as Map;
        final frames = <ui.Image>[];
        for (final id in binding['frames'] as List) {
          if (isCurrent != null && !isCurrent()) {
            throw StateError('Source background animation preparation cancelled');
          }
          frames.add(await loadBackground(id as String));
        }
        result.backgroundAnimations[binding['animation'] as int] = (
          background: binding['background'] as int,
          frames: List.unmodifiable(frames),
          durations: List<int>.unmodifiable(binding['durations'] as List),
        );
      }
      result._backgroundReservation?.commit();
      for (final command in commands) {
        final args = command.args;
        final movingOrthographic = command.op == 'startMovingOrthoEmitter';
        final orthographic = command.op == 'startOrthoEmitter' || movingOrthographic;
        final fieldPositioned = command.op == 'startFieldEmitter' ||
            command.op == 'startMovingFieldEmitter';
        if (isCurrent != null && !isCurrent()) {
          throw StateError('Source particle preparation cancelled');
        }
        final binding = bindings[args['particle']]!;
        final selected = definitions[binding.resource]!;
        final definitionJson =
            jsonDecode(jsonEncode(selected.toJson())) as Map<String, dynamic>;
        final sourceIndex = args['emitter'] as int;
        final emitter =
            (definitionJson['emitters'] as List)[binding.indices.indexOf(
                  sourceIndex,
                )]
                as Map;
        final fromUser =
            args['from'] == 0 || args['from'] == 'EFFVM_EMIT_ATTACKER';
        final towardOpponent =
            !fieldPositioned && (!orthographic || movingOrthographic) && args['from'] != 8 &&
            args['to'] != 8 &&
            args['from'] != args['to'] &&
            !(args['from'] == 0 && args['to'] == 'EFFVM_EMIT_ATTACKER');
        final centeredBeam = centeredBeamOrigins.contains((args['from'], args['offsetY']));
        final appearance = emitter['appearance'] as Map;
        final emission = emitter['emission'] as Map;
        final portraitBeam = centeredBeam &&
            appearance['draw'] == 'directionalBillboard' &&
            appearance['directionStretch'] is int &&
            emission['axisVelocity'] is int && emission['axisVelocity'] != 0;
        final emitterOffsetY = centeredBeam ? 0 : args['offsetY'] as int;
        applyGen5SourceEmitterParameters(
          emitter,
          movingOrthographic ? {...args, 'radiusScale': 3072, 'scaleScale': 3072} : args,
          orthographic: orthographic && !movingOrthographic,
          aimAtOpponent: towardOpponent && !orthographic,
        );
        final definition = (definitionJson['schemaVersion'] as int) > 5
            ? BattleSplParticleDefinition.fromExperimentalJson(definitionJson)
            : BattleSplParticleDefinition.fromJson(definitionJson);
        final projection = fieldPositioned
            ? overlay.experimentalGen5FieldProjection()
            : overlay.experimentalGen5Projection(
                attacker: fromUser == (attackerSide == BattleSideId.player),
                towardOpponent: towardOpponent,
                matchBattleSpacing: usesMotion || centeredBeam,
                anchorAtFoot: usesMotion || centeredBeam,
                centerTargetedBeam: centeredBeam,
              );
        final basePixelsPerUnit = orthographic
            ? math.min(projection.camera.viewport.width / 8,
                projection.camera.viewport.height / 6)
            : usesMotion || centeredBeam
            ? projection.worldTransform!.worldUnitsPerUnit /
                  projection.capture()!.single.unit
            : 25.0;
        final beamScale = portraitBeam
            ? (1 + (overlay.size.y / overlay.size.x - 1) * 1.1).clamp(1.0, 2.25)
            : 1.0;
        final pixelsPerUnit = basePixelsPerUnit * beamScale;
        final loader = BattleExperimentalSplLoader(resourceBudget: budget);
        result._loaders.add(loader);
        late final BattleExperimentalSplPreparation prepared;
        prepared = await loader.create(
          definition: definition,
          sourceEmitterIndices: binding.indices,
          textureBytes: <String, Uint8List>{
            for (final id in definition.textureIds) id: bundle.media[id]!,
          },
          textureSha256: {
            for (final resource in bundle.recipe.resources)
              if (definition.textureIds.contains(resource.id))
                resource.id: resource.sha256Hex,
          },
          emitters: [
            BattleSplStaticEmitter(
              emitterIndex: sourceIndex,
              startTick: 0,
              position: fieldPositioned
                  ? gen5SourceFieldEmitterOffset(args)
                  : (x: 0, y: orthographic ? 0 : emitterOffsetY, z: 0),
            ),
          ],
          seed: 0,
          poolCapacity: 256,
          maxTicks: 300,
          origin: ui.Offset.zero,
          pixelsPerUnit: pixelsPerUnit,
          projection: orthographic ? null : projection,
          onComplete: () => result._active.remove(prepared.component),
          onFailure: (failure) {
            result._failure = failure;
            result._active.remove(prepared.component);
          },
          isCurrent: isCurrent,
        );
        final component = prepared.component;
        if (component == null) {
          throw StateError('Source particle unavailable: ${prepared.failure}');
        }
        component.clipOutOfViewParticles = true;
        component.priority = isSurf && (sourceIndex == 1 || sourceIndex == 2)
            ? 13
            : 12;
        component.clipBounds = () => ui.Rect.fromLTWH(
          orthographic ? -component.position.x : 0,
          orthographic ? -component.position.y : 0,
          overlay.size.x,
          overlay.size.y,
        );
        if (command.op == 'startMovingEmitter' || movingOrthographic ||
            command.op == 'startMovingFieldEmitter') {
          final endpoints = fieldPositioned
              ? gen5SourceFieldMotionEndpoints(args)
              : (from: (x: 0, y: 0, z: 0), to: (x: 0, y: 0, z: 17 * 4096));
          final motion = BattleGen5EmitterMotion(
            from: endpoints.from,
            to: endpoints.to,
            motionType: args['motion'] as int,
            motionFramesFx32: args['motionFramesFx32'] as int,
            offsetYFx32: emitterOffsetY,
            heightFx32: args['height'] as int,
            turnsFx32: args['turns'] as int,
          );
          if (movingOrthographic) {
            component.advanceEmitterPosition = () {
              final anchors = projection.capture();
              final transform = projection.worldTransform;
              if (anchors == null || anchors.length != 1 || transform == null) {
                throw StateError('Source emitter anchor unavailable');
              }
              final anchor = anchors.single;
              final base = BattleCameraPoint(anchor.x, anchor.y, anchor.z);
              final origin = projection.camera.tryProject(base);
              final point = projection.camera.tryProject(base + transform.apply(motion.advance()));
              if (origin == null || point == null) {
                throw StateError('Source emitter projection unavailable');
              }
              component.position = Vector2(origin.position.dx, origin.position.dy);
              return (
                x: ((point.position.dx - origin.position.dx) * 4096 / pixelsPerUnit).round(),
                y: ((origin.position.dy - point.position.dy) * 4096 / pixelsPerUnit).round(),
                z: 0,
              );
            };
          } else {
            component.advanceEmitterPosition = motion.advance;
          }
        }
        result._prepared.add((args: args, result: prepared,
          screenAnchor: orthographic ? projection : null));
      }
      return result;
    } on Object {
      result.dispose();
      rethrow;
    }
  }

  bool hasEmitter(int particle, int emitter) =>
      !_disposed && (_indices[particle]?.contains(emitter) ?? false);

  void start(Map<String, dynamic> args) {
    if (_disposed ||
        _next >= _prepared.length ||
        jsonEncode(args) != jsonEncode(_prepared[_next].args)) {
      throw StateError('Unexpected source particle invocation');
    }
    final entry = _prepared[_next++];
    final component = entry.result.component!;
    final screenAnchor = entry.screenAnchor;
    if (screenAnchor != null) {
      final anchors = screenAnchor.capture();
      final transform = screenAnchor.worldTransform;
      if (anchors == null || anchors.length != 1 || transform == null) {
        throw StateError('Source emitter anchor unavailable');
      }
      final anchor = anchors.single;
      final point = BattleCameraPoint(anchor.x, anchor.y, anchor.z) +
          transform.apply((x: (args['offsetX'] as int?) ?? 0,
            y: args.containsKey('motion') ? 0 : args['offsetY'] as int,
            z: (args['offsetZ'] as int?) ?? 0));
      final projected = screenAnchor.camera.tryProject(point);
      if (projected == null) {
        throw StateError('Source emitter projection unavailable');
      }
      component.position = Vector2(projected.position.dx, projected.position.dy);
    }
    _active.add(component);
    _overlay.add(component);
  }

  void delete(int particle) {
    for (final entry in _prepared) {
      if (entry.args['particle'] == particle &&
          _active.remove(entry.result.component)) {
        entry.result.dispose();
      }
    }
  }

  bool isBusy() {
    if (_failure != null) throw StateError('Source particle failed: $_failure');
    return _active.isNotEmpty;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final entry in _prepared) {
      entry.result.dispose();
    }
    for (final loader in _loaders) {
      loader.cancel();
    }
    _active.clear();
    backgrounds.clear();
    for (final image in _backgroundImages.values) {
      image.dispose();
    }
    _backgroundImages.clear();
    backgroundAnimations.clear();
    _backgroundReservation?.release();
    _backgroundReservation = null;
  }
}
